# ResQ Route — Database Queries

Run these SQL files **in order** in the Supabase SQL Editor (Dashboard → SQL Editor → New Query).

| Order | File | Description |
|-------|------|-------------|
| 1 | `01_user_profiles.sql` | User profiles table + RLS + triggers |
| 2 | `02_emergency_contacts.sql` | Emergency contacts (3 per user) + RLS |
| 3 | `03_device_sessions.sql` | Device session tracking + RLS |
| 4 | `04_rate_limits.sql` | Server-side rate limiting + cleanup |
| 5 | `05_security_events.sql` | Security event logging (admin only) |

> **Prerequisites**: Supabase project created with Auth enabled (phone + email providers).
