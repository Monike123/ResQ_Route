-- ============================================================
-- 16. Journey Points Retention Policy
-- Phase 5: Live Monitoring Engine
-- ============================================================

-- Purge journey points older than 30 days.
-- Exception: points from SOS journeys are retained for 7 years.
--
-- To schedule daily via pg_cron (must be enabled in Supabase dashboard):
--   SELECT cron.schedule(
--     'purge-old-journey-points',
--     '0 4 * * *',
--     $$
--       DELETE FROM public.journey_points
--       WHERE recorded_at < NOW() - INTERVAL '30 days'
--         AND journey_id NOT IN (
--           SELECT id FROM public.journeys
--           WHERE status = 'sos'
--             AND started_at > NOW() - INTERVAL '7 years'
--         );
--     $$
--   );

-- Manual cleanup function (can be called via Edge Function or pg_cron)
CREATE OR REPLACE FUNCTION purge_old_journey_points()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.journey_points
    WHERE recorded_at < NOW() - INTERVAL '30 days'
      AND journey_id NOT IN (
        SELECT id FROM public.journeys
        WHERE status = 'sos'
          AND started_at > NOW() - INTERVAL '7 years'
      );
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
