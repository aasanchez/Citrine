# Use the official PostgreSQL image as the base image
FROM postgres:17

# Install PostGIS and dependencies
RUN apt-get update && apt-get install -y \
    postgis \
    && rm -rf /var/lib/apt/lists/*

# Expose PostgreSQL port
EXPOSE 5432

# Run PostgreSQL on container startup
CMD ["docker-entrypoint.sh", "postgres"]
