-- ============================================================
-- 24. Input validation triggers
-- Phase 9: Security Hardening
-- ============================================================

-- ── Phone validation (10-digit Indian format) ──
CREATE OR REPLACE FUNCTION validate_phone()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.phone IS NOT NULL AND NEW.phone !~ '^\+?91?[6-9][0-9]{9}$' THEN
        RAISE EXCEPTION 'Invalid phone number format: must be 10-digit Indian mobile';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_phone
    BEFORE INSERT OR UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION validate_phone();

-- ── Coordinate validation ──
CREATE OR REPLACE FUNCTION validate_coordinates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND (NEW.latitude < -90 OR NEW.latitude > 90) THEN
        RAISE EXCEPTION 'Invalid latitude: must be between -90 and 90';
    END IF;
    IF NEW.longitude IS NOT NULL AND (NEW.longitude < -180 OR NEW.longitude > 180) THEN
        RAISE EXCEPTION 'Invalid longitude: must be between -180 and 180';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_zone_coordinates
    BEFORE INSERT OR UPDATE ON public.unsafe_zones
    FOR EACH ROW EXECUTE FUNCTION validate_coordinates();

-- ── Text length constraints ──
ALTER TABLE public.user_profiles
    ADD CONSTRAINT chk_display_name_len
    CHECK (char_length(display_name) <= 100);

ALTER TABLE public.unsafe_zones
    ADD CONSTRAINT chk_description_len
    CHECK (description IS NULL OR char_length(description) <= 1000);
