# Comprehensive automated setup script for Gen3 Fence and Arborist
# Run this script once before starting docker compose

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Gen3 Automated Setup Script" -ForegroundColor Cyan
Write-Host " Fence + Arborist + PostgreSQL" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check dependencies
Write-Host "Checking dependencies..." -ForegroundColor Yellow

$dependencies = @{
    "docker" = "Docker"
    "openssl" = "OpenSSL"
    "python" = "Python3"
}

foreach ($cmd in $dependencies.Keys) {
    try {
        $null = Get-Command $cmd -ErrorAction Stop
        Write-Host "[OK] $($dependencies[$cmd]) found" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] $($dependencies[$cmd]) is required but not installed." -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Create necessary directories
Write-Host "Creating directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "Secrets/fenceJwtKeys" | Out-Null
New-Item -ItemType Directory -Force -Path "Secrets/TLS" | Out-Null
New-Item -ItemType Directory -Force -Path "scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "keys" | Out-Null
Write-Host "[OK] Directories created" -ForegroundColor Green
Write-Host ""

# Generate timestamp for key directory
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Generate RSA keypair for Fence JWT
Write-Host "Generating Fence JWT RSA keys..." -ForegroundColor Yellow
$keyDir = "Secrets/fenceJwtKeys/$timestamp"
New-Item -ItemType Directory -Force -Path $keyDir | Out-Null

openssl genpkey -algorithm RSA -out "$keyDir/jwt_private_key.pem" -pkeyopt rsa_keygen_bits:2048 2>$null
openssl rsa -pubout -in "$keyDir/jwt_private_key.pem" -out "$keyDir/jwt_public_key.pem" 2>$null

Write-Host "[OK] JWT keys generated in $keyDir" -ForegroundColor Green
Write-Host ""

# Generate Fence encryption key
Write-Host "Generating Fence encryption key..." -ForegroundColor Yellow
$encryptionKey = python -c "import secrets; import base64; key = secrets.token_bytes(32); print(base64.urlsafe_b64encode(key).decode())"
$encryptionKey | Out-File -FilePath "Secrets/.fence_encryption_key" -NoNewline -Encoding ASCII
Write-Host "[OK] Encryption key generated" -ForegroundColor Green
Write-Host ""

# Generate OAuth client credentials for frontend
Write-Host "Generating OAuth client credentials for 'fe_client'..." -ForegroundColor Yellow
$clientId = python -c "import secrets; print(secrets.token_urlsafe(32))"
$clientSecret = python -c "import secrets; print(secrets.token_urlsafe(48))"
$clientId | Out-File -FilePath "Secrets/.fe_client_id" -NoNewline -Encoding ASCII
$clientSecret | Out-File -FilePath "Secrets/.fe_client_secret" -NoNewline -Encoding ASCII
Write-Host "[OK] OAuth credentials generated" -ForegroundColor Green
Write-Host ""

# Run TLS certificate generation using WSL bash
Write-Host "Generating TLS certificates..." -ForegroundColor Yellow
try {
    wsl bash -c "cd /mnt/d/docker/docker-compose-service && bash ./creds_setup.sh localhost" 2>$null
    Write-Host "[OK] TLS certificates ready" -ForegroundColor Green
}
catch {
    Write-Host "[WARNING] TLS generation had issues but continuing..." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Review and edit configuration files:"
Write-Host "   - fence-config.yaml: Add your Google OAuth credentials"
Write-Host "   - user_graphql.yaml: Configure user access"
Write-Host ""
Write-Host "2. Start services:"
Write-Host "   docker compose up -d"
Write-Host ""
Write-Host "3. Check service health:"
Write-Host "   docker compose ps"
Write-Host "   docker compose logs -f"
Write-Host ""
Write-Host "OAuth Client Credentials (SAVE THESE!):" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Client ID:     $clientId" -ForegroundColor White
Write-Host "Client Secret: $clientSecret" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "These credentials are also saved in:"
Write-Host "  - Secrets/.fe_client_id"
Write-Host "  - Secrets/.fe_client_secret"
Write-Host ""
Write-Host "After services start, access Fence at:" -ForegroundColor Yellow
Write-Host "   http://localhost:5000"
Write-Host "   https://localhost (via nginx proxy)"
Write-Host ""
