CREATE EXTENSION IF NOT EXISTS postgis;

/*CREATE DATABASE IF NOT EXISTS betterroute;*/


CREATE TABLE IF NOT EXISTS merchants (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL DEFAULT '',
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS merchants_location_gix ON merchants USING GIST(location);

INSERT INTO merchants (name, address, location) VALUES
('Better Coffee', 'Jakarta', ST_SetSRID(ST_MakePoint(106.827153, -6.175392),4326)::geography),
('Better Mart', 'Bandung', ST_SetSRID(ST_MakePoint(107.619123, -6.917464),4326)::geography),
('Better Store', 'Depok', ST_SetSRID(ST_MakePoint(106.794200, -6.402500),4326)::geography)
ON CONFLICT DO NOTHING;
