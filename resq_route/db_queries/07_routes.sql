-- 07: Routes Table
-- Stores computed routes with PostGIS geometry, safety scores, and polylines.

CREATE TABLE public.routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    origin GEOMETRY(POINT, 4326) NOT NULL,
    destination GEOMETRY(POINT, 4326) NOT NULL,
    waypoints JSONB NOT NULL,                 -- Array of {lat, lng}
    polyline_encoded TEXT NOT NULL,            -- Google encoded polyline
    distance_km FLOAT NOT NULL,
    duration_min INTEGER NOT NULL,
    safety_score FLOAT,                        -- NULL until calculated (Phase 4)
    status TEXT DEFAULT 'calculating'
        CHECK (status IN ('calculating', 'scored', 'selected', 'error')),
    route_index INTEGER DEFAULT 0,             -- 0=safest, 1=balanced, 2=shortest
    safety_breakdown JSONB,                    -- Detailed score components
    start_address TEXT,
    end_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_routes_user_id ON public.routes(user_id);
CREATE INDEX idx_routes_status ON public.routes(status);
CREATE INDEX idx_routes_origin ON public.routes USING GIST (origin);
CREATE INDEX idx_routes_destination ON public.routes USING GIST (destination);
CREATE INDEX idx_routes_created ON public.routes(created_at DESC);

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_routes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER routes_updated_at
    BEFORE UPDATE ON public.routes
    FOR EACH ROW
    EXECUTE FUNCTION update_routes_updated_at();

-- RLS
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own routes"
    ON public.routes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own routes"
    ON public.routes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own routes"
    ON public.routes FOR UPDATE
    USING (auth.uid() = user_id);
