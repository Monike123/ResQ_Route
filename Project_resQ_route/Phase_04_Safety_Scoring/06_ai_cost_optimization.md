# 06 — AI Cost Optimization

## Objective
Control and optimize Gemini API costs through caching, batching, model selection, and usage monitoring.

---

## Cost Controls

| Strategy | Savings | Implementation |
|----------|---------|---------------|
| **Response Caching** | ~60% | Cache AI results for 6 hours per route segment |
| **Model Selection** | ~40% | Use `gemini-1.5-flash` (cheaper) instead of `gemini-1.5-pro` |
| **Prompt Optimization** | ~20% | Minimize prompt tokens, use structured data |
| **Batch Processing** | ~15% | Batch nearby routes into single API call |
| **Usage Alerts** | N/A | Alert when daily/monthly cost exceeds threshold |

## Cost Estimation

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Avg per route analysis |
|-------|----------------------|------------------------|----------------------|
| gemini-1.5-flash | $0.075 | $0.30 | ~$0.002 |
| gemini-1.5-pro | $1.25 | $5.00 | ~$0.03 |

**Expected monthly cost** (10k routes/month, 60% cache hit rate):
- Flash: 4000 × $0.002 = **$8/month**
- Pro: 4000 × $0.03 = **$120/month**

> Use `gemini-1.5-flash` by default; `gemini-1.5-pro` only for deep analysis on admin request.

## Usage Tracking

```sql
CREATE TABLE public.ai_usage_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE DEFAULT CURRENT_DATE,
    model VARCHAR(50),
    prompt_tokens INTEGER,
    response_tokens INTEGER,
    estimated_cost FLOAT,
    endpoint VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily usage view
CREATE VIEW daily_ai_costs AS
SELECT 
    date,
    model,
    COUNT(*) as requests,
    SUM(prompt_tokens) as total_prompt_tokens,
    SUM(response_tokens) as total_response_tokens,
    SUM(estimated_cost) as total_cost
FROM ai_usage_log
GROUP BY date, model
ORDER BY date DESC;
```

## Cost Alert Rule
```sql
-- Alert when daily cost exceeds $5
CREATE OR REPLACE FUNCTION check_ai_cost_alert()
RETURNS TRIGGER AS $$
DECLARE
    today_cost FLOAT;
BEGIN
    SELECT COALESCE(SUM(estimated_cost), 0) INTO today_cost
    FROM ai_usage_log WHERE date = CURRENT_DATE;

    IF today_cost > 5.0 THEN
        -- Insert alert (admin dashboard picks this up)
        INSERT INTO admin_alerts (type, message, severity)
        VALUES ('ai_cost', 'Daily AI cost exceeded $5: $' || today_cost, 'warning');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## Verification
- [ ] AI responses cached for 6 hours
- [ ] Token usage logged per request
- [ ] Cost alert fires above threshold
- [ ] Flash model used by default
- [ ] Cache hit rate trackable in analytics
