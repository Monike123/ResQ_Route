# 06 — Route Caching Strategy

## Objective
Cache frequently requested route segments and safety scores to reduce API costs and improve response times.

---

## Caching Layers

| Layer | What | TTL | Storage |
|-------|------|-----|---------|
| **Client** | Recent route results | Session | In-memory (Riverpod state) |
| **Database** | Computed safety scores per route segment | 24 hours | PostgreSQL `route_cache` table |
| **AI Response** | Gemini crime analysis results | 6 hours | PostgreSQL `ai_cache` table |
| **Places** | Places API autocomplete results | 1 hour | Client-side (SharedPreferences) |

---

## Route Cache Table

```sql
CREATE TABLE public.route_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key VARCHAR(255) UNIQUE NOT NULL,   -- Hash of origin+destination+mode
    route_data JSONB NOT NULL,
    safety_scores JSONB,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    hit_count INTEGER DEFAULT 0
);

CREATE INDEX idx_route_cache_key ON public.route_cache(cache_key);
CREATE INDEX idx_route_cache_expires ON public.route_cache(expires_at);

-- Cleanup expired cache (run via pg_cron)
CREATE OR REPLACE FUNCTION cleanup_route_cache()
RETURNS void AS $$
BEGIN
    DELETE FROM public.route_cache WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup every hour
SELECT cron.schedule('cleanup-route-cache', '0 * * * *', 'SELECT cleanup_route_cache()');
```

---

## Cache Key Generation

```typescript
function generateCacheKey(
  originLat: number, originLng: number,
  destLat: number, destLng: number,
  mode: string = 'walking'
): string {
  // Round coordinates to 4 decimal places (~11m precision)
  // This ensures nearby origins/destinations share cache
  const key = `${originLat.toFixed(4)}_${originLng.toFixed(4)}_` +
              `${destLat.toFixed(4)}_${destLng.toFixed(4)}_${mode}`;
  
  // SHA-256 hash for consistent key length
  return await crypto.subtle.digest('SHA-256', 
    new TextEncoder().encode(key)
  ).then(buf => Array.from(new Uint8Array(buf))
    .map(b => b.toString(16).padStart(2, '0')).join(''));
}
```

---

## Cache-First Route Fetching

```typescript
// In calculate-routes Edge Function:
async function getRoutesWithCache(params) {
  const cacheKey = generateCacheKey(
    params.originLat, params.originLng,
    params.destLat, params.destLng,
  );

  // 1. Check cache
  const { data: cached } = await supabase
    .from('route_cache')
    .select()
    .eq('cache_key', cacheKey)
    .gt('expires_at', new Date().toISOString())
    .single();

  if (cached) {
    // Cache hit — increment counter
    await supabase
      .from('route_cache')
      .update({ hit_count: cached.hit_count + 1 })
      .eq('id', cached.id);
    
    return cached.route_data;
  }

  // 2. Cache miss — fetch from Google API
  const routes = await fetchFromGoogleDirections(params);

  // 3. Store in cache (24hr TTL)
  await supabase.from('route_cache').upsert({
    cache_key: cacheKey,
    route_data: routes,
    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
  });

  return routes;
}
```

---

## Cost Savings Estimate

| Without Cache | With Cache (est. 60% hit rate) |
|---------------|-------------------------------|
| 1000 route requests/day | 400 API calls/day |
| $5/1000 Directions API calls | ~$2/day |
| $150/month | ~$60/month |

---

## Verification
- [ ] Cache checked before API call
- [ ] Cache miss triggers API call and stores result
- [ ] Cache hit returns stored data quickly
- [ ] Expired cache entries auto-cleaned
- [ ] Cache key groups nearby locations
- [ ] Hit count tracked for analytics
