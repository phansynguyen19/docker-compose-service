# Gen3 Fence + Arborist - Hướng dẫn Triển khai Tự động

**Tài liệu này hướng dẫn cách triển khai Gen3 Fence và Arborist với HOÀN TOÀN TỰ ĐỘNG hóa.**

Không cần thao tác thủ công! Chỉ cần chạy 2 lệnh:

1. `bash setup.sh` hoặc `.\setup.ps1` - Tạo keys/certs tự động
2. `docker compose up -d` - Khởi động tất cả services (tự động tạo OAuth client)

**Lấy OAuth credentials sau khi services chạy:**

```bash
cat Secrets/oauth_clients/fe_client.json
```

---

## 🆕 Tính năng mới: Username/Password Login với Keycloak

Ngoài Google OAuth, hệ thống giờ đây hỗ trợ **đăng nhập bằng username/password** thông qua Keycloak.

### Quick Setup Keycloak

Sau khi chạy `docker compose up -d`, chạy thêm:

```bash
# Linux/WSL
./scripts/setup_keycloak.sh

# Windows PowerShell
wsl -d Ubuntu -e bash scripts/setup_keycloak.sh
```

### Test Login

- **Keycloak Admin**: http://localhost:8085 (admin/admin123)
- **Test User**: `testuser` / `testpassword`
- **Login URL**: http://localhost/user/login

👉 Xem chi tiết tại [docs/KEYCLOAK_LOGIN.md](docs/KEYCLOAK_LOGIN.md)

---

## 📋 Mục lục

- [Tổng quan](#tổng-quan)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Triển khai tự động (Khuyến nghị)](#triển-khai-tự-động-khuyến-nghị)
- [Cấu hình](#cấu-hình)
- [Sử dụng](#sử-dụng)
- [Kiểm tra và Debug](#kiểm-tra-và-debug)
- [Environment Variables](#environment-variables)
- [Tham khảo](#tham-khảo)

---

## 🔧 Environment Variables

Tất cả các biến cấu hình quan trọng được quản lý trong file `.env`. Khi deploy, chỉ cần chỉnh sửa file này.

### Các biến chính:

| Biến                      | Mô tả                          | Giá trị mặc định                              |
| ------------------------- | ------------------------------ | --------------------------------------------- |
| `BASE_URL`                | URL ngoài của services         | `http://localhost`                            |
| `POSTGRES_USER`           | PostgreSQL username            | `postgres`                                    |
| `POSTGRES_PASSWORD`       | PostgreSQL password            | `postgres`                                    |
| `FENCE_PORT`              | Port expose cho Fence          | `5000`                                        |
| `ARBORIST_PORT`           | Port expose cho Arborist       | `8080`                                        |
| `KEYCLOAK_EXTERNAL_PORT`  | Port expose cho Keycloak       | `8085`                                        |
| `KEYCLOAK_ADMIN_USER`     | Keycloak admin username        | `admin`                                       |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password        | `admin123`                                    |
| `CORS_ALLOWED_ORIGINS`    | CORS origins (comma-separated) | `http://127.0.0.1:3000,http://localhost:3000` |

### Cách sử dụng:

1. Copy file `.env.example` thành `.env` (nếu có)
2. Chỉnh sửa các giá trị theo môi trường deploy
3. Chạy `docker compose up -d`

### Lưu ý quan trọng:

- **nginx.conf**: Sử dụng `$http_origin` để tự động chấp nhận các origin từ localhost/127.0.0.1 với mọi port
- **fence-config.yaml**: Một số giá trị cần chỉnh sửa trực tiếp trong file (xem comments trong file)
- **Keycloak**: Các giá trị `KEYCLOAK_CLIENT_ID`, `KEYCLOAK_CLIENT_SECRET` phải khớp với cấu hình trong `fence-config.yaml`

---

## 🎯 Tổng quan

Dự án này cung cấp môi trường Docker Compose cho **Gen3 Fence** (Authentication/Authorization) và **Arborist** (Policy Management) với:

✅ **Tự động hóa hoàn toàn**:

- Tạo RSA keypairs cho JWT tự động
- Tạo TLS certificates tự động
- Khởi tạo database tự động
- Chạy migrations tự động
- Tạo OAuth client tự động
- Sync users tự động

✅ **Custom Docker images**:

- `phansynguyen19/fence-custom:v1`
- `phansynguyen19/arborist-custom:v1`

✅ **Không cần thao tác thủ công**:

- Không cần vào container để chạy lệnh
- Không cần tạo client credentials thủ công
- Không cần reload user.yaml thủ công

---

## 💻 Yêu cầu hệ thống

### Bắt buộc:

- **Docker**: >= 20.10
- **Docker Compose**: >= 2.0
- **OpenSSL**: >= 1.1
- **Python 3**: >= 3.7

### Khuyến nghị:

- RAM: >= 4GB
- Disk: >= 10GB free space
- OS: Linux, macOS, hoặc Windows với WSL2

### Kiểm tra dependencies:

**Linux/macOS**:

```bash
docker --version
docker compose version
openssl version
python3 --version
```

**Windows PowerShell**:

```powershell
docker --version
docker compose version
openssl version
python --version
```

---

## 🚀 Triển khai tự động (Khuyến nghị)

### Bước 1: Clone hoặc tải repository

```bash
cd /path/to/your/workspace
```

### Bước 2: Chạy script setup

**Linux/macOS/WSL**:

```bash
chmod +x setup.sh
bash setup.sh
```

**Windows PowerShell**:

```powershell
.\setup.ps1
```

Script này sẽ tự động:

- ✅ Tạo RSA keypairs cho Fence JWT
- ✅ Tạo TLS certificates cho HTTPS
- ✅ Generate encryption keys
- ✅ Tạo OAuth client credentials
- ✅ Thiết lập cấu trúc thư mục

**Output mẫu**:

```
=========================================
 Setup Complete!
=========================================

OAuth Client Credentials:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OAuth client 'fe_client' will be AUTO-CREATED when Fence starts.

After 'docker compose up -d', get credentials from:
  cat Secrets/oauth_clients/fe_client.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Bước 3: Khởi động services

```bash
docker compose up -d
```

**Chờ các services khởi động** (khoảng 30-60 giây):

```bash
# Xem logs để theo dõi
docker compose logs -f

# Kiểm tra status
docker compose ps
```

### Bước 4: Lấy OAuth Client Credentials

Sau khi services chạy, credentials sẽ được tự động lưu:

```bash
# Xem credentials
cat Secrets/oauth_clients/fe_client.json
```

**Output mẫu**:

```json
{
  "client_name": "fe_client",
  "client_id": "abc123xyz...",
  "client_secret": "secret456...",
  "redirect_uris": [
    "http://localhost/user/login/google/login/",
    "http://127.0.0.1:3000/callback",
    "http://localhost:3000/callback"
  ],
  "created_at": "2025-11-26T16:06:56+00:00"
}
```

> **⚠️ QUAN TRỌNG:** Lưu lại Client ID và Client Secret!

### Bước 5: Cấu hình Google OAuth (Tùy chọn)

Nếu bạn muốn sử dụng Google Login, chỉnh sửa `fence-config.yaml`:

```yaml
OPENID_CONNECT:
  google:
    discovery_url: 'https://accounts.google.com/.well-known/openid-configuration'
    client_id: 'YOUR_GOOGLE_CLIENT_ID'
    client_secret: 'YOUR_GOOGLE_CLIENT_SECRET'
    redirect_url: 'http://localhost:5000/login/google/login/'
    scope: 'openid email profile'
```

Tạo Google OAuth credentials tại: https://console.cloud.google.com/

### Bước 4: Cấu hình Users (Tùy chọn)

Chỉnh sửa `user_graphql.yaml` để thiết lập quyền truy cập:

```yaml
authz:
  # policies automatically given to anyone, even if they are not authenticated
  anonymous_policies:
    - open_data_reader

  # policies automatically given to authenticated users
  all_users_policies: []

  groups:
    - name: administrators
      policies:
        - services.sheepdog-admin
        - data_upload
        - mds_admin
        - audit_reader
      users:
        - your-email@gmail.com # Thay bằng email của bạn
```

### Bước 5: Khởi động services

```bash
docker compose up -d
```

**Chờ các services khởi động** (khoảng 30-60 giây):

```bash
# Xem logs để theo dõi
docker compose logs -f

# Kiểm tra status
docker compose ps
```

### Bước 6: Xác nhận hoạt động

```bash
# Health check cho Fence
curl http://localhost:5000/_status

# Health check cho Arborist
curl http://localhost:8080/health
```

**Kết quả mong đợi**: Status 200 OK

---

## ⚙️ Cấu hình

### Cấu trúc thư mục

```
docker-compose-service/
├── docker-compose.yml          # Docker Compose configuration
├── fence-config.yaml           # Fence service configuration
├── user_graphql.yaml           # User permissions configuration
├── nginx.conf                  # Nginx reverse proxy config
├── init.sql                    # Database initialization script
├── setup.sh                    # Automated setup (Linux/Mac)
├── setup.ps1                   # Automated setup (Windows)
├── creds_setup.sh             # TLS certificate generator
├── scripts/
│   ├── fence_setup.sh         # Fence initialization script
│   └── arborist_setup.sh      # Arborist initialization script
└── Secrets/                    # Generated credentials (gitignored)
    ├── .fe_client_id          # OAuth Client ID
    ├── .fe_client_secret      # OAuth Client Secret
    ├── .fence_encryption_key  # Fence encryption key
    ├── fenceJwtKeys/          # JWT RSA keypairs
    │   └── {timestamp}/
    │       ├── jwt_private_key.pem
    │       └── jwt_public_key.pem
    └── TLS/                   # SSL/TLS certificates
        ├── ca.pem
        ├── ca-key.pem
        ├── service.crt
        └── service.key
```

### Services Configuration

| Service              | Port    | Description                       |
| -------------------- | ------- | --------------------------------- |
| **fence-service**    | 5000    | Authentication & Authorization    |
| **arborist-service** | 8080    | Policy Management                 |
| **gen3-postgres**    | 5432    | PostgreSQL Database               |
| **revproxy-service** | 80, 443 | Nginx Reverse Proxy               |
| **keycloak**         | 8085    | Identity Provider (Username/Pass) |

### Environment Variables

Tất cả environment variables được thiết lập tự động trong `docker-compose.yml`:

**Fence**:

- `FENCE_CONFIG_PATH`: `/var/www/fence/fence-config.yaml`
- `PGHOST`: `gen3-postgres`
- `PGDATABASE`: `fence_db`

**Arborist**:

- `PGHOST`: `gen3-postgres`
- `PGDATABASE`: `arborist_db`

---

## 📱 Sử dụng

### Truy cập Services

**Fence API**:

```bash
# Status endpoint
curl http://localhost:5000/_status

# Version info
curl http://localhost:5000/_version

# JWKS endpoint (for token validation)
curl http://localhost:5000/.well-known/jwks
```

**Arborist API**:

```bash
# Health check
curl http://localhost:8080/health

# List policies
curl http://localhost:8080/policy
```

### Tích hợp với Frontend

Sử dụng OAuth credentials đã tạo để kết nối frontend:

```javascript
// Example: React/Next.js config
const OAUTH_CONFIG = {
  clientId: 'YOUR_CLIENT_ID_FROM_SETUP', // Từ Secrets/.fe_client_id
  clientSecret: 'YOUR_CLIENT_SECRET_FROM_SETUP', // Từ Secrets/.fe_client_secret
  authorizationEndpoint: 'http://localhost:5000/user/oauth2/authorize',
  tokenEndpoint: 'http://localhost:5000/user/oauth2/token',
  redirectUri: 'http://localhost:3000/callback',
};
```

### Quản lý Users

**Sync users sau khi chỉnh sửa user_graphql.yaml**:

```bash
docker exec fence-service fence-create sync \
  --arborist http://arborist-service:80 \
  --yaml /var/www/fence/user.yaml
```

**Tạo user mới**:

```bash
docker exec -it fence-service bash
fence-create user-create --username user@example.com --email user@example.com
```

---

## 🔍 Kiểm tra và Debug

### Xem Logs

```bash
# Tất cả services
docker compose logs -f

# Chỉ Fence
docker compose logs -f fence-service

# Chỉ Arborist
docker compose logs -f arborist-service

# PostgreSQL
docker compose logs -f gen3-postgres
```

### Kiểm tra Database

```bash
# Truy cập PostgreSQL
docker exec -it gen3-postgres psql -U postgres

# Trong psql shell
\l                          # List databases
\c fence_db                 # Connect to fence_db
\dt                         # List tables
SELECT * FROM users;        # Query users
```

### Kiểm tra OAuth Client

```bash
# Verify client was created
docker exec -it gen3-postgres psql -U postgres -d fence_db -c \
  "SELECT name, client_id FROM client WHERE name='fe_client';"
```

### Common Issues

**Issue 1: Services không start**

```bash
# Check ports không bị conflict
netstat -tuln | grep -E '5000|8080|5432'

# Restart services
docker compose down
docker compose up -d
```

**Issue 2: Database connection errors**

```bash
# Wait for PostgreSQL to be fully ready
docker compose logs gen3-postgres

# Manually run migrations if needed
docker exec fence-service fence-create migrate
```

**Issue 3: OAuth client không được tạo**

```bash
# Check credentials files exist
ls -la Secrets/.fe_client_*

# Manually create client
docker exec -it fence-service bash
fence-create client-create --client fe_client \
  --urls "http://localhost:3000/callback" \
  --username admin_client
```

### Health Check Script

```bash
#!/bin/bash
# health_check.sh

echo "Checking Fence..."
curl -f http://localhost:5000/_status && echo "✓ Fence OK" || echo "✗ Fence FAIL"

echo "Checking Arborist..."
curl -f http://localhost:8080/health && echo "✓ Arborist OK" || echo "✗ Arborist FAIL"

echo "Checking PostgreSQL..."
docker exec gen3-postgres pg_isready && echo "✓ PostgreSQL OK" || echo "✗ PostgreSQL FAIL"
```

---

## 🔄 Update và Maintenance

### Update Docker Images

```bash
# Pull latest custom images
docker pull phansynguyen19/fence-custom:v1
docker pull phansynguyen19/arborist-custom:v1

# Restart services
docker compose down
docker compose up -d
```

### Backup Database

```bash
# Backup all databases
docker exec gen3-postgres pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# Restore from backup
cat backup_20231124.sql | docker exec -i gen3-postgres psql -U postgres
```

### Reset toàn bộ môi trường

```bash
# Stop và xóa containers + volumes
docker compose down -v

# Xóa credentials
rm -rf Secrets/

# Chạy lại setup
bash setup.sh
docker compose up -d
```

---

## 📚 Tham khảo

### Documentation Links

- **Fence Documentation**: https://github.com/uc-cdis/fence
- **Arborist Documentation**: https://github.com/uc-cdis/arborist
- **Gen3 Documentation**: https://gen3.org/
- **Docker Compose Documentation**: https://docs.docker.com/compose/

### Custom Images

- **Fence**: https://hub.docker.com/r/phansynguyen19/fence-custom
- **Arborist**: https://hub.docker.com/r/phansynguyen19/arborist-custom

### API Endpoints Reference

**Fence**:

- `GET /_status` - Service health
- `GET /_version` - Version information
- `GET /.well-known/jwks` - JSON Web Key Set
- `POST /user/oauth2/authorize` - OAuth authorization
- `POST /user/oauth2/token` - Get access token

**Arborist**:

- `GET /health` - Service health
- `GET /policy` - List all policies
- `GET /policy/{path}` - Get specific policy
- `POST /policy` - Create policy
- `GET /user/{username}` - Get user permissions

---

## 💡 Tips và Best Practices

### Security

- ✅ **Không commit** thư mục `Secrets/` vào git
- ✅ **Thay đổi** default passwords trong production
- ✅ **Sử dụng** HTTPS trong production (đã có TLS certificates)
- ✅ **Rotate** JWT keys định kỳ
- ✅ **Backup** database thường xuyên

### Performance

- ⚡ **Tăng** Docker memory limit nếu cần (Settings → Resources)
- ⚡ **Monitor** logs để phát hiện bottlenecks
- ⚡ **Sử dụng** PostgreSQL connection pooling

### Development

- 🔧 **Mount** local code để test changes nhanh
- 🔧 **Sử dụng** `docker compose restart` thay vì `down/up`
- 🔧 **Keep** credentials trong `.env` file (template provided)

---

## 🤝 Support

Nếu gặp vấn đề:

1. Kiểm tra logs: `docker compose logs -f`
2. Xem lại cấu hình trong `fence-config.yaml` và `user_graphql.yaml`
3. Verify credentials trong thư mục `Secrets/`
4. Check health endpoints của services
5. Review Docker Compose status: `docker compose ps`

---

**Last Updated**: November 24, 2025  
**Version**: 1.0 (Automated Setup)
