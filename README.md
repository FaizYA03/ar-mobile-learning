# AR Mobile Learning

Sistem pembelajaran Informatika berbasis Augmented Reality untuk siswa SMA/SMK.

## Arsitektur

```
ar-mobile-learning/
├── backend/          # Laravel 12 REST API + Admin CMS
├── frontend/         # Flutter Android app
└── docs/             # Dokumentasi proyek
```

| Komponen | Teknologi |
|----------|-----------|
| Backend | Laravel 12, PHP 8.2+, MySQL/SQLite |
| Auth Backend | Laravel Sanctum (token-based) |
| Admin CMS | Blade + Tailwind CSS v4 |
| Frontend | Flutter 3.47+, Dart |
| State Management | Riverpod |
| Networking | Dio |
| AR | Augen (marker tracking) |
| 3D Viewer | model_viewer_plus |

## Role

| Role | Akses |
|------|-------|
| `admin` | Full CRUD, user management, system settings, activity logs |
| `guru` | CRUD materi, quiz, AR models/markers/hotspots |
| `siswa` | Lihat materi, kerjakan quiz, AR scanner |

## Quick Start

### Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

Admin default: `admin@admin.com` / `password`

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### API Base URL

| Environment | URL |
|-------------|-----|
| Android Emulator | `http://10.0.2.2:8000/api` |
| Physical Device | `http://<LAPTOP_IP>:8000/api` |
| API v1 | `http://<HOST>:8000/api/v1` |

## Dokumentasi

- [Backend Setup](backend/README.md)
- [Frontend Setup](frontend/README.md)
- [API Reference](docs/API.md)

## Testing

```bash
# Backend (71 tests)
cd backend && php artisan test

# Frontend (47 tests)
cd frontend && flutter test

# Lint check
cd frontend && dart analyze lib/
```

## Project Status

| Phase | Status |
|-------|--------|
| 1. Audit | Done |
| 2. Foundation + Backend + CMS | Done |
| 3. Flutter Auth | Done |
| 4. Materials | Done |
| 5. Quiz System | Done |
| 6-8. AR System | Done |
| 9-11. Integration, Dashboard | Done |
| 12-13. Bug fixes, Code quality | Done |
| 14. Documentation | Done |
| 15. Final testing & release | Pending |

## License

Private - Tugas Akhir
