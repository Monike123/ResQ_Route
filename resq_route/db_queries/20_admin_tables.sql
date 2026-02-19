-- ============================================================
-- 20. Admin tables
-- Phase 8: Admin Dashboard
-- ============================================================

-- ── Admin users & roles ──
CREATE TABLE IF NOT EXISTS public.admin_users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id),
    role TEXT DEFAULT 'moderator'
        CHECK (role IN ('moderator', 'admin', 'super_admin')),
    permissions JSONB DEFAULT '["view_users", "moderate_flags"]',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins only"
    ON public.admin_users FOR ALL
    USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- ── Admin audit log ──
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES auth.users(id),
    action TEXT NOT NULL,
    target_type TEXT,
    target_id UUID,
    details JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_admin_id ON public.admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON public.admin_audit_log(created_at DESC);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins read audit log"
    ON public.admin_audit_log FOR SELECT
    USING (auth.uid() IN (SELECT user_id FROM admin_users));

CREATE POLICY "Admins insert audit log"
    ON public.admin_audit_log FOR INSERT
    WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- ── Admin alerts ──
CREATE TABLE IF NOT EXISTS public.admin_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    severity TEXT DEFAULT 'info'
        CHECK (severity IN ('info', 'warning', 'critical')),
    acknowledged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.admin_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins manage alerts"
    ON public.admin_alerts FOR ALL
    USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- ── Helper functions ──
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION has_admin_permission(required_permission TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admin_users
        WHERE user_id = auth.uid()
        AND permissions ? required_permission
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Allow admins to read all user_profiles ──
CREATE POLICY "Admins read all users"
    ON public.user_profiles FOR SELECT
    USING (
        auth.uid() = id
        OR auth.uid() IN (SELECT user_id FROM admin_users)
    );
