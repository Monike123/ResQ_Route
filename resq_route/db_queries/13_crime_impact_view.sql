-- ============================================================
-- Migration 13: Crime Impact Materialized View
-- Phase 4: Safety Scoring & AI Integration
-- ============================================================
-- Precomputes crime severity × recency decay for fast scoring.
-- Refresh daily (pg_cron if available, else manual/Edge Function cron).

CREATE MATERIALIZED VIEW IF NOT EXISTS public.crime_impact AS
SELECT
    id,
    location,
    crime_type,
    severity,
    occurred_at,
    -- Severity multiplier
    CASE severity
        WHEN 'critical' THEN 10
        WHEN 'high' THEN 7
        WHEN 'medium' THEN 4
        WHEN 'low' THEN 2
        ELSE 1
    END
    *
    -- Recency decay
    CASE
        WHEN occurred_at > NOW() - INTERVAL '30 days' THEN 1.0
        WHEN occurred_at > NOW() - INTERVAL '90 days' THEN 0.7
        WHEN occurred_at > NOW() - INTERVAL '180 days' THEN 0.4
        WHEN occurred_at > NOW() - INTERVAL '365 days' THEN 0.2
        ELSE 0.05
    END AS impact_score
FROM public.crime_data;

-- Index for spatial joins
CREATE INDEX IF NOT EXISTS idx_crime_impact_location
    ON public.crime_impact USING GIST ((location::geography));

-- To refresh (run daily via pg_cron or scheduled Edge Function):
-- REFRESH MATERIALIZED VIEW CONCURRENTLY public.crime_impact;

-- If pg_cron is available:
-- SELECT cron.schedule(
--     'refresh-crime-impact',
--     '0 3 * * *',
--     'REFRESH MATERIALIZED VIEW CONCURRENTLY public.crime_impact'
-- );
