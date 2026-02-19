-- ============================================================
-- 22. Admin analytics view
-- Phase 8: Admin Dashboard — Analytics
-- ============================================================

CREATE OR REPLACE VIEW admin_daily_stats AS
SELECT
    DATE(started_at) AS date,
    COUNT(DISTINCT user_id) AS active_users,
    COUNT(*) AS total_journeys,
    AVG(r.safety_score) AS avg_safety_score,
    COUNT(CASE WHEN j.status = 'sos' THEN 1 END) AS sos_count
FROM journeys j
LEFT JOIN routes r ON j.route_id = r.id
WHERE started_at > NOW() - INTERVAL '90 days'
GROUP BY DATE(started_at)
ORDER BY date DESC;
