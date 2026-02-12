# Phase 08 — Admin Dashboard

## Objective
Build an admin dashboard for managing user reports, moderating unsafe zone flags, monitoring system analytics, and tuning safety score parameters.

## Prerequisites
- All core phases (1-7) complete
- Admin users provisioned in Supabase Auth with `admin` role

## Deliverables
| # | Deliverable | Detailed File |
|---|-------------|---------------|
| 1 | Admin authentication & access control | [01_admin_auth.md](./01_admin_auth.md) |
| 2 | Moderation workflows | [02_moderation_workflows.md](./02_moderation_workflows.md) |
| 3 | Analytics dashboard | [03_analytics_dashboard.md](./03_analytics_dashboard.md) |
| 4 | Safety score tuning panel | [04_safety_score_tuning.md](./04_safety_score_tuning.md) |

## Implementation Choice

> **Decision Required:** Build with Flutter Web (code reuse) or React/Next.js (better web admin experience).
> 
> **Recommendation:** Flutter Web for MVP, migrate to React if complexity warrants it.

## Admin Features

### User Management
- View all users (with verification status)
- Suspend/ban accounts
- View user activity logs

### Flag Moderation  
- Queue of unverified unsafe zone flags
- Approve/reject/merge flags
- View flag history and reporter credibility

### SOS Event Monitoring
- Live SOS events dashboard
- Resolution management
- Response time analytics

### Analytics
- Daily active users
- Journeys per day/week/month
- Safety score distribution
- SOS trigger patterns
- AI cost monitoring

### Safety Score Tuning
- Adjust component weights (crime, flags, commercial, lighting, population)
- Override individual zone severity
- Preview safety score changes before applying

## Database Schema

```sql
-- Admin role management
CREATE TABLE public.admin_users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id),
    role TEXT DEFAULT 'moderator' CHECK (role IN ('moderator', 'admin', 'super_admin')),
    permissions JSONB DEFAULT '["view_users", "moderate_flags"]',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin audit log (every admin action logged)
CREATE TABLE public.admin_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES auth.users(id),
    action TEXT NOT NULL,           -- 'approve_flag', 'ban_user', etc.
    target_type TEXT,               -- 'user', 'flag', 'zone'
    target_id UUID,
    details JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin alerts
CREATE TABLE public.admin_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    severity TEXT DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
    acknowledged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## RLS for Admin Access

```sql
-- Only admins can access admin-specific tables
CREATE POLICY "Admins only" ON public.admin_users
    FOR ALL USING (
        auth.uid() IN (SELECT user_id FROM admin_users)
    );

-- Admins can read all user profiles
CREATE POLICY "Admins read all users" ON public.user_profiles
    FOR SELECT USING (
        auth.uid() = id  -- Own profile
        OR auth.uid() IN (SELECT user_id FROM admin_users)  -- Or admin
    );
```

## Security Checkpoints
- [ ] MFA required for admin login
- [ ] All admin actions logged with audit trail
- [ ] Admin permissions granular (RBAC)
- [ ] Admin session timeout (30 min inactivity)

## Git Branch
```bash
git checkout -b phase/08-admin-dashboard
```

## Verification Criteria
- [ ] Admin can log in with MFA
- [ ] Flag moderation queue functional
- [ ] Analytics charts display live data
- [ ] Safety score weights adjustable
- [ ] All admin actions audited
