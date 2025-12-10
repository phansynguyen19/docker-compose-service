#!/bin/bash
# Keycloak Setup Script - Run this AFTER Keycloak is healthy
# This script creates the gen3 realm, fence-client, and a test user

set -e

# Use environment variables with fallback defaults
# When running in Docker: use container names (keycloak:8080)
# When running locally: use localhost:8085
KEYCLOAK_URL="${KEYCLOAK_URL:-http://127.0.0.1:8085}"
ADMIN_USER="${KEYCLOAK_ADMIN:-admin}"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin123}"
REALM_NAME="${KEYCLOAK_REALM:-gen3}"
CLIENT_ID="${KEYCLOAK_CLIENT_ID:-fence-client}"
CLIENT_SECRET="${KEYCLOAK_CLIENT_SECRET:-fence-client-secret}"
FENCE_REDIRECT_URI="${FENCE_REDIRECT_URI:-http://localhost/user/login/keycloak/login/}"
FRONTEND_REDIRECT_URI="${FRONTEND_REDIRECT_URI:-http://127.0.0.1:3000/callback}"
CORS_ORIGINS="${CORS_ALLOWED_ORIGINS:-http://localhost,http://127.0.0.1:3000}"

echo "=== Keycloak Setup Script ==="
echo ""
echo "Configuration (from environment variables):"
echo "  KEYCLOAK_URL: ${KEYCLOAK_URL}"
echo "  ADMIN_USER: ${ADMIN_USER}"
echo "  REALM_NAME: ${REALM_NAME}"
echo "  CLIENT_ID: ${CLIENT_ID}"
echo "  FENCE_REDIRECT_URI: ${FENCE_REDIRECT_URI}"
echo "  FRONTEND_REDIRECT_URI: ${FRONTEND_REDIRECT_URI}"
echo ""

# Wait for Keycloak to be ready
echo "Checking if Keycloak is ready..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -sf "${KEYCLOAK_URL}/realms/master" > /dev/null 2>&1; then
        echo "Keycloak is ready!"
        break
    fi
    echo "Attempt $attempt/$max_attempts: Keycloak not ready yet, waiting 5 seconds..."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "ERROR: Keycloak did not become ready in time"
    exit 1
fi

# Get admin token
echo ""
echo "Getting admin access token..."
ADMIN_TOKEN=$(curl -sf -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${ADMIN_USER}" \
    -d "password=${ADMIN_PASSWORD}" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')

if [ -z "$ADMIN_TOKEN" ]; then
    echo "ERROR: Failed to get admin token. Check admin credentials."
    exit 1
fi
echo "Got admin token successfully"

# Check if realm exists
echo ""
echo "Checking if realm '${REALM_NAME}' exists..."
REALM_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
echo "Realm check HTTP status: $REALM_CHECK"

if [ "$REALM_CHECK" = "200" ]; then
    echo "Realm '${REALM_NAME}' already exists"
else
    echo "Creating realm '${REALM_NAME}'..."
    CREATE_RESULT=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{
            "realm": "'"${REALM_NAME}"'",
            "enabled": true,
            "registrationAllowed": true,
            "registrationEmailAsUsername": false,
            "loginWithEmailAllowed": true,
            "duplicateEmailsAllowed": false,
            "resetPasswordAllowed": true,
            "editUsernameAllowed": false,
            "bruteForceProtected": true
        }')
    echo "Create realm result: $CREATE_RESULT"
    echo "Realm '${REALM_NAME}' created successfully"
fi

# Check if client exists
echo ""
echo "Checking if client '${CLIENT_ID}' exists..."
EXISTING_CLIENTS=$(curl -s "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients?clientId=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
echo "Existing clients response: $EXISTING_CLIENTS"
CLIENT_COUNT=$(echo "$EXISTING_CLIENTS" | grep -c "${CLIENT_ID}" || echo "0")

if [ "$CLIENT_COUNT" != "0" ] && [ "$CLIENT_COUNT" -gt 0 ] 2>/dev/null; then
    echo "Client '${CLIENT_ID}' already exists"
else
    echo "Creating client '${CLIENT_ID}'..."
    CLIENT_RESULT=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{
            "clientId": "'"${CLIENT_ID}"'",
            "name": "Fence OAuth Client",
            "description": "OAuth client for Gen3 Fence authentication",
            "enabled": true,
            "clientAuthenticatorType": "client-secret",
            "secret": "'"${CLIENT_SECRET}"'",
            "redirectUris": ["'"${FENCE_REDIRECT_URI}"'", "'"${FRONTEND_REDIRECT_URI}"'", "http://localhost/*", "http://127.0.0.1:3000/*"],
            "webOrigins": ["http://localhost", "http://127.0.0.1:3000", "*"],
            "standardFlowEnabled": true,
            "implicitFlowEnabled": false,
            "directAccessGrantsEnabled": true,
            "serviceAccountsEnabled": false,
            "publicClient": false,
            "protocol": "openid-connect",
            "attributes": {
                "post.logout.redirect.uris": "http://localhost/*"
            }
        }')
    echo "Create client result: $CLIENT_RESULT"
    echo "Client '${CLIENT_ID}' created successfully"
fi

# Create test user
echo ""
echo "Checking if test user exists..."
EXISTING_USERS=$(curl -s "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users?username=testuser" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
echo "Existing users response: $EXISTING_USERS"
USER_COUNT=$(echo "$EXISTING_USERS" | grep -c "testuser" || echo "0")

if [ "$USER_COUNT" != "0" ] && [ "$USER_COUNT" -gt 0 ] 2>/dev/null; then
    echo "Test user 'testuser' already exists"
else
    echo "Creating test user 'testuser'..."
    USER_RESULT=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{
            "username": "testuser",
            "email": "testuser@example.com",
            "emailVerified": true,
            "enabled": true,
            "firstName": "Test",
            "lastName": "User",
            "credentials": [{
                "type": "password",
                "value": "testpassword",
                "temporary": false
            }]
        }')
    echo "Create user result: $USER_RESULT"
    echo "Test user 'testuser' created (password: testpassword)"
fi

echo ""
echo "========================================"
echo "=== Keycloak Setup Complete ==="
echo "========================================"
echo ""
echo "Configuration details:"
echo "  Realm: ${REALM_NAME}"
echo "  Client ID: ${CLIENT_ID}"
echo "  Client Secret: ${CLIENT_SECRET}"
echo "  Discovery URL: ${KEYCLOAK_URL}/realms/${REALM_NAME}/.well-known/openid-configuration"
echo ""
echo "Test user credentials:"
echo "  Username: testuser"
echo "  Password: testpassword"
echo ""
echo "Keycloak Admin Console: http://localhost:8085"
echo "  Admin Username: ${ADMIN_USER}"
echo "  Admin Password: ${ADMIN_PASSWORD}"
echo ""
echo "To test the login, visit: http://localhost/user/login"
echo ""
