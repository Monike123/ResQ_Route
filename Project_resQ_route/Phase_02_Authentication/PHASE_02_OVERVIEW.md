# Phase 02 — Identity & Authentication

## Objective
Implement the complete authentication system including signup, login, Aadhaar/PAN verification, emergency contact setup, and session management using Supabase Auth.

## Prerequisites
- Phase 1 completed (Flutter project, Supabase initialized)
- Supabase Auth configured (phone + email)
- `user_profiles` table with RLS

## Deliverables
| # | Deliverable | Detailed File |
|---|-------------|---------------|
| 1 | Supabase Auth setup & Flutter integration | [01_supabase_auth_setup.md](./01_supabase_auth_setup.md) |
| 2 | User registration flow (UI + logic) | [02_user_registration_flow.md](./02_user_registration_flow.md) |
| 3 | Login flow (UI + logic) | [03_login_flow.md](./03_login_flow.md) |
| 4 | Aadhaar/PAN verification integration | [04_aadhaar_pan_verification.md](./04_aadhaar_pan_verification.md) |
| 5 | Emergency contacts system | [05_emergency_contacts.md](./05_emergency_contacts.md) |
| 6 | Session management & token handling | [06_session_management.md](./06_session_management.md) |
| 7 | Abuse prevention & rate limiting | [07_abuse_prevention.md](./07_abuse_prevention.md) |

## Security Checkpoints (Phase 2)
- [ ] Argon2 password hashing (Supabase handles this)
- [ ] JWT access tokens (15-min expiry)
- [ ] Refresh token rotation enabled
- [ ] Aadhaar/PAN — only hashed references stored
- [ ] Secure token storage (Flutter Secure Storage)
- [ ] Login rate limiting (5 attempts / 15 min)
- [ ] RLS policies on `user_profiles` and `emergency_contacts`
- [ ] Phone numbers masked in logs

## Database Schema (Phase 2)
```sql
-- user_profiles (created in Phase 1)
-- emergency_contacts (created in this phase)
-- sessions (managed by Supabase Auth)
```

## UI Screens
1. **Splash Screen** — App loading with logo
2. **Login Screen** — Phone/email + password
3. **Signup Screen** — Full registration form
4. **OTP Verification** — Phone/email OTP entry
5. **Aadhaar/PAN Verification** — Identity verification
6. **Emergency Contacts** — Select 3 contacts
7. **Profile Setup** — Optional profile image, gender

## Git Branch
```bash
git checkout -b phase/02-authentication
```

## Verification Criteria
- [ ] New user can sign up with phone + password
- [ ] OTP verification works
- [ ] Login returns JWT token
- [ ] Emergency contacts are saved and retrievable
- [ ] Aadhaar/PAN verification flow works (or stub)
- [ ] Tokens stored securely on device
- [ ] Rate limiting prevents brute force
