#!/bin/bash
# Entrypoint script for fence service
# Automatically runs migrations, creates OAuth client, and syncs users

set -e

echo "========================================="
echo "Fence Service Initialization"
echo "========================================="

# Use environment variables with defaults
POSTGRES_HOST="${PGHOST:-gen3-postgres}"
POSTGRES_PORT="${PGPORT:-5432}"
POSTGRES_USER="${PGUSER:-postgres}"
POSTGRES_PASSWORD="${PGPASSWORD:-postgres}"
FENCE_DB="${PGDATABASE:-fence_db}"
ARBORIST_HOST="${ARBORIST_SERVICE_HOST:-arborist-service}"
CLIENT_NAME="${OAUTH_CLIENT_NAME:-fe_client}"
CLIENT_REDIRECT_URIS="${OAUTH_CLIENT_REDIRECT_URIS:-http://localhost/user/login/google/login/,http://127.0.0.1:3000/callback,http://localhost:3000/callback}"

# Wait for Postgres to be ready using Python (available in fence image)
echo "Waiting for PostgreSQL..."
until python -c "import psycopg2; psycopg2.connect(host='${POSTGRES_HOST}', port=${POSTGRES_PORT}, user='${POSTGRES_USER}', password='${POSTGRES_PASSWORD}', dbname='${FENCE_DB}')" 2>/dev/null; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 2
done
echo "OK PostgreSQL is ready"

# Wait for Arborist to be ready
echo "Waiting for Arborist service..."
until curl -f -s -o /dev/null http://${ARBORIST_HOST}:80/health; do
    echo "Arborist not ready - sleeping"
    sleep 2
done
echo "OK Arborist is ready"

# Run Fence migrations - need to run from /fence directory where alembic.ini is
echo "Running Fence database migrations..."
cd /fence
fence-create migrate
echo "OK Migrations complete"

# Directory to save client credentials (mounted volume)
CREDS_DIR="/var/www/fence/oauth_clients"
mkdir -p "$CREDS_DIR"

# Convert comma-separated URIs to space-separated for fence-create command
IFS=',' read -ra URI_ARRAY <<< "$CLIENT_REDIRECT_URIS"
URI_ARGS=""
for uri in "${URI_ARRAY[@]}"; do
    URI_ARGS="$URI_ARGS \"$uri\""
done

# Create OAuth client automatically
echo "Creating/checking OAuth client '${CLIENT_NAME}'..."

# Check if client already exists in database
CLIENT_EXISTS=$(fence-create client-list 2>/dev/null | grep -c "${CLIENT_NAME}" || echo "0")

if [ "$CLIENT_EXISTS" -gt "0" ]; then
    echo "OAuth client '${CLIENT_NAME}' already exists in database"
    
    # If credentials file doesn't exist, we can't recover the secret
    if [ ! -f "$CREDS_DIR/${CLIENT_NAME}.json" ]; then
        echo "WARNING: Client exists but credentials file not found."
        echo "If you need the secret, delete the client and restart:"
        echo "  docker exec fence-service fence-create client-delete --client ${CLIENT_NAME}"
        echo "  docker compose restart fence-service"
    fi
else
    echo "Creating new OAuth client '${CLIENT_NAME}'..."
    
    # Create new client and capture output
    CLIENT_OUTPUT=$(eval fence-create client-create \
        --client ${CLIENT_NAME} \
        --urls $URI_ARGS \
        --username admin_client \
        --auto-approve \
        --allowed-scopes openid user data google_credentials google_service_account google_link 2>&1) || true
    
    echo "$CLIENT_OUTPUT"
    
    # Extract client_id and client_secret from output
    # The fence-create output format: ('client_id', 'client_secret')
    EXTRACTED_CLIENT_ID=$(echo "$CLIENT_OUTPUT" | grep -oP "\('\K[^']+(?=',)" | head -1)
    EXTRACTED_CLIENT_SECRET=$(echo "$CLIENT_OUTPUT" | grep -oP "', '\K[^']+(?='\))" | head -1)
    
    if [ -n "$EXTRACTED_CLIENT_ID" ] && [ -n "$EXTRACTED_CLIENT_SECRET" ]; then
        # Build redirect URIs JSON array
        REDIRECT_URIS_JSON=""
        for uri in "${URI_ARRAY[@]}"; do
            if [ -n "$REDIRECT_URIS_JSON" ]; then
                REDIRECT_URIS_JSON="$REDIRECT_URIS_JSON,"
            fi
            REDIRECT_URIS_JSON="$REDIRECT_URIS_JSON\n        \"$uri\""
        done
        
        # Save credentials to JSON file
        cat > "$CREDS_DIR/${CLIENT_NAME}.json" << EOF
{
    "client_name": "${CLIENT_NAME}",
    "client_id": "$EXTRACTED_CLIENT_ID",
    "client_secret": "$EXTRACTED_CLIENT_SECRET",
    "redirect_uris": [$(echo -e "$REDIRECT_URIS_JSON")
    ],
    "created_at": "$(date -Iseconds)"
}
EOF
        chmod 600 "$CREDS_DIR/${CLIENT_NAME}.json"
        
        echo ""
        echo "========================================="
        echo "OAuth Client Created Successfully!"
        echo "========================================="
        echo "Client ID:     $EXTRACTED_CLIENT_ID"
        echo "Client Secret: $EXTRACTED_CLIENT_SECRET"
        echo ""
        echo "Credentials saved to: $CREDS_DIR/${CLIENT_NAME}.json"
        echo "========================================="
    else
        echo "WARNING: Could not extract client credentials from output"
        echo "You may need to create the client manually or check logs"
    fi
fi

# Sync users from user.yaml - THIS ALSO SYNCS CLIENT POLICIES TO ARBORIST
if [ -f /var/www/fence/user.yaml ]; then
    echo ""
    echo "Syncing users and clients to Arborist..."
    fence-create sync --arborist http://${ARBORIST_HOST}:80 --yaml /var/www/fence/user.yaml
    echo "OK User and client sync complete"
else
    echo "WARNING: user.yaml not found, skipping user sync"
fi

echo ""
echo "========================================="
echo "Fence initialization complete!"
echo "========================================="
echo ""

# Start Fence service
exec /fence/dockerrun.bash