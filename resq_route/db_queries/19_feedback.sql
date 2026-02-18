-- ============================================================
-- 19. Feedback table
-- Phase 7: SRR Reporting Engine — Post-journey feedback
-- ============================================================

CREATE TABLE IF NOT EXISTS public.feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journey_id UUID REFERENCES public.journeys(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    safety_rating INTEGER CHECK (safety_rating BETWEEN 1 AND 5),
    score_accuracy TEXT
        CHECK (score_accuracy IN ('accurate', 'too_safe', 'too_dangerous')),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes ──
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON public.feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_journey_id ON public.feedback(journey_id);

-- ── RLS ──
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own feedback"
    ON public.feedback FOR ALL
    USING (auth.uid() = user_id);

-- ── Zone confidence adjustment trigger ──
CREATE OR REPLACE FUNCTION adjust_zone_confidence()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.score_accuracy = 'too_safe' THEN
        UPDATE unsafe_zones SET confidence_score = LEAST(confidence_score + 0.05, 1.0)
        WHERE ST_DWithin(location::geography,
            (SELECT ST_MakePoint(dest_lng, dest_lat)::geography FROM journeys WHERE id = NEW.journey_id),
            500);
    ELSIF NEW.score_accuracy = 'too_dangerous' THEN
        UPDATE unsafe_zones SET confidence_score = GREATEST(confidence_score - 0.03, 0.1)
        WHERE ST_DWithin(location::geography,
            (SELECT ST_MakePoint(dest_lng, dest_lat)::geography FROM journeys WHERE id = NEW.journey_id),
            500);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER feedback_zone_adjustment
    AFTER INSERT ON public.feedback
    FOR EACH ROW
    EXECUTE FUNCTION adjust_zone_confidence();
