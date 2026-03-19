-- Detective RPG — PostgreSQL database initialization
-- Runs automatically on first postgres container start via docker-entrypoint-initdb.d

-- Per-service databases
CREATE DATABASE case_db;
CREATE DATABASE player_db;
CREATE DATABASE time_points_db;
CREATE DATABASE map_db;
CREATE DATABASE police_db;

-- PostGIS extension for map_db (spatial queries / travel time calculation)
\connect map_db
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
