-- ============================================================
-- 23. Data retention & right-to-deletion
-- Phase 9: Security Hardening
-- ============================================================

-- ── Right-to-deletion (GDPR / data protection) ──
CREATE OR REPLACE FUNCTION delete_user_data(target_user_id UUID)
RETURNS void AS $$
BEGIN
    -- Delete in dependency order
    DELETE FROM feedback WHERE user_id = target_user_id;
    DELETE FROM reports WHERE user_id = target_user_id;
    DELETE FROM journey_points WHERE journey_id IN (
        SELECT id FROM journeys WHERE user_id = target_user_id
    );
    DELETE FROM journeys WHERE user_id = target_user_id;
    DELETE FROM routes WHERE user_id = target_user_id;
    DELETE FROM emergency_contacts WHERE user_id = target_user_id;
    DELETE FROM device_sessions WHERE user_id = target_user_id;

    -- Anonymize (don't delete) SOS events for legal retention (7 yr)
    UPDATE sos_events SET
        metadata = COALESCE(metadata, '{}'::jsonb) || '{"anonymized": true}'::jsonb
    WHERE user_id = target_user_id;

    -- Delete profile
    DELETE FROM user_profiles WHERE id = target_user_id;

    -- Note: storage files (profile images, PDFs) must be
    -- deleted via an Edge Function that calls the Storage API.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Auto-purge cron jobs (run via pg_cron if enabled) ──
-- Uncomment after enabling pg_cron on your Supabase project:

-- Purge location points older than 30 days (skip SOS-linked journeys)
-- SELECT cron.schedule('purge-location-data', '0 3 * * *',
--   $$DELETE FROM journey_points
--     WHERE recorded_at < NOW() - INTERVAL '30 days'
--     AND journey_id NOT IN (
--       SELECT journey_id FROM sos_events WHERE status != 'false_alarm'
--     )$$
-- );

-- Purge stale device sessions (30 days inactive)
-- SELECT cron.schedule('purge-device-sessions', '30 3 * * *',
--   $$DELETE FROM device_sessions
--     WHERE last_active_at < NOW() - INTERVAL '30 days'$$
-- );

-- Purge expired rate limit windows
-- SELECT cron.schedule('purge-rate-limits', '0 * * * *',
--   $$DELETE FROM rate_limits
--     WHERE window_start < NOW() - INTERVAL '15 minutes'$$
-- );
