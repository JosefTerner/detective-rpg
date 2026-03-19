#!/usr/bin/env bash
# Detective RPG — local database initialisation
# Usage: ./scripts/init-db.sh
# Requires: psql, mongosh, curl available on PATH and all containers running.

set -euo pipefail

PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-detective}"
PG_PASSWORD="${PG_PASSWORD:-detective}"

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-detective}"
MONGO_PASSWORD="${MONGO_PASSWORD:-detective}"

ES_HOST="${ES_HOST:-localhost}"
ES_PORT="${ES_PORT:-9200}"

export PGPASSWORD="$PG_PASSWORD"

echo "==> Waiting for PostgreSQL..."
until psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -c '\q' 2>/dev/null; do
  sleep 2
done
echo "    PostgreSQL ready."

echo "==> Creating PostgreSQL databases..."
for db in case_db player_db time_points_db map_db police_db; do
  psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -tc \
    "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1 \
    || psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -c "CREATE DATABASE $db;"
  echo "    $db OK"
done

echo "==> Enabling PostGIS on map_db..."
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d map_db \
  -c "CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS postgis_topology;"
echo "    PostGIS OK"

echo "==> Waiting for MongoDB..."
until mongosh --host "$MONGO_HOST" --port "$MONGO_PORT" \
  -u "$MONGO_USER" -p "$MONGO_PASSWORD" --authenticationDatabase admin \
  --eval "db.adminCommand('ping')" --quiet 2>/dev/null; do
  sleep 2
done
echo "    MongoDB ready."

echo "==> Creating MongoDB collections in police_db..."
mongosh --host "$MONGO_HOST" --port "$MONGO_PORT" \
  -u "$MONGO_USER" -p "$MONGO_PASSWORD" --authenticationDatabase admin \
  --quiet <<'MONGO'
use police_db
db.createCollection("criminal_records")
db.createCollection("coroner_reports")
db.createCollection("security_footage")
db.criminal_records.createIndex({ suspectId: 1 }, { unique: true })
db.criminal_records.createIndex({ surname: 1 })
db.coroner_reports.createIndex({ caseId: 1 })
db.security_footage.createIndex({ locationId: 1, timestamp: 1 })
print("MongoDB collections OK")
MONGO

echo "==> Waiting for Elasticsearch..."
until curl -sf "http://$ES_HOST:$ES_PORT/_cluster/health" \
  | grep -qv '"status":"red"'; do
  sleep 3
done
echo "    Elasticsearch ready."

echo "==> Creating Elasticsearch indexes..."
curl -sf -X PUT "http://$ES_HOST:$ES_PORT/criminal_records" \
  -H 'Content-Type: application/json' -d '{
  "mappings": {
    "properties": {
      "suspectId":   { "type": "keyword" },
      "fullName":    { "type": "text" },
      "aliases":     { "type": "text" },
      "crimeHistory":{ "type": "text" },
      "description": { "type": "text" }
    }
  }
}' && echo "    criminal_records index OK"

curl -sf -X PUT "http://$ES_HOST:$ES_PORT/witness_statements" \
  -H 'Content-Type: application/json' -d '{
  "mappings": {
    "properties": {
      "caseId":     { "type": "keyword" },
      "witnessId":  { "type": "keyword" },
      "statement":  { "type": "text" },
      "recordedAt": { "type": "date" }
    }
  }
}' && echo "    witness_statements index OK"

echo ""
echo "==> Database initialisation complete."
