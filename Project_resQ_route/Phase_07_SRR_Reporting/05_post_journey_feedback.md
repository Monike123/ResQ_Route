# 05 — Post-Journey Feedback

## Objective
Collect user feedback after each journey to improve safety scoring accuracy and validate unsafe zone reports.

---

## Feedback Flow

After journey completes, show feedback prompt:

```
┌─────────────────────────────────┐
│  ✅ Journey Complete!            │
│                                 │
│  How safe did you feel?         │
│  ⭐⭐⭐⭐☆  (4/5)                │
│                                 │
│  Was the safety score accurate? │
│  ○ Yes, spot on                 │
│  ○ Route was safer than shown   │
│  ○ Route was less safe          │
│                                 │
│  Any unsafe areas we missed?    │
│  [ Flag an area → ]            │
│                                 │
│  Comments (optional):           │
│  [________________________]     │
│                                 │
│  [ SUBMIT ] [ SKIP ]           │
└─────────────────────────────────┘
```

## Database Schema

```sql
CREATE TABLE public.feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journey_id UUID REFERENCES public.journeys(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    safety_rating INTEGER CHECK (safety_rating BETWEEN 1 AND 5),
    score_accuracy TEXT CHECK (score_accuracy IN ('accurate', 'too_safe', 'too_dangerous')),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own feedback" ON public.feedback FOR ALL USING (auth.uid() = user_id);
```

## Feedback Impact

User feedback feeds back into the safety scoring system:
- **"Route was less safe"** → Increases crime weight for that area
- **"Route was safer"** → Decreases false-positive flag weight
- **Low ratings** on flagged zones → Reduces zone confidence score

```sql
-- Update zone confidence based on feedback
CREATE OR REPLACE FUNCTION adjust_zone_confidence()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.score_accuracy = 'too_safe' THEN
        -- Route was actually less safe → increase nearby zone confidence
        UPDATE unsafe_zones SET confidence_score = LEAST(confidence_score + 0.05, 1.0)
        WHERE ST_DWithin(location::geography, 
            (SELECT destination::geography FROM journeys WHERE id = NEW.journey_id), 
            500);
    ELSIF NEW.score_accuracy = 'too_dangerous' THEN
        -- Route was safer → decrease nearby zone confidence
        UPDATE unsafe_zones SET confidence_score = GREATEST(confidence_score - 0.03, 0.1)
        WHERE ST_DWithin(location::geography,
            (SELECT destination::geography FROM journeys WHERE id = NEW.journey_id),
            500);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER feedback_zone_adjustment
    AFTER INSERT ON public.feedback
    FOR EACH ROW
    EXECUTE FUNCTION adjust_zone_confidence();
```

---

## Verification
- [ ] Feedback prompt shown after journey completion
- [ ] 1-5 star rating collected
- [ ] Score accuracy preference recorded
- [ ] Feedback stored with journey reference
- [ ] Zone confidence adjusted based on feedback
- [ ] Skip option available (no forced feedback)
