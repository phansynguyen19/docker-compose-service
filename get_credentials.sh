#!/bin/bash
# Script to get OAuth client credentials

CREDS_FILE="Secrets/oauth_clients/fe_client.json"

if [ -f "$CREDS_FILE" ]; then
    echo "========================================="
    echo " OAuth Client Credentials"
    echo "========================================="
    echo ""
    CLIENT_ID=$(grep -oP '"client_id": "\K[^"]+' "$CREDS_FILE")
    CLIENT_SECRET=$(grep -oP '"client_secret": "\K[^"]+' "$CREDS_FILE")
    echo "Client ID:     $CLIENT_ID"
    echo "Client Secret: $CLIENT_SECRET"
    echo ""
    echo "========================================="
    echo ""
    echo "For frontend .env file:"
    echo "FENCE_CLIENT_ID=$CLIENT_ID"
    echo "FENCE_CLIENT_SECRET=$CLIENT_SECRET"
    echo ""
    echo "To delete after copying (for security):"
    echo "  rm -rf Secrets/oauth_clients/"
else
    echo "Credentials file not found: $CREDS_FILE"
    echo ""
    echo "Check logs for credentials:"
    echo "  docker compose logs fence-service | grep -A3 'client id, client secret'"
    echo ""
    echo "Or query database for client_id (secret is hashed):"
    echo "  docker exec gen3-postgres psql -U postgres -d fence_db -c \"SELECT name, client_id FROM client;\""
fi
