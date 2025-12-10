# Keycloak Local Login Setup

This setup adds username/password login to Fence using Keycloak as an Identity Provider.

## Overview

- **Keycloak**: Self-hosted Identity Provider running at `http://localhost:8085`
- **Realm**: `gen3`
- **Test User**: `testuser` / `testpassword`
- **Self-Registration**: Enabled - users can create their own accounts

## Quick Start

After running `docker compose up -d`, execute the Keycloak setup script:

```bash
# On Linux/WSL
chmod +x scripts/setup_keycloak.sh
./scripts/setup_keycloak.sh

# Or from Windows PowerShell with WSL
wsl -d Ubuntu -e bash scripts/setup_keycloak.sh
```

## Login Options

After setup, Fence provides two login options:

1. **Login with Google** - OAuth2 via Google
2. **Login with Username/Password** - Local login via Keycloak

### Test Login Flow

1. Open browser: `http://localhost/user/login`
2. You'll see both login options available
3. Click "Login with Username/Password" (Keycloak)
4. Login with:
   - Username: `testuser`
   - Password: `testpassword`

## Self-Registration

Users can create their own accounts:

### From Fence Login Page

1. Go to `http://localhost/user/login`
2. Click "Login with Username/Password"
3. On Keycloak login page, click "Register"
4. Fill in the registration form
5. After registration, login with new credentials

### Direct Registration URL

```
http://localhost:8085/realms/gen3/protocol/openid-connect/auth?client_id=fence-client&response_type=code&scope=openid&redirect_uri=http://localhost/user/login/keycloak/login/&kc_action=register
```

### From Frontend Application

The frontend at `http://127.0.0.1:3000` has a "Create New Account" button that redirects to Keycloak registration.

## Frontend Integration (backoffice-frontend)

The frontend application has been updated to support both Google and Keycloak login:

### Environment Variables (.env.local)

```bash
NEXT_PUBLIC_FENCE_URL=http://localhost/user
NEXT_PUBLIC_ARBORIST_URL=http://localhost/authz
NEXT_PUBLIC_CLIENT_ID=<your-fence-client-id>
NEXT_PUBLIC_REDIRECT_URI=http://127.0.0.1:3000/callback
NEXT_PUBLIC_SCOPES=openid user
NEXT_PUBLIC_IDP=google

# Keycloak Configuration
NEXT_PUBLIC_KEYCLOAK_URL=http://localhost:8085
NEXT_PUBLIC_KEYCLOAK_REALM=gen3
```

### Login Page Features

The login page (`/login`) now shows:

- **Sign in with Google** - OAuth2 via Google
- **Sign in with Username/Password** - Local login via Keycloak
- **Create New Account** - Self-registration via Keycloak

### Registration Flow

1. User clicks "Create New Account"
2. Redirected to Keycloak registration form
3. User fills in username, email, password
4. After registration, redirected back to Fence
5. Fence completes OAuth flow (may need to login again)

## Keycloak Admin Console

Access the admin console to manage users:

- **URL**: http://localhost:8085
- **Admin Username**: `admin`
- **Admin Password**: `admin123`

### Create New Users (Admin)

1. Go to http://localhost:8085
2. Login with admin credentials
3. Select realm "gen3"
4. Go to "Users" → "Add user"
5. Fill in username, email, etc.
6. Go to "Credentials" tab
7. Set password (disable "Temporary")

## Configuration Details

### Keycloak Client Settings

| Setting       | Value                                                                    |
| ------------- | ------------------------------------------------------------------------ |
| Client ID     | `fence-client`                                                           |
| Client Secret | `fence-client-secret`                                                    |
| Redirect URIs | `http://localhost/user/login/keycloak/login/`, `http://127.0.0.1:3000/*` |
| Grant Types   | Authorization Code                                                       |
| Registration  | Enabled                                                                  |

### Fence Configuration

The Keycloak provider is configured in `fence-config.yaml`:

```yaml
OPENID_CONNECT:
  keycloak:
    name: 'Local Login'
    discovery:
      authorization_endpoint: 'http://localhost:8085/realms/gen3/protocol/openid-connect/auth'
      token_endpoint: 'http://keycloak:8080/realms/gen3/protocol/openid-connect/token'
      jwks_uri: 'http://keycloak:8080/realms/gen3/protocol/openid-connect/certs'
      userinfo_endpoint: 'http://keycloak:8080/realms/gen3/protocol/openid-connect/userinfo'
    client_id: 'fence-client'
    client_secret: 'fence-client-secret'
    redirect_url: '{{BASE_URL}}/login/keycloak/login/'
    scope: 'openid email profile'
    user_id_field: 'preferred_username'
    email_field: 'email'
    enable_idp_users_registration: true
```

## Network Architecture

```
Browser → Keycloak (localhost:8085) → Fence (localhost/user) ← Keycloak (internal: keycloak:8080)
```

- Browser accesses Keycloak via `localhost:8085`
- Fence talks to Keycloak internally via `keycloak:8080` (Docker network)
- This is why we use `discovery` block instead of `discovery_url`

## Troubleshooting

### "Invalid redirect" error

Make sure the redirect URL is whitelisted:

- In Keycloak admin: Clients → fence-client → Valid redirect URIs
- Should include: `http://localhost/*`, `http://127.0.0.1:3000/*`

### Cannot connect to Keycloak

1. Check if Keycloak is running: `docker ps | grep keycloak`
2. Check logs: `docker logs keycloak`
3. Wait ~60 seconds after startup for Keycloak to be ready

### Login callback fails

Check Fence logs:

```bash
docker logs fence-service 2>&1 | tail -50
```

### Reset Keycloak

To completely reset Keycloak:

```bash
docker compose down -v
docker compose up -d
./scripts/setup_keycloak.sh
```

### Update Keycloak Client (after setup)

If you need to add more redirect URIs after initial setup:

1. Go to Keycloak Admin Console → Clients → fence-client
2. Add new URIs to "Valid redirect URIs"
3. Save changes
