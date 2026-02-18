-- ============================================
-- 05: Security Events Logging Table
-- Run FIFTH in Supabase SQL Editor
-- ============================================

CREATE TABLE IF NOT EXISTS public.security_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL,
    identifier VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- No RLS — only accessible via service role (admin/Edge Functions)

-- Index for querying by event type and time
CREATE INDEX IF NOT EXISTS idx_security_events_type
    ON public.security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_security_events_created
    ON public.security_events(created_at DESC);
