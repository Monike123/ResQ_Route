-- ============================================
-- 03: Device Sessions Table
-- Run THIRD in Supabase SQL Editor
-- ============================================

CREATE TABLE IF NOT EXISTS public.device_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name VARCHAR(100),
    device_os VARCHAR(50),
    device_model VARCHAR(100),
    app_version VARCHAR(20),
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Row Level Security
ALTER TABLE public.device_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own device sessions"
    ON public.device_sessions FOR ALL
    USING (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_device_sessions_user_id
    ON public.device_sessions(user_id);
