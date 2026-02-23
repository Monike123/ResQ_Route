-- 09: Crime Data Table (Updated for AI Web Search Pipeline)
-- Crime records from AI web search (Gemini/Perplexity) + future government data.

CREATE TABLE public.crime_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location GEOMETRY(POINT, 4326),
    crime_type VARCHAR(100) NOT NULL,
    severity TEXT NOT NULL
        CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT,
    source VARCHAR(100),               -- 'ai_gemini', 'ai_perplexity', 'government', 'user_report'
    route_name VARCHAR(500),           -- Route/area name for cache lookup
    city VARCHAR(200),                 -- City/region context
    occurred_at TIMESTAMPTZ,
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    ai_confidence FLOAT,               -- AI analysis confidence (0-1)
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',  -- Cache TTL
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial + filter indexes
CREATE INDEX idx_crime_data_location ON public.crime_data USING GIST (location);
CREATE INDEX idx_crime_data_type ON public.crime_data(crime_type);
CREATE INDEX idx_crime_data_severity ON public.crime_data(severity);
CREATE INDEX idx_crime_data_occurred_at ON public.crime_data(occurred_at);
CREATE INDEX idx_crime_data_route_name ON public.crime_data(route_name);
CREATE INDEX idx_crime_data_expires_at ON public.crime_data(expires_at);

-- RLS: Read-only for authenticated, insert/update by service role only
ALTER TABLE public.crime_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read crime data"
    ON public.crime_data FOR SELECT
    USING (auth.uid() IS NOT NULL);
