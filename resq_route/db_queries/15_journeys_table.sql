-- ============================================================
-- 15. Journeys + Journey Points tables
-- Phase 5: Live Monitoring Engine
-- ============================================================

-- ── Journeys table ──
CREATE TABLE IF NOT EXISTS public.journeys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    route_id UUID REFERENCES public.routes(id),
    origin_lat DOUBLE PRECISION NOT NULL,
    origin_lng DOUBLE PRECISION NOT NULL,
    dest_lat DOUBLE PRECISION NOT NULL,
    dest_lng DOUBLE PRECISION NOT NULL,
    status TEXT DEFAULT 'active'
        CHECK (status IN ('active', 'paused', 'completed', 'sos', 'cancelled')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    share_live_location BOOLEAN DEFAULT FALSE,
    tracking_link_id VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Journey Points table ──
CREATE TABLE IF NOT EXISTS public.journey_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journey_id UUID NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    accuracy FLOAT,
    speed FLOAT,             -- m/s
    heading FLOAT,           -- degrees
    battery_level FLOAT,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes ──
CREATE INDEX IF NOT EXISTS idx_journeys_user_id ON public.journeys(user_id);
CREATE INDEX IF NOT EXISTS idx_journeys_status ON public.journeys(status);
CREATE INDEX IF NOT EXISTS idx_journey_points_journey_id ON public.journey_points(journey_id);
CREATE INDEX IF NOT EXISTS idx_journey_points_recorded ON public.journey_points(recorded_at);

-- ── RLS ──
ALTER TABLE public.journeys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own journeys"
    ON public.journeys FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users manage own journey points"
    ON public.journey_points FOR ALL
    USING (journey_id IN (SELECT id FROM public.journeys WHERE user_id = auth.uid()));
