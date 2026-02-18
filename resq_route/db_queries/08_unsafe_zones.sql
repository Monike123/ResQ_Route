-- 08: Unsafe Zones Table
-- User-reported and verified unsafe areas with severity, decay, and auto-verify.

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

-- Spatial + filter indexes
CREATE INDEX idx_unsafe_zones_location ON public.unsafe_zones USING GIST (location);
CREATE INDEX idx_unsafe_zones_verified ON public.unsafe_zones(verified);
CREATE INDEX idx_unsafe_zones_severity ON public.unsafe_zones(severity);

-- RLS: Everyone reads verified zones, users can create flags
ALTER TABLE public.unsafe_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read verified zones"
    ON public.unsafe_zones FOR SELECT
    USING (verified = TRUE OR reported_by = auth.uid());

CREATE POLICY "Authenticated users can flag zones"
    ON public.unsafe_zones FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own flags"
    ON public.unsafe_zones FOR UPDATE
    USING (reported_by = auth.uid());

-- Auto-verify: if 3+ unique users flag within 200m in 7 days → verified
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

    IF nearby_count >= 2 THEN  -- 2 existing + this = 3
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
