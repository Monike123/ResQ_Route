-- ============================================================
-- 21. Safety configuration
-- Phase 8: Admin Dashboard — Score tuning
-- ============================================================

CREATE TABLE IF NOT EXISTS public.safety_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    updated_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.safety_config ENABLE ROW LEVEL SECURITY;

-- Everyone can read config (needed by scoring algorithm)
CREATE POLICY "Anyone can read config"
    ON public.safety_config FOR SELECT
    USING (true);

-- Only admins can update
CREATE POLICY "Admins update config"
    ON public.safety_config FOR UPDATE
    USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- Insert default weights
INSERT INTO safety_config (config_key, config_value) VALUES
('score_weights', '{
    "crime_density": 0.35,
    "user_flags": 0.25,
    "commercial": 0.20,
    "lighting": 0.10,
    "population": 0.10
}')
ON CONFLICT (config_key) DO NOTHING;
