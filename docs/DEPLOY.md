# Deploy & CI/CD — AR Mobile Learning

Alur setelah dokumen ini dijalankan:

```
push main → CI (test) → deploy backend otomatis (VPS)
tag v*    → build APK signed → GitHub Release → landing page terupdate
```

## 1. Sewa VPS (syarat auto-deploy)

VPS Ubuntu 22.04, RAM ≥1 GB (IDCloudHost / Niagahoster / dsb, ±Rp50–80rb/bln).
Shared hosting **tidak cocok** (butuh SSH + Composer + cron).

Setup sekali di VPS (sebagai root):

```bash
# PHP 8.2 + ekstensi + composer + mysql + nginx + certbot
apt update && apt install -y software-properties-common
add-apt-repository -y ppa:ondrej/php && apt update
apt install -y php8.2-fpm php8.2-mysql php8.2-mbstring php8.2-xml php8.2-bcmath \
  php8.2-curl php8.2-zip php8.2-gd mysql-server nginx certbot python3-certbot-nginx \
  git unzip composer python3-pip

# Database
mysql -e "CREATE DATABASE ar_mobile_learning CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER 'arml'@'localhost' IDENTIFIED BY 'GANTI_PASSWORD_KUAT';"
mysql -e "GRANT ALL ON ar_mobile_learning.* TO 'arml'@'localhost'; FLUSH PRIVILEGES;"

# User deploy (tanpa password, login via SSH key)
adduser --disabled-password --gecos '' deploy
usermod -aG www-data deploy
mkdir -p /var/www && chown deploy:www-data /var/www

# Clone repo
sudo -u deploy git clone https://github.com/FaizYA03/ar-mobile-learning.git /var/www/ar-mobile-learning
```

`.env` production di `/var/www/ar-mobile-learning/backend/.env`:

```
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.domainmu.id
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=ar_mobile_learning
DB_USERNAME=arml
DB_PASSWORD=GANTI_PASSWORD_KUAT
CORS_ALLOWED_ORIGINS=https://download.domainmu.id
SANCTUM_TOKEN_EXPIRATION=1440
```

Nginx: root ke `backend/public`, `client_max_body_size 100M` (upload GLB),
PHP-FPM 8.2, lalu `certbot --nginx -d api.domainmu.id -d download.domainmu.id`.
Landing page: serve folder `landing/` sebagai site `download.domainmu.id`.
Cron scheduler Laravel: `* * * * * cd /var/www/ar-mobile-learning/backend && php artisan schedule:run >> /dev/null 2>&1`

### Dependensi generator marker ArUco (CMS → Generate Marker)

```bash
pip3 install --break-system-packages opencv-python-headless numpy
python3 /var/www/ar-mobile-learning/backend/scripts/generate_aruco.py --help
```

Tanpa ini, halaman Generate Marker menampilkan peringatan dan menolak generate
(test otomatis skip bila OpenCV tidak ada).

Deploy pertama (manual, sekali saja): copy `.env`, `composer install --no-dev`,
`php artisan key:generate`, `migrate --seed`, `storage:link`,
`config:cache route:cache view:cache`. Setelah itu otomatis via workflow.

## 2. GitHub Secrets (repo Settings → Secrets → Actions)

| Secret | Isi | Cara dapat |
|---|---|---|
| `VPS_HOST` | IP/domain VPS | dari panel provider |
| `VPS_USER` | `deploy` | dibuat di atas |
| `VPS_SSH_KEY` | private key | `ssh-keygen -t ed25519` di laptop → public key ke `~deploy/.ssh/authorized_keys` |
| `VPS_PATH` | `/var/www/ar-mobile-learning` | path clone |
| `PROD_API_URL` | `https://api.domainmu.id/api` | domain API |
| `KEYSTORE_BASE64` | keystore ter-encode | lihat bawah |
| `KEY_ALIAS` / `KEY_PASSWORD` / `STORE_PASSWORD` | kredensial keystore | saat generate |

Generate keystore (sekali, di laptop — JAGA file aslinya, jangan commit):

```powershell
keytool -genkey -v -keystore release.keystore -alias arml -keyalg RSA -keysize 2048 -validity 10000
$bytes = [IO.File]::ReadAllBytes("release.keystore")
[Convert]::ToBase64String($bytes) | Set-Clipboard   # tempel ke KEYSTORE_BASE64
```

`android/app/release.keystore` + `key.properties` sudah gitignored — aman.

## 3. Cara rilis

```bash
# Update biasa (backend/CMS/API): cukup push
git push origin main
# → CI jalan → deploy VPS otomatis (±1 menit) → CMS ikut update

# Rilis APK baru:
# 1. Naikkan version di frontend/pubspec.yaml (mis. 1.1.0+2)
# 2. Tambah AppVersion di CMS (agar notifikasi update di app jalan)
git tag v1.1.0
git push origin v1.1.0
# → APK signed → GitHub Release → landing page otomatis menunjuk versi baru
```

Branch: `main` = production (jangan push coba-coba), `develop` = kerja harian.
