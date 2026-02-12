# 04 — Unsafe Zone Display

## Objective
Display verified and user-reported unsafe zones on the map with severity indicators, filtering, and info popups.

---

## Database Schema

```sql
CREATE TABLE public.unsafe_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location GEOMETRY(POINT, 4326) NOT NULL,
    radius_meters INTEGER DEFAULT 200,
    reason TEXT NOT NULL,
    severity TEXT DEFAULT 'medium' 
        CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    confidence_score FLOAT DEFAULT 0.5,
    reported_by UUID REFERENCES auth.users(id),
    verified BOOLEAN DEFAULT FALSE,
    flag_count INTEGER DEFAULT 1,
    photo_url VARCHAR(255),
    decay_coefficient FLOAT DEFAULT 0.95,
    last_reported_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- PostGIS spatial index
CREATE INDEX idx_unsafe_zones_location ON public.unsafe_zones USING GIST (location);
CREATE INDEX idx_unsafe_zones_verified ON public.unsafe_zones(verified);

-- RLS: Everyone can read verified zones, users can create flags
ALTER TABLE public.unsafe_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read verified zones"
    ON public.unsafe_zones FOR SELECT
    USING (verified = TRUE OR reported_by = auth.uid());

CREATE POLICY "Users can create flags"
    ON public.unsafe_zones FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);
```

---

## Fetching Nearby Unsafe Zones

### Edge Function: `get-unsafe-zones`
```typescript
serve(async (req) => {
  const { lat, lng, radiusKm } = await req.json();
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Query zones within radius using PostGIS
  const { data, error } = await supabase.rpc('get_nearby_unsafe_zones', {
    user_lat: lat,
    user_lng: lng,
    radius_km: radiusKm || 5,
  });

  return new Response(JSON.stringify({ zones: data }));
});
```

### PostGIS Function
```sql
CREATE OR REPLACE FUNCTION get_nearby_unsafe_zones(
    user_lat FLOAT,
    user_lng FLOAT,
    radius_km FLOAT DEFAULT 5
)
RETURNS TABLE (
    id UUID,
    latitude FLOAT,
    longitude FLOAT,
    radius_meters INTEGER,
    reason TEXT,
    severity TEXT,
    confidence_score FLOAT,
    verified BOOLEAN,
    flag_count INTEGER,
    distance_km FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        uz.id,
        ST_Y(uz.location)::FLOAT as latitude,
        ST_X(uz.location)::FLOAT as longitude,
        uz.radius_meters,
        uz.reason,
        uz.severity,
        uz.confidence_score,
        uz.verified,
        uz.flag_count,
        (ST_Distance(
            uz.location::geography,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) / 1000)::FLOAT as distance_km
    FROM public.unsafe_zones uz
    WHERE ST_DWithin(
        uz.location::geography,
        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
        radius_km * 1000  -- Convert km to meters
    )
    AND (uz.verified = TRUE OR uz.flag_count >= 3)
    AND (uz.expires_at IS NULL OR uz.expires_at > NOW())
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql;
```

---

## Map Visualization

### Severity-Based Markers

| Severity | Marker Color | Circle Radius | Opacity |
|----------|-------------|---------------|---------|
| `critical` | 🔴 Red | Full radius | 0.4 |
| `high` | 🟠 Orange | 75% radius | 0.3 |
| `medium` | 🟡 Yellow | 50% radius | 0.2 |
| `low` | ⚪ Grey | 25% radius | 0.15 |

```dart
Set<Circle> _buildUnsafeZoneCircles(List<UnsafeZone> zones) {
  return zones.map((zone) {
    return Circle(
      circleId: CircleId('zone_${zone.id}'),
      center: LatLng(zone.latitude, zone.longitude),
      radius: zone.radiusMeters.toDouble(),
      fillColor: _getSeverityColor(zone.severity).withOpacity(_getOpacity(zone.severity)),
      strokeColor: _getSeverityColor(zone.severity),
      strokeWidth: 2,
    );
  }).toSet();
}

Color _getSeverityColor(String severity) {
  switch (severity) {
    case 'critical': return Colors.red;
    case 'high': return Colors.orange;
    case 'medium': return Colors.amber;
    case 'low': return Colors.grey;
    default: return Colors.grey;
  }
}
```

---

## Flag Submission (Crowdsourcing)

### UI: Flag Unsafe Area Button
During a journey, users can report unsafe zones:

```
┌─────────────────────────────┐
│  ⚠️ Flag Unsafe Area         │
│                             │
│  What did you notice?       │
│  ○ Poor lighting            │
│  ○ Suspicious activity      │
│  ○ Isolated area            │
│  ○ Known crime area         │
│  ○ Other: [__________]     │
│                             │
│  📸 [Add Photo (optional)]  │
│                             │
│  [ SUBMIT FLAG ]            │
└─────────────────────────────┘
```

### Auto-Verification

If 3+ unique users flag the same area (within 200m) within 7 days, it auto-verifies with `confidence_score: 0.5`:

```sql
CREATE OR REPLACE FUNCTION check_auto_verify_zone()
RETURNS TRIGGER AS $$
DECLARE
    nearby_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO nearby_count
    FROM public.unsafe_zones
    WHERE ST_DWithin(
        location::geography,
        NEW.location::geography,
        200  -- 200 meters
    )
    AND created_at > NOW() - INTERVAL '7 days'
    AND id != NEW.id;

    IF nearby_count >= 2 THEN  -- 2 existing + this new one = 3
        NEW.verified := TRUE;
        NEW.confidence_score := 0.5;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_verify_zone
    BEFORE INSERT ON public.unsafe_zones
    FOR EACH ROW
    EXECUTE FUNCTION check_auto_verify_zone();
```

---

## Verification
- [ ] Unsafe zones fetched within radius using PostGIS
- [ ] Map displays colored circles per severity
- [ ] Info popup shows zone reason on tap
- [ ] Users can flag new unsafe areas
- [ ] Auto-verification triggers at 3 flags
- [ ] Zones expire when `expires_at` passes
