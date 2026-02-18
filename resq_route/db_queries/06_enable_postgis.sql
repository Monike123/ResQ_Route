-- 06: Enable PostGIS Extension
-- Run this FIRST before any geospatial tables.
-- Go to Supabase Dashboard → Database → Extensions → Enable "postgis"
-- OR run this query in the SQL editor:

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
