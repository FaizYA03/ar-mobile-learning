# AR Mobile Learning

Sistem pembelajaran Informatika berbasis Augmented Reality untuk siswa SMA/SMK.

## Arsitektur

```
ar-mobile-learning/
├── backend/            # Laravel 12 REST API + Admin CMS (Blade)
├── frontend/           # Flutter Android app
├── landing/            # Halaman unduh APK (static HTML)
├── docs/               # Dokumentasi API & deploy
└── .github/workflows/  # CI, deploy backend, release APK
```

| Komponen | Teknologi |
|----------|-----------|
| Backend | Laravel 12, PHP 8.2+, MySQL (produksi) / SQLite (dev & test) |
| Auth Backend | Laravel Sanctum (token-based) |
| Otorisasi | `RoleMiddleware` (`admin` / `guru` / `siswa`) |
| Admin CMS | Blade + Tailwind CSS v4, session auth |
| Frontend | Flutter 3.47 (stable), Material 3 |
| State Management | `StatefulWidget` + `setState` |
| Networking | `dio` (API v1) + `package:http` (CRUD & multipart) |
| AR Utama | ARCore — `io.github.sceneview:arsceneview:4.32.0` + `com.google.ar:core:1.54.0` |
| AR Alternatif | OpenCV ArUco via `dartcv4` (deteksi marker + overlay 2D) |
| 3D Viewer | `model_viewer_plus` |
| CI/CD | GitHub Actions (`ci.yml`, `deploy-backend.yml`, `release-apk.yml`) |

> **Catatan arsitektur:** proyek ini **tidak** memakai Riverpod maupun GoRouter.
> State dikelola `setState`, routing memakai `Navigator` + map `routes:` pada `MaterialApp`.
> Lihat `PROJECT_STATUS_REPORT.md` untuk daftar temuan arsitektur yang masih terbuka.

## Role

| Role | Akses |
|------|-------|
| `admin` | Full CRUD, user management, system settings, activity logs, CMS konten UI |
| `guru` | CRUD materi, quiz, AR models/markers/hotspots/mappings |
| `siswa` | Lihat materi published, kerjakan quiz, AR scanner |

Backend adalah sumber kebenaran untuk autentikasi, otorisasi, validasi, dan scoring quiz.

## AR Pipeline

```
Camera → deteksi marker → identitas marker → mapping backend
      → muat model 3D (.glb) → render AR
```

- **ARCore / SceneView** (`ArEngineView.kt`) — `AugmentedImageDatabase` → `AugmentedImageNode` → Filament.
  Marker terdeteksi sebagai `AugmentedImage`, nama marker memakai kolom `marker_id`.
- **OpenCV ArUco** (`ar_uco_service.dart`) — `detectMarkersAsync` di native thread. Identitas marker
  memakai pasangan `aruco_dictionary` + `ar_uco_id`, atau `marker_id`.

Identitas marker **tidak pernah diinput manual** di build release (fitur input manual hanya
tersedia di `kDebugMode`).

## Quick Start

### Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
php artisan serve
```

Akun demo hasil seeder:

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@demo.com` | `password` |
| Guru | `guru@demo.com` | `password` |
| Siswa | `siswa@demo.com` | `password` |
| Siswa 2 | `siswa2@demo.com` | `password` |

> Password demo hanya untuk pengembangan. Ganti sebelum deploy.

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### API Base URL

Diselesaikan berurutan oleh `ApiConfig` (`frontend/lib/config/api_config.dart`):

1. `--dart-define=API_BASE_URL=...` (dipasok CI dari secret `PROD_API_URL`)
2. Override runtime dari **dialog pengaturan server** (disimpan di `SharedPreferences`)
3. Fallback: `10.0.2.2:8000/api` (Android emulator) · `127.0.0.1:8000/api` (web)

| Environment | URL |
|-------------|-----|
| Android Emulator | `http://10.0.2.2:8000/api` |
| Physical Device | `http://<LAPTOP_IP>:8000/api` |
| API v0 | `http://<HOST>:8000/api` |
| API v1 | `http://<HOST>:8000/api/v1` |

Release build memakai **HTTPS** dan `android:usesCleartextTraffic="false"`.
Build debug mengizinkan cleartext lewat `android/app/src/debug/AndroidManifest.xml`.

## Dokumentasi

- [Backend Setup](backend/README.md)
- [Frontend Setup](frontend/README.md)
- [API Reference](docs/API.md)
- [Deploy](docs/DEPLOY.md)
- [Status & Temuan](PROJECT_STATUS_REPORT.md)

## Testing

```bash
# Backend — 148 test (SQLite in-memory, sesuai phpunit.xml)
cd backend && php artisan test

# Frontend — 131 test
cd frontend && flutter test

# Static analysis
cd frontend && flutter analyze
cd backend  && vendor/bin/pint --test app database routes tests
```

> Backend test saat ini berjalan di SQLite. Skema produksi (MySQL) bisa berbeda,
> jadi migrasi baru tetap perlu diverifikasi manual dengan `php artisan migrate` di MySQL.

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
| 15. Final testing & release | In progress (`v1.0.6`) |

Rilis: `git tag v1.1.0 && git push origin v1.1.0` → workflow `release-apk.yml`
build APK signed, mengarsipkan GitHub Release, dan mirror ke server unduhan + `versions.json`.

## License

Private - Tugas Akhir