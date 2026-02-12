# 05 — Penetration Testing Plan

## Objective
Define a structured penetration testing plan targeting all critical attack surfaces.

---

## Test Scope

### In Scope
| Area | Target | Priority |
|------|--------|----------|
| Authentication | Login, signup, OTP, session management | Critical |
| Authorization | RLS bypass, privilege escalation | Critical |
| API Security | Edge Functions, rate limiting | High |
| Data Protection | PII exposure, encryption | Critical |
| Mobile App | APK reverse engineering, local storage | High |
| SOS System | False triggering, message interception | Critical |
| AI Integration | Prompt injection, response manipulation | Medium |

### Out of Scope
- Supabase infrastructure (managed by Supabase team)
- Google Maps API infrastructure
- Twilio infrastructure
- Physical device security

---

## Test Cases

### Authentication Tests
1. Brute force login — verify rate limiting activates
2. OTP replay — verify expired OTPs rejected
3. Token manipulation — verify JWT cannot be forged
4. Session fixation — verify session IDs regenerate
5. Password reset — verify cannot reset other users' passwords

### Authorization Tests
1. Access other user's profile — verify RLS blocks
2. Access other user's journey data — verify RLS blocks
3. Access admin endpoints as regular user — verify blocked
4. Modify safety scores via client — verify service role required
5. Delete other user's emergency contacts — verify blocked

### API Tests
1. SQL injection via search inputs — verify parameterized queries
2. XSS via flag submission text — verify sanitization
3. IDOR (Insecure Direct Object Reference) — verify UUID not guessable
4. Mass API calls — verify rate limiting
5. Invalid coordinate injection — verify bounds checking

### Mobile Tests
1. Decompile APK — verify obfuscation effective
2. Extract tokens from device — verify encrypted storage
3. Intercept network traffic — verify TLS + pinning
4. Modify local data — verify server validates

---

## Automated Tools

| Tool | Purpose |
|------|---------|
| OWASP ZAP | Web application vulnerability scanning |
| sqlmap | SQL injection testing |
| Burp Suite | API intercepting and testing |
| MobSF | Mobile app static analysis |
| apktool | APK decompilation analysis |

---

## Reporting

Each finding documented with:
- Severity: Critical / High / Medium / Low / Info
- Description: What was found
- Reproduction steps: How to reproduce
- Impact: What could go wrong
- Remediation: How to fix
- Status: Open / Fixed / Accepted Risk

---

## Verification
- [ ] All test cases executed
- [ ] Critical/High findings fixed before deployment
- [ ] Medium findings tracked with remediation plan
- [ ] Retest confirms fixes effective
- [ ] Pen test report signed off by team lead
