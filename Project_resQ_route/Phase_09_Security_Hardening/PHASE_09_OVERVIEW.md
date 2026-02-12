# Phase 09 — Security Hardening & Compliance

## Objective
Harden the entire application against security threats, ensure compliance with data protection regulations, and conduct penetration testing.

## Prerequisites
- All functional phases (1-8) complete
- Production deployment pending this phase

## Deliverables
| # | Deliverable | Detailed File |
|---|-------------|---------------|
| 1 | Encryption audit & implementation | [01_encryption_audit.md](./01_encryption_audit.md) |
| 2 | PII handling & data retention | [02_pii_handling.md](./02_pii_handling.md) |
| 3 | Threat model (STRIDE) | [03_threat_model.md](./03_threat_model.md) |
| 4 | Mobile app security | [04_mobile_app_security.md](./04_mobile_app_security.md) |
| 5 | Penetration testing plan | [05_penetration_testing.md](./05_penetration_testing.md) |

## Security Checklist (Comprehensive)

### Data in Transit
- [ ] TLS 1.3 for all HTTP connections
- [ ] WSS (WebSocket Secure) for Realtime
- [ ] Certificate pinning on mobile app
- [ ] No HTTP fallback — reject unencrypted connections

### Data at Rest
- [ ] Database encryption enabled (Supabase default)
- [ ] Aadhaar/PAN stored as SHA-256 hash only
- [ ] Tokens in Flutter Secure Storage (encrypted)
- [ ] API keys never in client code (Edge Functions only)

### Authentication
- [ ] Argon2 hashing (Supabase default)
- [ ] JWT expiry: 15 min access, rotatable refresh
- [ ] MFA for admin accounts
- [ ] Rate limiting: 5 login attempts / 15 min

### Authorization
- [ ] RLS on all tables
- [ ] Service role key only in Edge Functions
- [ ] Admin endpoints authenticated + role-checked

### Input Validation
- [ ] Phone: 10-digit Indian format
- [ ] Email: RFC 5322 compliance
- [ ] Coordinates: valid lat/lng ranges
- [ ] Text fields: max length + sanitization
- [ ] AI prompts: injection prevention

### Logging & Monitoring
- [ ] No PII in logs (phone masked, no Aadhaar)
- [ ] Admin actions audited
- [ ] SOS events immutably logged
- [ ] Error logs structured (JSON)

### Mobile Security
- [ ] Code obfuscation (`--obfuscate` flag)
- [ ] Split debug info saved separately
- [ ] Root/jailbreak detection
- [ ] Screenshot prevented on sensitive screens
- [ ] Clipboard cleared after paste on sensitive fields

## Git Branch
```bash
git checkout -b phase/09-security-hardening
```

## Verification Criteria
- [ ] Security checklist 100% complete
- [ ] STRIDE threat model documented
- [ ] Penetration test executed with findings addressed
- [ ] Data retention policies implemented
- [ ] No secrets exposed in client code
