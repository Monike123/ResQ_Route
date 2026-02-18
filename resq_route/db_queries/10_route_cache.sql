-- 10: Route Cache Table
-- Caches computed routes (24hr TTL) to reduce Google API costs.

CREATE TABLE public.route_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key VARCHAR(255) UNIQUE NOT NULL,   -- SHA-256 of origin+dest+mode
    route_data JSONB NOT NULL,
    safety_scores JSONB,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    hit_count INTEGER DEFAULT 0
);

CREATE INDEX idx_route_cache_key ON public.route_cache(cache_key);
CREATE INDEX idx_route_cache_expires ON public.route_cache(expires_at);

-- Cleanup expired cache entries
CREATE OR REPLACE FUNCTION cleanup_route_cache()
RETURNS void AS $$
BEGIN
    DELETE FROM public.route_cache WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Optional: schedule hourly cleanup via pg_cron (if enabled)
-- SELECT cron.schedule('cleanup-route-cache', '0 * * * *', 'SELECT cleanup_route_cache()');
