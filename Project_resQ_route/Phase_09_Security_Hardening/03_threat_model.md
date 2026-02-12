# 03 — Threat Model (STRIDE)

## Objective
Systematically identify and mitigate security threats using the STRIDE framework.

---

## STRIDE Analysis

### S — Spoofing (Identity)

| Threat | Target | Mitigation |
|--------|--------|-----------|
| Fake account creation | Auth system | Aadhaar/PAN verification, OTP |
| Session hijacking | JWT tokens | Short expiry (15min), rotation |
| Admin impersonation | Admin dashboard | MFA required |

### T — Tampering (Data Integrity)

| Threat | Target | Mitigation |
|--------|--------|-----------|
| Modified SRR reports | Reports | SHA-256 integrity hash |
| Altered safety scores | Routes DB | RLS + service role only for writes |
| Tampered forensic data | SOS snapshots | Immutable storage bucket |
| Modified GPS data | Journey points | Kalman filter + anomaly detection |

### R — Repudiation (Deniability)

| Threat | Target | Mitigation |
|--------|--------|-----------|
| Deny SOS trigger | Emergency system | Immutable event log |
| Deny flag submission | Unsafe zones | User ID + timestamp audit |
| Admin denies action | Admin panel | Comprehensive audit trail |

### I — Information Disclosure

| Threat | Target | Mitigation |
|--------|--------|-----------|
| PII leak via logs | Logging system | Log redaction |
| API key exposure | Client code | Edge Functions proxy |
| Location data leak | Database | RLS + 30-day retention |
| Aadhaar number exposure | User profiles | SHA-256 hash only |

### D — Denial of Service

| Threat | Target | Mitigation |
|--------|--------|-----------|
| Brute force login | Auth system | Rate limiting (5/15min) |
| API spam | Edge Functions | Supabase rate limits |
| SMS bombing | Twilio | Per-user SMS limits |
| DB overload | PostgreSQL | Connection pooling, indexes |

### E — Elevation of Privilege

| Threat | Target | Mitigation |
|--------|--------|-----------|
| User acts as admin | Admin routes | RLS + role check functions |
| Cross-user data access | User data | RLS on all tables |
| Service key theft | Edge Functions | Environment variables, never in client |

---

## Risk Matrix

| Risk | Likelihood | Impact | Priority |
|------|-----------|--------|----------|
| PII data breach | Medium | Critical | 🔴 P0 |
| Account takeover | Low | High | 🟠 P1 |
| SOS system failure | Low | Critical | 🔴 P0 |
| API key exposure | Low | High | 🟠 P1 |
| GPS spoofing | Medium | Medium | 🟡 P2 |
| DDoS on API | Low | Medium | 🟡 P2 |

---

## Verification
- [ ] All STRIDE categories analyzed
- [ ] P0 risks have mitigations implemented
- [ ] P1 risks have mitigations planned
- [ ] Risk matrix reviewed quarterly
