# 03 — Analytics Dashboard

## Objective
Display real-time and historical analytics for platform monitoring.

---

## Key Metrics

| Metric | Query Source | Update Frequency |
|--------|-------------|------------------|
| Daily Active Users | `journeys` WHERE `started_at` = today | Real-time |
| Journeys per Day | `journeys` GROUP BY date | Hourly |
| Average Safety Score | `routes` AVG(safety_score) | Daily |
| SOS Events | `sos_events` count + trends | Real-time |
| Flag Submissions | `unsafe_zones` count by status | Hourly |
| AI API Cost | `ai_usage_log` SUM(cost) | Daily |

## Dashboard Layout

```
┌──────────────────────────────────────────────┐
│  📊 ResQ Route Admin Dashboard               │
├──────────────────────────────────────────────┤
│                                              │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐    │
│  │ 1,234│  │  89  │  │ 72.5 │  │   3  │    │
│  │ Users│  │Today │  │ Avg  │  │ SOS  │    │
│  │      │  │Trips │  │Score │  │Today │    │
│  └──────┘  └──────┘  └──────┘  └──────┘    │
│                                              │
│  [Journeys Chart - 30 Day Trend]             │
│  ┌──────────────────────────────────┐        │
│  │  📈 ________________________    │        │
│  │      ___/                       │        │
│  │  ___/                           │        │
│  └──────────────────────────────────┘        │
│                                              │
│  [Safety Score Distribution]                 │
│  ┌──────────────────────────────────┐        │
│  │  0-20: ██ 5%                    │        │
│  │  20-40: ████ 12%                │        │
│  │  40-60: ████████ 25%            │        │
│  │  60-80: █████████████ 38%       │        │
│  │  80-100: ██████ 20%             │        │
│  └──────────────────────────────────┘        │
│                                              │
│  [AI Cost Monitor - Monthly]                 │
│  Budget: $50/mo | Used: $28.50               │
│  ━━━━━━━━━━━━━━━░░░░░░  57%                 │
└──────────────────────────────────────────────┘
```

## SQL Views for Analytics

```sql
CREATE VIEW admin_daily_stats AS
SELECT 
    DATE(started_at) as date,
    COUNT(DISTINCT user_id) as active_users,
    COUNT(*) as total_journeys,
    AVG(r.safety_score) as avg_safety_score,
    COUNT(CASE WHEN j.status = 'sos' THEN 1 END) as sos_count
FROM journeys j
LEFT JOIN routes r ON j.route_id = r.id
WHERE started_at > NOW() - INTERVAL '90 days'
GROUP BY DATE(started_at)
ORDER BY date DESC;
```

---

## Verification
- [ ] Dashboard loads with current metrics
- [ ] Charts display historical trends
- [ ] Real-time SOS events visible
- [ ] AI cost monitor shows usage vs budget
