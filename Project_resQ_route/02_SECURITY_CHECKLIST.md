# 🔒 Security Checklist — ResQ Route (Cross-Phase)

This checklist tracks security measures across ALL phases. Each item is tagged with the phase where it should be implemented.

---

## 1. Authentication & Identity Security

- [ ] **[Phase 2]** Implement Supabase Auth with email/phone + password
- [ ] **[Phase 2]** Enforce strong password policy (min 8 chars, upper, lower, number, special)
- [ ] **[Phase 2]** JWT access token (15-min expiry) via Supabase
- [ ] **[Phase 2]** Refresh token rotation (Supabase handles this)
- [ ] **[Phase 2]** Device session tracking (store device info per session)
- [ ] **[Phase 2]** Login rate limiting (max 5 attempts per 15 min)
- [ ] **[Phase 2]** Account lockout after 10 failed attempts
- [ ] **[Phase 2]** IP anomaly detection logging
- [ ] **[Phase 2]** Aadhaar/PAN verification — never store raw numbers, only hashed reference
- [ ] **[Phase 9]** MFA for admin accounts

---

## 2. Data Encryption

- [ ] **[Phase 1]** TLS/HTTPS enforced for all API communication (Supabase provides this)
- [ ] **[Phase 1]** WSS (WebSocket Secure) for realtime channels
- [ ] **[Phase 2]** Tokens stored in Flutter Secure Storage (AES-256 on device)
- [ ] **[Phase 5]** Location data encrypted in transit
- [ ] **[Phase 9]** Database-level encryption at rest (Supabase managed)
- [ ] **[Phase 7]** Report PDFs encrypted in storage buckets

---

## 3. Row Level Security (RLS) — Supabase

- [ ] **[Phase 2]** `users` — users can only read/update their own row
- [ ] **[Phase 2]** `emergency_contacts` — users can only access their own contacts
- [ ] **[Phase 3]** `routes` — users can only access routes for their journeys
- [ ] **[Phase 5]** `journeys` — users can only access their own journeys
- [ ] **[Phase 5]** `journey_points` — restricted to journey owner
- [ ] **[Phase 6]** `emergency_logs` — restricted to journey owner + admin
- [ ] **[Phase 7]** `reports` — restricted to report owner + admin
- [ ] **[Phase 8]** Admin-specific RLS policies for moderation access

---

## 4. Input Validation

- [ ] **[Phase 2]** Phone number format validation (`^[6-9]\d{9}$`)
- [ ] **[Phase 2]** Email format validation
- [ ] **[Phase 2]** Password strength validation (client + server)
- [ ] **[Phase 3]** GPS coordinate validation (lat: -90 to 90, lng: -180 to 180)
- [ ] **[Phase 4]** AI prompt sanitization (prevent prompt injection)
- [ ] **[Phase 6]** SOS trigger type validation (enum check)
- [ ] **[Phase 7]** Report request authorization validation
- [ ] **[Phase 8]** Admin action input validation
- [ ] **[Phase 9]** SQL injection prevention audit (Supabase uses parameterized queries)

---

## 5. API & Rate Limiting

- [ ] **[Phase 2]** Auth endpoints: max 5 req/min per IP
- [ ] **[Phase 3]** Route calculation: max 10 req/min per user
- [ ] **[Phase 6]** SOS endpoint: no rate limit (critical safety)
- [ ] **[Phase 8]** Admin API: authenticated + role-checked
- [ ] **[Phase 9]** Global API rate limiting via Supabase/Cloudflare

---

## 6. PII Handling

- [ ] **[Phase 2]** Aadhaar number — NEVER stored raw, only verification status + hashed ref
- [ ] **[Phase 2]** PAN number — NEVER stored raw, only verification status + hashed ref
- [ ] **[Phase 5]** Location data — retained max 30 days, then purged
- [ ] **[Phase 6]** Emergency logs — retained 7 years (legally mandated)
- [ ] **[Phase 9]** User data deletion flow (right to be forgotten)
- [ ] **[Phase 9]** Data anonymization for analytics
- [ ] **[Phase 9]** Consent management system

---

## 7. Logging & Redaction

- [ ] **[Phase 1]** Structured JSON logging setup
- [ ] **[Phase 2]** Password NEVER logged
- [ ] **[Phase 2]** Phone numbers masked in logs (e.g., `98****3210`)
- [ ] **[Phase 5]** Location data handling policy in logs
- [ ] **[Phase 6]** Emergency forensic snapshots — immutable append-only
- [ ] **[Phase 8]** Admin action audit trail
- [ ] **[Phase 9]** Full log redaction audit

---

## 8. Secrets Management

- [ ] **[Phase 1]** `.env` file for local secrets, NEVER committed
- [ ] **[Phase 1]** `.gitignore` includes all secret files
- [ ] **[Phase 1]** Supabase keys as environment variables only
- [ ] **[Phase 3]** Google Maps API key — restricted by app package name
- [ ] **[Phase 4]** Gemini API key — stored as secret, rate-limited
- [ ] **[Phase 6]** Twilio credentials — stored as secrets
- [ ] **[Phase 9]** Full secrets audit — no hardcoded credentials anywhere

---

## 9. Threat Model (STRIDE)

- [ ] **[Phase 9]** **Spoofing** — Aadhaar/PAN verification prevents fake accounts
- [ ] **[Phase 9]** **Tampering** — Immutable forensic logs, SHA-256 report hashing
- [ ] **[Phase 9]** **Repudiation** — Detailed audit logs for all critical actions
- [ ] **[Phase 9]** **Information Disclosure** — RLS, encryption, data redaction
- [ ] **[Phase 9]** **Denial of Service** — Rate limiting, Cloudflare DDoS protection
- [ ] **[Phase 9]** **Elevation of Privilege** — RBAC, RLS, admin MFA

---

## 10. Mobile App Security

- [ ] **[Phase 1]** ProGuard/R8 obfuscation for Android release builds
- [ ] **[Phase 2]** Certificate pinning for Supabase connections
- [ ] **[Phase 2]** Secure storage for all tokens (Flutter Secure Storage)
- [ ] **[Phase 5]** Background service permissions properly declared
- [ ] **[Phase 9]** Root/jailbreak detection
- [ ] **[Phase 9]** Anti-tampering measures
- [ ] **[Phase 9]** Dependency vulnerability scan

---

## 11. Pre-Release Security Gate

Before any deployment to production:
- [ ] All RLS policies tested and verified
- [ ] Penetration test completed
- [ ] Dependency vulnerability scan clean
- [ ] Secrets audit passed
- [ ] OWASP Top 10 mobile checklist reviewed
- [ ] PII handling compliance verified
- [ ] Aadhaar compliance verified
