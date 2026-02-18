-- ============================================================
-- 18. Reports table
-- Phase 7: SRR Reporting Engine
-- ============================================================

CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journey_id UUID REFERENCES public.journeys(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    report_type TEXT DEFAULT 'srr'
        CHECK (report_type IN ('srr', 'sos_report')),
    pdf_url TEXT,
    map_snapshot_url TEXT,
    share_link_id VARCHAR(50) UNIQUE,
    share_link_expires_at TIMESTAMPTZ,
    integrity_hash VARCHAR(255),
    hash_source_data JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes ──
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON public.reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_journey_id ON public.reports(journey_id);
CREATE INDEX IF NOT EXISTS idx_reports_share_link ON public.reports(share_link_id);

-- ── RLS ──
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own reports"
    ON public.reports FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users create own reports"
    ON public.reports FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own reports"
    ON public.reports FOR UPDATE
    USING (auth.uid() = user_id);
