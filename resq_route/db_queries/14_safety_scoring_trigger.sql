-- ============================================================
-- Migration 14: Auto-Score Trigger on Route Insert
-- Phase 4: Safety Scoring & AI Integration
-- ============================================================
-- When a route is inserted, automatically trigger safety scoring
-- via an Edge Function call using pg_net (async HTTP).
--
-- NOTE: pg_net must be enabled in Supabase Dashboard > Database > Extensions.
-- If pg_net is not available, scoring is triggered from the client instead.

-- Enable pg_net extension (if not already)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION trigger_safety_scoring()
RETURNS TRIGGER AS $$
BEGIN
    -- Async HTTP POST to the calculate-safety-score Edge Function
    PERFORM net.http_post(
        url := current_setting('app.supabase_url', true) || '/functions/v1/calculate-safety-score',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.service_role_key', true)
        ),
        body := jsonb_build_object('routeId', NEW.id)
    );
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- If pg_net is not available or HTTP fails, log and continue
        -- Scoring will be triggered from the client as fallback
        RAISE LOG 'Safety scoring trigger failed for route %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER auto_score_route
    AFTER INSERT ON public.routes
    FOR EACH ROW
    EXECUTE FUNCTION trigger_safety_scoring();
