# 05 — Database Schema: Routes & Related Tables

## Objective
Define the database schema for routes, crime data, and related geospatial tables.

---

## `routes` Table

```sql
CREATE TABLE public.routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    origin GEOMETRY(POINT, 4326) NOT NULL,
    destination GEOMETRY(POINT, 4326) NOT NULL,
    waypoints JSONB NOT NULL,            -- Array of {lat, lng} objects
    polyline_encoded TEXT NOT NULL,       -- Google encoded polyline
    distance_km FLOAT NOT NULL,
    duration_min INTEGER NOT NULL,
    safety_score FLOAT,                   -- NULL until calculated
    status TEXT DEFAULT 'calculating'
        CHECK (status IN ('calculating', 'scored', 'selected', 'error')),
    route_index INTEGER DEFAULT 0,        -- 0=safest, 1=balanced, 2=shortest
    safety_breakdown JSONB,               -- Detailed score components
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_routes_user_id ON public.routes(user_id);
CREATE INDEX idx_routes_status ON public.routes(status);
CREATE INDEX idx_routes_origin ON public.routes USING GIST (origin);
CREATE INDEX idx_routes_destination ON public.routes USING GIST (destination);

-- RLS
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own routes"
    ON public.routes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert/update routes"
    ON public.routes FOR ALL
    USING (true)
    WITH CHECK (true);  -- Edge functions use service role
```

---

## `crime_data` Table

```sql
CREATE TABLE public.crime_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location GEOMETRY(POINT, 4326) NOT NULL,
    crime_type VARCHAR(100) NOT NULL,
    severity TEXT NOT NULL 
        CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT,
    source VARCHAR(100),              -- 'police_report', 'news', 'ai_analysis'
    occurred_at TIMESTAMPTZ,
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    ai_confidence FLOAT,              -- AI analysis confidence (0-1)
    metadata JSONB DEFAULT '{}',      -- Additional data
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial index for proximity queries
CREATE INDEX idx_crime_data_location ON public.crime_data USING GIST (location);
CREATE INDEX idx_crime_data_type ON public.crime_data(crime_type);
CREATE INDEX idx_crime_data_severity ON public.crime_data(severity);
CREATE INDEX idx_crime_data_occurred_at ON public.crime_data(occurred_at);
```

---

## `safety_breakdown` JSONB Structure

Each scored route stores a detailed breakdown:

```json
{
  "overall_score": 85.5,
  "components": {
    "crime_density_score": 78.0,
    "user_flag_score": 90.0,
    "commercial_factor": 85.0,
    "lighting_factor": 80.0,
    "population_density": 88.0
  },
  "weights": {
    "crime_density": 0.35,
    "user_flags": 0.25,
    "commercial": 0.20,
    "lighting": 0.10,
    "population": 0.10
  },
  "crime_count_nearby": 12,
  "unsafe_zones_on_route": 2,
  "commercial_points": 14,
  "ai_analysis_id": "uuid-of-ai-analysis"
}
```

---

## PostGIS Utility Functions

```sql
-- Get crimes near a route (within buffer distance)
CREATE OR REPLACE FUNCTION get_crimes_near_route(
    route_waypoints JSONB,
    buffer_meters FLOAT DEFAULT 500
)
RETURNS TABLE (
    crime_id UUID,
    crime_type VARCHAR,
    severity TEXT,
    distance_meters FLOAT
) AS $$
DECLARE
    route_line GEOMETRY;
BEGIN
    -- Build a line from waypoints
    SELECT ST_MakeLine(
        ARRAY(
            SELECT ST_SetSRID(
                ST_MakePoint(
                    (point->>'lng')::FLOAT,
                    (point->>'lat')::FLOAT
                ),
                4326
            )
            FROM jsonb_array_elements(route_waypoints) AS point
        )
    ) INTO route_line;

    RETURN QUERY
    SELECT
        cd.id,
        cd.crime_type,
        cd.severity,
        ST_Distance(cd.location::geography, route_line::geography)::FLOAT
    FROM public.crime_data cd
    WHERE ST_DWithin(
        cd.location::geography,
        route_line::geography,
        buffer_meters
    )
    AND cd.occurred_at > NOW() - INTERVAL '1 year'
    ORDER BY ST_Distance(cd.location::geography, route_line::geography);
END;
$$ LANGUAGE plpgsql;

-- Count commercial points near a route
CREATE OR REPLACE FUNCTION count_commercial_near_route(
    route_waypoints JSONB,
    buffer_meters FLOAT DEFAULT 200
)
RETURNS INTEGER AS $$
-- Uses Google Places API results cached in a commercial_points table
-- Implementation in Phase 4
$$ LANGUAGE plpgsql;
```

---

## Migration File

Save as: `supabase/migrations/002_routes_schema.sql`

> [!NOTE]
> Migration numbers should be sequential. Phase 1 creates `001_user_profiles.sql`. Phase 3 creates `002_routes_schema.sql`.

---

## Verification
- [ ] All tables created with correct constraints
- [ ] PostGIS geometry columns properly typed (SRID 4326)
- [ ] Spatial indexes created for performance
- [ ] RLS policies in place
- [ ] `get_crimes_near_route` function works with test data
- [ ] JSONB safety_breakdown structure validated
