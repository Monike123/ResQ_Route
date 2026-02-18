-- ============================================================
-- 17. SOS Events table
-- Phase 6: Emergency Response System
-- ============================================================

CREATE TABLE IF NOT EXISTS public.sos_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journey_id UUID REFERENCES public.journeys(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    trigger_type TEXT NOT NULL
        CHECK (trigger_type IN ('button', 'voice', 'deadman', 'shake')),
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    accuracy FLOAT,
    status TEXT DEFAULT 'active'
        CHECK (status IN ('active', 'resolved', 'false_alarm')),
    resolved_at TIMESTAMPTZ,
    resolved_by TEXT,           -- 'user', 'admin', 'system'
    forensic_snapshot_url TEXT,
    forensic_integrity_hash TEXT,
    tracking_link_id VARCHAR(50) UNIQUE,
    tracking_link_expires_at TIMESTAMPTZ,
    sms_delivery_status JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes ──
CREATE INDEX IF NOT EXISTS idx_sos_events_user_id ON public.sos_events(user_id);
CREATE INDEX IF NOT EXISTS idx_sos_events_status ON public.sos_events(status);
CREATE INDEX IF NOT EXISTS idx_sos_events_journey_id ON public.sos_events(journey_id);
CREATE INDEX IF NOT EXISTS idx_sos_events_tracking_link ON public.sos_events(tracking_link_id);

-- ── RLS ──
ALTER TABLE public.sos_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own SOS events"
    ON public.sos_events FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users create own SOS events"
    ON public.sos_events FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own SOS events"
    ON public.sos_events FOR UPDATE
    USING (auth.uid() = user_id);
