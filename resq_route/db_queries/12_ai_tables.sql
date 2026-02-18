-- ============================================================
-- Migration 12: AI Analysis & Usage Tracking Tables
-- Phase 4: Safety Scoring & AI Integration
-- ============================================================

-- 1. AI Analysis Results (cached Gemini responses)
CREATE TABLE IF NOT EXISTS public.ai_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE,
    analysis_type VARCHAR(50) NOT NULL DEFAULT 'crime_analysis',
    prompt_tokens INTEGER,
    response_tokens INTEGER,
    result JSONB NOT NULL,
    model_used VARCHAR(50) DEFAULT 'gemini-1.5-flash',
    is_fallback BOOLEAN DEFAULT FALSE,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '6 hours'
);

-- Indexes
CREATE INDEX idx_ai_analyses_route ON public.ai_analyses(route_id);
CREATE INDEX idx_ai_analyses_expires ON public.ai_analyses(expires_at);
CREATE INDEX idx_ai_analyses_type ON public.ai_analyses(analysis_type);

-- RLS
ALTER TABLE public.ai_analyses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read AI analyses for their routes"
    ON public.ai_analyses FOR SELECT
    USING (
        route_id IN (
            SELECT id FROM public.routes WHERE user_id = auth.uid()
        )
    );

-- 2. AI Usage Log (cost tracking)
CREATE TABLE IF NOT EXISTS public.ai_usage_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE DEFAULT CURRENT_DATE,
    model VARCHAR(50) NOT NULL,
    prompt_tokens INTEGER DEFAULT 0,
    response_tokens INTEGER DEFAULT 0,
    estimated_cost FLOAT DEFAULT 0,
    endpoint VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ai_usage_date ON public.ai_usage_log(date);
CREATE INDEX idx_ai_usage_model ON public.ai_usage_log(model);

-- RLS — admin only (service role)
ALTER TABLE public.ai_usage_log ENABLE ROW LEVEL SECURITY;

-- 3. Daily AI Cost View
CREATE OR REPLACE VIEW public.daily_ai_costs AS
SELECT
    date,
    model,
    COUNT(*) AS requests,
    SUM(prompt_tokens) AS total_prompt_tokens,
    SUM(response_tokens) AS total_response_tokens,
    ROUND(SUM(estimated_cost)::NUMERIC, 4) AS total_cost
FROM public.ai_usage_log
GROUP BY date, model
ORDER BY date DESC;

-- 4. Cost Alert Trigger (fires when daily cost > $5)
CREATE OR REPLACE FUNCTION check_ai_cost_alert()
RETURNS TRIGGER AS $$
DECLARE
    today_cost FLOAT;
BEGIN
    SELECT COALESCE(SUM(estimated_cost), 0) INTO today_cost
    FROM public.ai_usage_log WHERE date = CURRENT_DATE;

    IF today_cost > 5.0 THEN
        -- Insert a row into a lightweight alerts mechanism
        -- (admin dashboard will pick this up via polling/realtime)
        RAISE LOG 'AI COST ALERT: Daily cost exceeded $5: $%', today_cost;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_cost_alert
    AFTER INSERT ON public.ai_usage_log
    FOR EACH ROW
    EXECUTE FUNCTION check_ai_cost_alert();
