#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
  echo "--> $POSTGRES_USER PostgreSQL is not yet ready. Waiting..."
  sleep 2
done

# Create PostGIS extension in the PostgreSQL database
echo "Creating PostGIS extension in database $POSTGRES_DB..."

psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
EOSQL
# Validate PostGIS installation
echo "Checking if PostGIS is installed correctly..."
POSTGIS_VERSION=$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT PostGIS_Version();")
if [[ -z "$POSTGIS_VERSION" ]]; then
  echo "Error: PostGIS extension is not installed properly."
  exit 1
else
  echo "PostGIS version: $POSTGIS_VERSION"
fi