-- 09: Crime Data Table
-- Historical crime records with geospatial indexing for route safety scoring.

CREATE TABLE public.crime_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location GEOMETRY(POINT, 4326) NOT NULL,
    crime_type VARCHAR(100) NOT NULL,
    severity TEXT NOT NULL
        CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT,
    source VARCHAR(100),               -- 'police_report', 'news', 'ai_analysis'
    occurred_at TIMESTAMPTZ,
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    ai_confidence FLOAT,               -- AI analysis confidence (0-1)
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial + filter indexes
CREATE INDEX idx_crime_data_location ON public.crime_data USING GIST (location);
CREATE INDEX idx_crime_data_type ON public.crime_data(crime_type);
CREATE INDEX idx_crime_data_severity ON public.crime_data(severity);
CREATE INDEX idx_crime_data_occurred_at ON public.crime_data(occurred_at);

-- RLS: Read-only for authenticated, insert/update by service role only
ALTER TABLE public.crime_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read crime data"
    ON public.crime_data FOR SELECT
    USING (auth.uid() IS NOT NULL);
