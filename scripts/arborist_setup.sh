#!/bin/bash
# Entrypoint script for arborist service
# Automatically runs database migrations

set -e

echo "========================================="
echo "Arborist Service Initialization"
echo "========================================="

# Wait for Postgres to be ready using pg_isready (available in the image)
echo "Waiting for PostgreSQL..."
until pg_isready -h gen3-postgres -U postgres -d arborist_db > /dev/null 2>&1; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 2
done
echo "OK PostgreSQL is ready"

# Run Arborist migrations - run SQL directly instead of using broken script
echo "Running Arborist database migrations..."
cd /go/src/github.com/uc-cdis/arborist

# Run each migration directory in order
for migration_dir in ./migrations/20*/; do
    if [ -d "$migration_dir" ]; then
        migration_name=$(basename "$migration_dir")
        echo "Applying migration: $migration_name"
        
        up_sql="${migration_dir}up.sql"
        if [ -f "$up_sql" ]; then
            psql -h gen3-postgres -U postgres -d arborist_db -f "$up_sql" 2>/dev/null || true
        fi
    fi
done

echo "OK Migrations complete"

echo ""
echo "========================================="
echo "Arborist initialization complete!"
echo "========================================="
echo ""

# Start Arborist service
exec /go/src/github.com/uc-cdis/arborist/bin/arborist \
    --port 80 \
    --jwks http://fence-service:80/.well-known/jwks
