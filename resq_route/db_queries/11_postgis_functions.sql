-- 11: PostGIS Utility Functions
-- Geospatial functions for nearby zone lookups and route crime analysis.

-- Get unsafe zones within radius of user's position
CREATE OR REPLACE FUNCTION get_nearby_unsafe_zones(
    user_lat FLOAT,
    user_lng FLOAT,
    radius_km FLOAT DEFAULT 5
)
RETURNS TABLE (
    id UUID,
    latitude FLOAT,
    longitude FLOAT,
    radius_meters INTEGER,
    reason TEXT,
    severity TEXT,
    confidence_score FLOAT,
    verified BOOLEAN,
    flag_count INTEGER,
    distance_km FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        uz.id,
        ST_Y(uz.location)::FLOAT AS latitude,
        ST_X(uz.location)::FLOAT AS longitude,
        uz.radius_meters,
        uz.reason,
        uz.severity,
        uz.confidence_score,
        uz.verified,
        uz.flag_count,
        (ST_Distance(
            uz.location::geography,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) / 1000)::FLOAT AS distance_km
    FROM public.unsafe_zones uz
    WHERE ST_DWithin(
        uz.location::geography,
        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
        radius_km * 1000
    )
    AND (uz.verified = TRUE OR uz.flag_count >= 3)
    AND (uz.expires_at IS NULL OR uz.expires_at > NOW())
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql;

-- Get crimes near a route (within buffer distance)
CREATE OR REPLACE FUNCTION get_crimes_near_route(
    route_waypoints JSONB,
    buffer_meters FLOAT DEFAULT 500
)
RETURNS TABLE (
    crime_id UUID,
    crime_type VARCHAR,
    severity TEXT,
    distance_meters FLOAT
) AS $$
DECLARE
    route_line GEOMETRY;
BEGIN
    -- Build a line from waypoints
    SELECT ST_MakeLine(
        ARRAY(
            SELECT ST_SetSRID(
                ST_MakePoint(
                    (point->>'lng')::FLOAT,
                    (point->>'lat')::FLOAT
                ),
                4326
            )
            FROM jsonb_array_elements(route_waypoints) AS point
        )
    ) INTO route_line;

    RETURN QUERY
    SELECT
        cd.id,
        cd.crime_type,
        cd.severity,
        ST_Distance(cd.location::geography, route_line::geography)::FLOAT
    FROM public.crime_data cd
    WHERE ST_DWithin(
        cd.location::geography,
        route_line::geography,
        buffer_meters
    )
    AND cd.occurred_at > NOW() - INTERVAL '1 year'
    ORDER BY ST_Distance(cd.location::geography, route_line::geography);
END;
$$ LANGUAGE plpgsql;
