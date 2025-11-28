#!/bin/bash
# Comprehensive automated setup script for Gen3 Fence and Arborist
# Run this script once before starting docker compose

set -e

echo "========================================="
echo " Gen3 Automated Setup Script"
echo " Fence + Arborist + PostgreSQL"
echo "========================================="
echo ""

# Check dependencies
echo "Checking dependencies..."
command -v docker >/dev/null 2>&1 || { echo "✗ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "✗ OpenSSL is required but not installed. Aborting." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "✗ Python3 is required but not installed. Aborting." >&2; exit 1; }
echo "✓ All dependencies found"
echo ""

# Create necessary directories
echo "Creating directory structure..."
mkdir -p Secrets/fenceJwtKeys
mkdir -p Secrets/TLS
mkdir -p Secrets/oauth_clients
mkdir -p scripts
mkdir -p keys
echo "✓ Directories created"
echo ""

# Generate timestamp for key directory
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H%M%SZ")

# Generate RSA keypair for Fence JWT
echo "Generating Fence JWT RSA keys..."
KEYDIR="Secrets/fenceJwtKeys/${timestamp}"
mkdir -p "$KEYDIR"
openssl genpkey -algorithm RSA -out "$KEYDIR/jwt_private_key.pem" -pkeyopt rsa_keygen_bits:2048 2>/dev/null
openssl rsa -pubout -in "$KEYDIR/jwt_private_key.pem" -out "$KEYDIR/jwt_public_key.pem" 2>/dev/null
chmod -R a+rx Secrets/fenceJwtKeys
echo "✓ JWT keys generated in $KEYDIR"
echo ""

# Create symlink to latest keys for fence to find
echo "Creating symlink to latest keys..."
cd Secrets/fenceJwtKeys
ln -sf "${timestamp}" "latest" 2>/dev/null || true
cd ../..
echo "✓ Symlink created"
echo ""

# Generate Fence encryption key
echo "Generating Fence encryption key..."
ENCRYPTION_KEY=$(python3 -c "import secrets; import base64; key = secrets.token_bytes(32); print(base64.urlsafe_b64encode(key).decode())")
echo "$ENCRYPTION_KEY" > Secrets/.fence_encryption_key
echo "✓ Encryption key generated"
echo ""

# Run TLS certificate generation
echo "Generating TLS certificates..."
bash ./creds_setup.sh localhost 2>/dev/null || {
    echo "⚠ TLS generation had warnings but continuing..."
}
echo "✓ TLS certificates ready"
echo ""

# Make scripts executable
echo "Setting script permissions..."
chmod +x scripts/*.sh 2>/dev/null || true
echo "✓ Scripts are executable"
echo ""

echo "========================================="
echo " Setup Complete!"
echo "========================================="
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Review and edit configuration files:"
echo "   - fence-config.yaml: Add your Google OAuth credentials"
echo "   - user_graphql.yaml: Configure user access"
echo ""
echo "2. Start services:"
echo "   docker compose up -d"
echo ""
echo "3. Check service health:"
echo "   docker compose ps"
echo "   docker compose logs -f"
echo ""
echo "🔑 OAuth Client Credentials:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OAuth client 'fe_client' will be AUTO-CREATED when Fence starts."
echo ""
echo "After 'docker compose up -d', get credentials from:"
echo "  cat Secrets/oauth_clients/fe_client.json"
echo ""
echo "Or check Fence logs:"
echo "  docker compose logs fence-service | grep -A5 'OAuth client'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 After services start, access:"
echo "   Fence:    http://localhost:5000"
echo "   Arborist: http://localhost:8080"
echo "   Proxy:    https://localhost (via nginx)"
echo ""
