# Quick Start Guide - Gen3 Fence + Arborist

## 🚀 Triển khai trong 2 phút

### Linux/macOS/WSL:

```bash
# 1. Chạy setup (tự động tạo credentials)
bash setup.sh

# 2. Khởi động services
docker compose up -d

# 3. Kiểm tra status
docker compose ps
docker compose logs -f
```

### Windows PowerShell:

```powershell
# 1. Chạy setup (tự động tạo credentials)
.\setup.ps1

# 2. Khởi động services
docker compose up -d

# 3. Kiểm tra status
docker compose ps
docker compose logs -f
```

---

## ✅ Verification

```bash
# Test Fence
curl http://localhost:5000/_status

# Test Arborist
curl http://localhost:8080/health
```

---

## 🔑 OAuth Credentials

Sau khi chạy `setup.sh` hoặc `setup.ps1`, OAuth credentials sẽ được hiển thị:

```
OAuth Client Credentials (SAVE THESE!):
=========================================
Client ID:     abc123...xyz
Client Secret: def456...uvw
=========================================
```

**Credentials cũng được lưu tại**:

- `Secrets/.fe_client_id`
- `Secrets/.fe_client_secret`

---

## 🎯 Sử dụng với Frontend

```javascript
const OAUTH_CONFIG = {
  clientId: 'YOUR_CLIENT_ID', // Từ Secrets/.fe_client_id
  clientSecret: 'YOUR_CLIENT_SECRET', // Từ Secrets/.fe_client_secret
  authorizationEndpoint: 'http://localhost:5000/user/oauth2/authorize',
  tokenEndpoint: 'http://localhost:5000/user/oauth2/token',
  redirectUri: 'http://localhost:3000/callback',
};
```

---

## 📊 Services Overview

| Service    | URL                   | Purpose                        |
| ---------- | --------------------- | ------------------------------ |
| Fence      | http://localhost:5000 | Authentication & Authorization |
| Arborist   | http://localhost:8080 | Policy Management              |
| PostgreSQL | localhost:5432        | Database                       |
| Nginx      | http://localhost      | Reverse Proxy                  |

---

## 🔧 Common Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart single service
docker compose restart fence-service

# Access database
docker exec -it gen3-postgres psql -U postgres

# Sync users after editing user_graphql.yaml
docker exec fence-service fence-create sync \
  --arborist http://arborist-service:80 \
  --yaml /var/www/fence/user.yaml
```

---

## 🐛 Troubleshooting

**Services không start?**

```bash
docker compose logs -f
```

**Database connection error?**

```bash
docker compose restart gen3-postgres
```

**Reset everything?**

```bash
docker compose down -v
rm -rf Secrets/
bash setup.sh
docker compose up -d
```

---

## 📖 Xem thêm

Đọc `README.md` để biết chi tiết đầy đủ về:

- Cấu hình nâng cao
- Google OAuth setup
- User management
- API documentation
- Security best practices

---

**Happy Coding! 🎉**
