-- ============================================
-- 04: Rate Limits Table
-- Run FOURTH in Supabase SQL Editor
-- ============================================

CREATE TABLE IF NOT EXISTS public.rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier VARCHAR(255) NOT NULL,
    endpoint VARCHAR(100) NOT NULL,
    attempts INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(identifier, endpoint)
);

-- No RLS — accessed via service role in Edge Functions only

-- Cleanup expired rate limits (run via pg_cron or manually)
CREATE OR REPLACE FUNCTION cleanup_expired_rate_limits()
RETURNS void AS $$
BEGIN
    DELETE FROM public.rate_limits
    WHERE window_start < NOW() - INTERVAL '15 minutes';
END;
$$ LANGUAGE plpgsql;
