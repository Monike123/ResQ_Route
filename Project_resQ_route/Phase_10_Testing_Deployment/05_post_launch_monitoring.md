# 05 — Post-Launch Monitoring

## Objective
Monitor app health, user engagement, crash rates, and system performance after deployment.

---

## Monitoring Stack

| Tool | Purpose | Metrics |
|------|---------|---------|
| Firebase Crashlytics | Crash reporting | Crash-free rate, ANR rate |
| Supabase Dashboard | Database metrics | Connection count, query latency |
| Custom analytics | Business metrics | DAU, journeys/day, SOS events |
| Sentry (optional) | Error tracking | Unhandled exceptions, breadcrumbs |

## Key Metrics to Monitor

### System Health
- API response time (p50, p95, p99)
- Edge Function execution duration
- Database connection pool utilization
- Supabase Realtime subscription count

### Business Metrics
- Daily Active Users (DAU)
- Journeys started / completed per day
- Average safety score distribution
- SOS events triggered (rate + false alarm rate)
- Report generation count

### Error Budget
- Target: 99.9% uptime (8.7 hours downtime/year)
- Crash-free rate target: > 99.5%
- SOS delivery success rate target: > 99.9%

## Alerting Rules

| Condition | Severity | Action |
|-----------|----------|--------|
| Crash-free rate < 99% | Critical | Immediate investigation |
| SOS SMS delivery fails | Critical | Switch to fallback provider |
| Database connections > 80% | Warning | Scale or optimize |
| AI API cost > daily budget | Warning | Review and optimize |
| Edge Function > 10s latency | Warning | Investigate |

## Weekly Review Checklist
- [ ] Review crash reports and fix top crashers
- [ ] Check SOS delivery success rate
- [ ] Review AI cost trends
- [ ] Check user feedback submissions
- [ ] Monitor unsafe zone flag accuracy
- [ ] Review safety score feedback (too safe / too dangerous)

---

## Verification
- [ ] Crashlytics integrated and receiving data
- [ ] Custom analytics events firing
- [ ] Alert rules configured
- [ ] Weekly review process documented
