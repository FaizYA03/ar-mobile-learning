# AR MOBILE LEARNING — PROJECT STATUS REPORT

> **Terakhir diperbarui:** 3 Oktober 2026
> **Versi aplikasi:** `1.0.7+8` (`frontend/pubspec.yaml:19`) · rilis `v1.0.7`
> **Commit terakhir:** `b5310b3` — 28 Sep 2026
> **Stack aktual:** Laravel 12 (backend + Blade CMS) + Flutter 3.47 (Android) + ARCore/SceneView + OpenCV (dartcv4)
> **Database:** SQLite (dev & test) / MySQL (production)

> **Catatan revisi:** laporan sebelumnya (22 Sep 2026) sudah kedaluwarsa dan memuat klaim yang
> tidak sesuai kode. Koreksi penting: **tidak ada package `augen`** (AR memakai ARCore native +
> OpenCV), **`api_v1.php` sudah terdaftar**, dan **Riverpod/GoRouter tidak pernah dipakai**.
> Laporan ini ditulis ulang dari pembacaan kode langsung.

---

## 1. RINGKASAN EKSEKECUTIF

| Komponen | Status | Persentase | Catatan |
|----------|--------|------------|---------|
| Backend REST API | Selesai | ~95% | 26 controller, 8 Form Request, 8 Resource |
| Admin CMS (Blade) | Selesai | ~95% | 15 controller, 7 grup route |
| Database Schema | Selesai | ~95% | 28 migration, 13 model, 1 seeder |
| Frontend UI | Selesai | ~95% | 52 file Dart, 20.616 LOC, 23 screen |
| AR System | Selesai | ~90% | ARCore 6DoF native + ArUco OpenCV |
| Integrasi FE↔BE | Selesai | ~95% | 40+ endpoint, CI/CD terpasang |
| Test & QA | Selesai | ~85% | 133 test backend + 120 test frontend |
| Build & Release | Selesai | ~95% | 3 workflow GitHub Actions, APK rilis |
| **Kualitas & Keamanan** | **Perlu perbaikan** | **~65%** | 4 cacat kritis, lihat §8 |

**Status Keseluruhan: Fungsional & layak demo. Belum layak produksi** karena 4 temuan kritis
(validasi unggah file, integritas skor quiz, tombol marker-ID manual, dokumen tidak sinkron).

---

## 2. UPDATE LOG

### Fase 1–6 — Fondasi, Alur Siswa, CMS Guru/Admin, AR (18–22 Sep 2026)
Sudah lengkap. Ringkasan:

| Fase | Isi | Status |
|------|-----|--------|
| 1 — Data Foundation | Migration + Model + API TP/ATP & Materi | ✅ |
| 2 — Siswa Learning Flow | 7 screen (TP/ATP → Materi → Quiz → AR Hub) | ✅ |
| 3 — Guru Content Management | CRUD TP/ATP + Materi + upload cover | ✅ |
| 4 — Admin Management | 7 tab + User CRUD + Hasil Quiz | ✅ |
| 5 — AR System | Kamera + deteksi marker + muat GLB + hotspot | ✅ |
| 6 — Build Verification | APK debug + web build | ✅ |

> ⚠️ **Koreksi:** entri lama menyebut AR memakai `augen v1.4.2` dan `ar_camera_screen.dart`.
> Keduanya **tidak pernah ada**. Implementasi AR sebenarnya dijelaskan di §5.

### ✅ Fase 6.1 — ArUco Hardening (22 Sep 2026)
- Multi-device: fallback `yuv420` → `bgra8888`; plane Y dipakai langsung (bug `cvtColor` pada Mat 1-channel dihapus); konversi BT.601 manual untuk BGRA
- `detectMarkersAsync` (native thread) → UI isolate tidak terblokir
- `ArucoDetector` + dictionary dibuat sekali; frame-skip 5 + *latest-frame-wins*; dirty-checksum luma
- Helper murni dipisah ke `ar_uco_frame_math.dart` (tanpa import native) → unit-testable
- Test: `ar_uco_service_test.dart`

### ✅ Fase 7 — Backend & Frontend Consolidated (23–24 Sep 2026)
Commit `212261d`, `2866662` — implementasi massal seluruh backend, admin panel, dan frontend.
- Penambahan **P0 security**, **P1** (profil/quiz/paginasi), **P2** (CMS + media)
- **CMS-driven UI content**: branding, splash, greetings, announcement, help, onboarding — 19 `AppSetting`
- **CI/CD + landing page** (`landing/index.html`)
- `server_time` ditambahkan ke app config untuk verifikasi deploy
- Activity log, pagination opt-in, cleanup media orphan (`media:clean-orphans`)

### ✅ Fase 8 — AR & Marker Management (23–24 Sep 2026)
Commit `d24c165`, `9f14dd6`, `b1f8b14`, `09237d6`
- **ArUco identity parity** — `aruco_dictionary` + `ar_uco_id` tersedia di API, CMS, dan app (semua form marker)
- **CMS generator marker ArUco otomatis via OpenCV** (`ArMarkerGenerator` → `scripts/generate_aruco.py`)
- **Pivot sync** `ar_marker_models` pada create/update/destroy mapping + backfill
- **Speech bubble hotspot** di AR scanner
- Scanner auto-start + full-bleed, preview cache-first, CMS clear-cache, startup cepat

### ✅ Fase 9 — Release Hardening (24–28 Sep 2026)
Commit `51a16af`, `2de41d7`, `5cc9d4c`, `3d8f59c`, `6e74bbe`, `b5310b3`
| Commit | Perbaikan |
|--------|-----------|
| `51a16af` | `MainActivity` dipindah ke `com.ar.mobilelearning` — sebelumnya **crash saat launch** (`ClassNotFoundException`) |
| `2de41d7` | Launcher icon custom dari logo CMS (v1.0.2) |
| `5cc9d4c` | Scanner auto-start, full-bleed, cache-first preview, fast startup |
| `3d8f59c` | Fix white-screen saat restart, **global 401 auto-logout**, marker download untuk siswa |
| `6e74bbe` | Free disk runner sebelum release build ( SCP gagal `No space left on device`) |
| `b5310b3` | **Sesi bertahan setelah restart**; pengaturan server dipindah ke admin |

---

## 3. BACKEND (Laravel 12 + Sanctum)

### 3.1 Inventaris

| Komponen | Jumlah | Lokasi |
|----------|--------|--------|
| Model | 13 | `app/Models/` |
| Controller API | 9 | `app/Http/Controllers/` |
| Controller Admin CMS | 15 | `app/Http/Controllers/Admin/` |
| Controller API v1 | 2 | `app/Http/Controllers/Api/V1/` |
| Form Request | 8 | `app/Http/Requests/` |
| API Resource | 8 | `app/Http/Resources/` |
| Middleware | 2 | `CorsMiddleware`, `RoleMiddleware` |
| Service | 2 | `ActivityLogger`, `ArMarkerGenerator` |
| Migration | 28 | `database/migrations/` |
| Seeder | 1 | `DatabaseSeeder.php` |
| Route file | 5 | `api.php`, `api_v1.php`, `admin.php`, `web.php`, `console.php` |
| **Policy / Gate** | **0** | ⚠️ **tidak ada** — lihat §8 |

### 3.2 Models

| Model | Table | Relasi |
|-------|-------|--------|
| `User` | `users` | HasApiTokens, hasMany QuizAttempt |
| `TpAtp` | `tp_atp` | hasMany Materi |
| `Materi` | `materi` | belongsTo TpAtp, belongsTo ArModel, hasOne Quiz |
| `Quiz` | `quizzes` | hasMany Question, hasMany QuizAttempt |
| `Question` | `questions` | belongsTo Quiz, hasMany QuestionOption |
| `QuestionOption` | `question_options` | belongsTo Question |
| `QuizAttempt` | `quiz_attempts` | belongsTo User, belongsTo Quiz |
| `ArModel` | `ar_models` | belongsToMany ArMarker, hasMany ArHotspot |
| `ArMarker` | `ar_markers` | belongsToMany ArModel |
| `ArHotspot` | `ar_hotspots` | belongsTo ArModel |
| `ArMarker3dMapping` | `ar_marker3d_mappings` | belongsTo ArMarker, ArModel |
| `AppSetting` | `app_settings` | — |
| `AppVersion` | `app_versions` | — |
| `ActivityLog` | `activity_logs` | — |

### 3.3 Route API v0 — `routes/api.php`

| Group | Endpoint | Auth |
|-------|----------|------|
| Publik | `POST /api/register`, `POST /api/login` | `throttle:10,1` |
| Publik | `GET /api/ar/public/models`, `/{id}`, `/{id}/markers` | — |
| Sanctum | `POST /api/logout`, `GET /api/user` | Sanctum |
| Sanctum | `PUT /api/user/profile`, `PUT /api/user/password`, `POST /api/user/avatar` | Sanctum |
| Sanctum | `GET /api/dashboard` | Sanctum |
| Sanctum | `GET /api/quizzes`, `/{id}`, `/{id}/attempts`, `POST /{id}/submit` | Sanctum |
| Sanctum | `GET /api/tp-atp`, `/{id}`, `GET /api/materi`, `/{id}` | Sanctum |
| Admin | `GET/POST /api/admin/users`, `PUT/DELETE /api/admin/users/{id}`, `GET /api/admin/quiz-attempts` | `role:admin` |
| Guru/Admin | `GET/POST /api/guru/quizzes`, `PUT/DELETE /api/guru/quizzes/{id}` | `role:guru,admin` |
| Guru/Admin | `POST /api/guru/quizzes/{id}/questions`, `DELETE /api/guru/questions/{id}`, `GET /api/guru/quiz-attempts` | `role:guru,admin` |
| Guru/Admin | `POST/PUT/DELETE /api/guru/tp-atp[/{id}]` | `role:guru,admin` |
| Guru/Admin | `POST/PUT/DELETE /api/guru/materi[/{id}]` (multipart) | `role:guru,admin` |
| Guru/Admin | `POST/PUT/DELETE /api/ar/models`, `/ar/markers`, `/ar/hotspots` | `role:guru,admin` |
| Guru/Admin | `GET/POST/PUT /api/ar/mappings`, `POST /api/ar/markers/{m}/attach`, `DELETE .../detach/{m}` | `role:guru,admin` |

### 3.4 Route API v1 — `routes/api_v1.php`

Terdaftar di `bootstrap/app.php:14-18` dengan prefix `api/v1` + `throttle:60,1`. Dipakai Flutter untuk
cold-start config dan resolusi marker.

| Endpoint | Fungsi |
|----------|--------|
| `GET /api/v1/app/config` | Config app: branding, versi, maintenance, 19 key UI |
| `GET /api/v1/content/version` | Versi konten agregat untuk deteksi sinkronisasi |
| `GET /api/v1/ar/content` | Manifest konten AR (model + marker + thumbnail) |
| `GET /api/v1/ar/resolve` | Resolusi marker → model via `aruco_dictionary` + `ar_uco_id` |
| `GET /api/v1/ar/resolve/marker` | Resolusi via `marker_id` |
| `GET /api/v1/ar/markers` | Daftar marker aktif |

### 3.5 Admin CMS (Blade) — `routes/admin.php`

13 controller, session auth + `role:admin`, prefix `admin`.

| Modul | Rute |
|-------|------|
| Auth | `GET/POST /admin/login`, `POST /admin/logout` |
| Dashboard | `GET /admin/dashboard` |
| Users | `resource users` (except show) |
| TP/ATP | `resource tp-atp` |
| Materi | `resource materi` |
| Quiz | `resource quiz` + `GET/POST /admin/quiz/{q}/questions`, `DELETE .../questions/{q}` |
| Hasil Quiz | `GET /admin/quiz-attempts` |
| AR Models | `resource ar/models` |
| AR Markers | `resource ar/markers` + `GET/POST /admin/ar/markers/generate` (generator ArUco) |
| AR Hotspots | `resource ar/hotspots` + `hotspots-api/*` (CRUD + reorder) |
| AR Mappings | `resource ar/mappings` |
| Activity Logs | `GET /admin/activity-logs` |
| System | `system/settings`, `system/clear-cache`, `system/content/{branding,splash,greetings,announcement,help,onboarding}`, `system/versions` |

### 3.6 Middleware

| Middleware | Fungsi | Status |
|------------|--------|--------|
| `CorsMiddleware` | CORS untuk Flutter web; strip `Allow-Credentials` saat wildcard | ✅ |
| `RoleMiddleware` | Cek role dari `auth()->user()->role` | ✅ |
| Sanctum | Token auth (`personal_access_tokens`) | ✅ |
| `throttle:10,1` | API login/register | ✅ |
| `throttle:60,1` | Seluruh `api/v1` | ✅ |
| **Throttle admin login** | `POST /admin/login` | ❌ **tidak ada** |

### 3.7 Akun Demo (`DatabaseSeeder`)

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@demo.com` | `password` |
| Guru | `guru@demo.com` | `password` |
| Siswa | `siswa@demo.com` | `password` |
| Siswa 2 | `siswa2@demo.com` | `password` |

---

## 4. FRONTEND (Flutter)

**Version:** `1.0.5+6` · **applicationId:** `com.ar.mobilelearning` · **minSdk:** 24

### 4.1 Struktur (52 file Dart, 20.616 LOC)

```
frontend/lib/
├── main.dart                    # Entry + routing statis + theme + init state
├── splash_screen.dart           # Splash + session restore
├── onboarding_screen.dart       # 3 slide
├── login_screen.dart            # Login + dialog pengaturan server
├── register_screen.dart
├── student_dashboard.dart       # 5 tab
├── guru_dashboard.dart          # 5 tab
├── admin_dashboard.dart         # 7 tab
├── config/
│   └── api_config.dart          # Base URL: dart-define > override > fallback
├── core/debug/
│   └── ar_debug_log.dart        # Log ringkas, gated kDebugMode
├── models/
│   └── models.dart              # 697 LOC — semua model
├── screens/                     # 23 file
│   ├── [Siswa] tp_atp, materi_list, materi_detail, quiz_list,
│   │           quiz_take, quiz_result, ar_hub, profile, info
│   ├── [AR]    ar_scanner, ar_uco_scanner, ar_diagnostic, model_viewer
│   ├── [Guru]  guru_tp_atp, guru_materi, guru_ar_management, guru_hasil_quiz
│   └── [Admin] admin_tp_atp, admin_materi, admin_quiz_management,
│               admin_ar_management, admin_hasil_quiz
├── services/                    # 14 file
│   ├── api_client.dart          # Dio + interceptor (401 auto-logout)
│   ├── api_service.dart         # package:http + endpoint CRUD
│   ├── app_config_service.dart  # Config + version check + asset URL
│   ├── content_sync_service.dart# Offline-first sync manifest
│   ├── marker_download_service.dart
│   ├── ar_service.dart          # ARCore availability (MethodChannel)
│   ├── ar_engine_controller.dart# PlatformChannel ke native
│   ├── ar_uco_service.dart      # Pipeline deteksi ArUco (dartcv4)
│   ├── ar_uco_frame_math.dart   # Helper geometri murni (unit-testable)
│   ├── ar_content_resolver.dart # Marker → model
│   ├── ar_camera_projector.dart # Proyeksi 2D untuk overlay
│   ├── ar_diagnostics_service.dart
│   ├── secure_storage_service.dart
│   └── server_config_service.dart
├── tools/
│   └── generate_marker.dart     # ⚠️ dev tool di dalam lib/
└── widgets/                     # 4 file
    ├── ar_engine_view.dart      # AndroidView → SceneView
    ├── ar_hotspot_speech_bubble.dart
    ├── announcement_banner.dart
    └── server_settings_dialog.dart
```

> ⚠️ **Tidak mengikuti struktur `app/ core/ features/ shared/`** yang diwajibkan `AGENTS.md`.
> Semua screen datar di `screens/`, 8 file root, model digabung di satu file 697 LOC.

### 4.2 Dependencies (13 runtime)

| Package | Versi | Fungsi |
|---------|--------|--------|
| `dio` | ^5.7.0 | HTTP client + interceptor (v1 API) |
| `http` | ^1.6.0 | HTTP client (CRUD + multipart) — **duplikat dengan Dio** |
| `flutter_secure_storage` | ^9.2.4 | Token & role |
| `shared_preferences` | ^2.5.3 | Preferensi non-sensitif |
| `camera` | ^0.12.1 | Preview & frame stream ArUco |
| `dartcv4` | ^2.2.2 | OpenCV ArUco (`include_modules: [aruco]`) |
| `model_viewer_plus` | ^1.10.0 | Render GLB |
| `webview_flutter` | ^4.14.1 | Backend model_viewer_plus |
| `permission_handler` | ^12.0.1 | Izin kamera |
| `file_picker` | ^8.0.0 | Pilih file GLB |
| `image_picker` | ^1.1.2 | Pilih gambar cover |
| `path_provider` | ^2.1.5 | Path cache |
| `url_launcher` / `share_plus` | ^6.3.2 / ^12.0.2 | Kontak bantuan / bagikan |

> ⚠️ **Tidak ada `flutter_riverpod` dan tidak ada `go_router`** di `pubspec.yaml`.
> State management memakai `setState`; routing memakai `Navigator` + map `routes:`.
> Ini **bertentangan dengan `AGENTS.md` dan `README.md`** — lihat §8.

### 4.3 Konfigurasi API Base URL (COMPLIANT)

`lib/config/api_config.dart` — urutan resolusi:
1. `API_BASE_URL` dari `--dart-define` (dipasok CI: `secrets.PROD_API_URL`)
2. Override runtime dari `SharedPreferences` (diatur admin lewat dialog pengaturan server)
3. Fallback: `10.0.2.2:8000/api` (Android emulator/iOS) · `127.0.0.1:8000/api` (web)

`127.0.0.1` hanya ada di fallback web — **tidak ada** di jalur request produksi. ✅

---

## 5. AR SYSTEM

Ada **dua** implementasi. Yang dipakai sebagai AR utama adalah **Path A**.

### 5.1 Path A — ARCore + SceneView (AR 6DoF asli) ✅

```
Camera → AugmentedImageDatabase → marker tracking → identitas marker
      → ArContentResolver (API) → muat .glb → AugmentedImageNode + Filament render
```

| Langkah | Implementasi | Bukti |
|---------|--------------|-------|
| Session ARCore | `MainActivity.kt` | availability check `ARCoreApk.checkAvailability` |
| Marker tracking | `ArEngineView.kt:234` `AugmentedImageDatabase(session)`; `:244` `addImage(name, bitmap, widthMeters)`; `:255` `config.augmentedImageDatabase` | ARCore native |
| Identitas marker | `ar_scanner_screen.dart:169-175` bangun `ArEngineMarker` dari `marker_id` | ✅ |
| Mapping API | `ar_scanner_screen.dart:272` → `ArContentResolver.resolveByMarkerId()` | ✅ |
| Muat model 3D | `ar_scanner_screen.dart:178-188` GLB dari cache lokal | ✅ |
| Render 3D | `ArEngineView.kt:326` `AugmentedImageNode`; `:334` `ModelNode` | Filament native |

**Dependency native** (`android/app/build.gradle`):
`io.github.sceneview:arsceneview:4.32.0` · `com.google.ar:core:1.54.0`

**Manifest:** `com.google.ar.core` = **`optional`** (bukan `required`) agar app tetap jalan di
device tanpa ARCore; `camera.ar` feature = `required="false"`.

### 5.2 Path B — OpenCV ArUco (deteksi asli, render 2D) ⚠️

```
Camera → ArUco detectMarkersAsync → dictionary + id → resolveFromApi()
      → GLB → ModelViewer(ar: false) di rect bounding box 2D
```

Deteksi **nyata** dan cukup baik: `detectMarkersAsync` (native thread), detector di-reuse,
fast-path plane Y, `Mat`/`Vec*` di-dispose di `finally`, `ResolutionPreset.low`, frame-skip.

**Kekurangan:** render bukan AR. `ar_camera_projector.dart:105-111` menghitung
`modelWidth = footprint.width * scale` dari **bounding box 2D layar** — tanpa depth, pose,
homography, atau 6DoF. `ar: false` di `ar_uco_scanner_screen.dart:1152`. Data pose
`rvec`/`tvec` yang bisa dihasilkan `detectMarkers` **dibuang**.

### 5.3 Pipeline Wajib (Status)

| FAO `AGENTS.md` | Status | Catatan |
|----------------|--------|---------|
| Camera → marker detection/tracking | ✅ | ARCore `AugmentedImage` + OpenCV ArUco |
| Identifikasi marker | ✅ | `marker_id` / `aruco_dictionary`+`ar_uco_id` |
| Mapping backend | ✅ | `/api/v1/ar/resolve`, `/api/v1/ar/resolve/marker` |
| Muat model 3D | ✅ | GLB dari cache lokal, fallback URL remote |
| Render AR | ✅ (Path A) · ⚠️ (Path B) | Path A 6DoF; Path B billboard 2D |
| **Tanpa input marker ID manual** | ❌ | Tombol manual aktif di release — lihat §8 |

---

## 6. TESTING

| Sisi | File | Test | Status |
|------|------|------|--------|
| Backend | 20 file di `tests/Feature/` | **133 test** | ✅ green |
| Frontend | 12 file di `test/` | **120 test** | ✅ green |

### Backend — cakupan baik
`AuthorizationTest` (role middleware) · `QuizSecurityTest` (`is_correct` tidak bocor ke siswa, reject jawaban lintas quiz) · `MarkerArucoParityTest` + `ArMarkerGenerateTest` (paritas ArUco di 4 jalur tulis) · `MappingPivotSyncTest` (sinkron pivot) · `ProfileTest` (role escalation diabaikan, avatar non-gambar ditolak) · `AdminWebTest` + `AdminClearCacheTest` (guard CMS) · `ActivityLogTest` · `GuruQuizAttemptsTest` (paginasi) · `OrphanMediaTest` · `UiContentTest` · `ApiV1Test` · `TpAtpTest` · `MateriTest`

### Frontend — cakupan baik di area murni
`ar_uco_service_test.dart` (30 test geometri: crop Y-plane, BT.601, mapping rotasi 0/90/180/270, footprint, anchor) · `ar_content_resolver_test.dart` (resolusi marker→model) · `content_sync_test.dart` (manifest & keputusan cache) · `models_test.dart` · `ar_hotspot_test.dart` (widget test clamping) · `app_config_service_test.dart` · `api_client_logout_test.dart` (`shouldAutoLogout`)

### Cakupan belum ada
- Backend: integritas skor quiz, penolakan tipe file, IDOR materi unpublished, unique constraint
- Frontend: `ApiService` & interceptor Dio, `SecureStorageService`, route guard, rantai AR end-to-end
- ⚠️ `content_sync_test.dart:125-220` memuat 5 test tautologis (`expect(15 == 15, true)`) yang **tidak** memanggil `shouldDownloadMarker`
- ⚠️ `widget_test.dart:13` melakukan real network I/O → rawan hang di CI
- ⚠️ CI hanya menjalankan test di **SQLite**; produksi MySQL tidak pernah diuji

---

## 7. BUILD, CI/CD, RELEASE

### 7.1 Workflow

| File | Trigger | Fungsi |
|------|---------|--------|
| `ci.yml` | push/PR ke `main`, `develop` | Backend: `composer install` + `php artisan test`. Frontend: `flutter pub get` + `flutter analyze` + `flutter test` |
| `deploy-backend.yml` | push ke `main` (path `backend/**`, `landing/**`) | Deploy via SSH ke VPS (`appleboy/ssh-action@v1`) |
| `release-apk.yml` | tag `v*` | Build APK release signed → GitHub Release + mirror ke VPS landing + `versions.json` |

**Secrets yang dibutuhkan:** `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_PATH` (deploy) ·
`KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`, `PROD_API_URL` (release)

### 7.2 Rilis

| Item | Nilai |
|------|-------|
| Versi | `1.0.5+6` |
| Metode | `git tag v1.1.0 && git push origin v1.1.0` |
| Output | APK signed (arsip GitHub Release) + unduhan langsung via `landing/index.html` |
| API URL | `--dart-define=API_BASE_URL=${{ secrets.PROD_API_URL }}` |

### 7.3 Build config Android

| Komponen | Nilai |
|----------|-------|
| applicationId | `com.ar.mobilelearning` |
| minSdk | 24 (Android 7.0+) |
| targetSdk / compileSdk | `flutter.targetSdkVersion` / `flutter.compileSdkVersion` |
| NDK | `flutter.ndkVersion` |
| Release signing | Diisi CI dari Secrets (`key.properties`); fallback ke debug signing agar `flutter run --release` lokal tetap jalan |
| Izin | `CAMERA`, `INTERNET` |
| Feature | `camera`, `camera.ar` → `required="false"` |
| FileProvider | `${applicationId}.fileProvider` (untuk `file_picker` GLB) |

---

## 8. KNOWN ISSUES (diverifikasi 3 Oktober 2026)

### 🔴 KRITIS

| # | Temuan | Lokasi | Dampak |
|---|--------|--------|--------|
| K-1 | **Nilai quiz bisa dimanipulasi.** `answers.*.question_id` tanpa `distinct`/`size`; `correctCount` menghitung tiap jawaban yang dikirim tanpa clamp | `QuizSubmitRequest.php:18-20`, `QuizController.php:87-92` | Kirim 1 jawaban benar ×100 pada quiz 3 soal → `score = 3333`, `passed = true`. Melanggar aturan "backend = sumber kebenaran scoring" |
| K-2 | **Unggah file tanpa validasi tipe.** `gambar_cover` = `nullable`; `glb_path` tanpa rule `file:` (string biasa bisa lolos); 4 `image_path` update kehilangan rule `image` | `MateriStoreRequest.php:25`, `MateriUpdateRequest.php:25`, `ArController.php:48,90,236,356`, `Admin/ArModelController.php:38`, `Admin/ArMarkerController.php:139` | Guru bisa unggah `.php`/`.svg` ke disk `public` → stored XSS,aybe RCE |
| K-3 | **Tombol "Marker ID manual" aktif di build release.** Tombol debug di baris berikutnya sudah di-gate `kDebugMode`, tombol ini lupa | `ar_uco_scanner_screen.dart:750-754` (reachable via `ar_hub_screen.dart:265,445`) | Langsung melanggar `AGENTS.md` §AR RULES & §MARKER SYSTEM |
| K-4 | **Dokumen bertentangan dengan kode.** `README.md` menyebut Riverpod, Augen, GoRouter — ketiganya tidak ada. `AGENTS.md` mewajibkan Riverpod + GoRouter | `README.md:18-20,49,99-101` | Penguji yang mencocokkan README dengan `pubspec.yaml` akan menemukan ketidaksesuaian |

### 🟡 TINGGI

| # | Temuan | Lokasi |
|---|--------|--------|
| H-1 | **Tidak ada Policy/Gate sama sekali.** `app/Policies/` tidak ada; otorisasi hanya string match middleware. Guru bisa hapus soal/materi/quiz milik guru lain | `app/Providers/AppServiceProvider.php:20-23` |
| H-2 | **Tidak ada route guard di Flutter.** `MaterialApp` pakai map `routes:` tanpa `redirect`. `pushNamed('/admin')` terbuka tanpa cek role. *Server tetap mengkap — ini masalah UX + defense-in-depth* | `main.dart:184-200` |
| H-3 | **HTTP 403 tidak dibedakan dari 401** → pesan "respons tidak valid (HTTP 403)" untuk kegagalan izin | `api_service.dart:57-82` |
| H-4 | **`usesCleartextTraffic="true"` di manifest utama** (bukan overlay debug). Tidak ada `network_security_config.xml`, tidak ada cert pinning | `AndroidManifest.xml:13` |
| H-5 | **`replaceFirst('/api','')` merusak URL produksi di 9 situs.** `ApiConfig.stripApiSuffix()` sudah benar ada tapi hanya dipakai 2×. `https://api.domain.com/api` → `https:/.domain.com` | `profile_screen.dart:27`, `app_config_service.dart:55`, `ar_content_resolver.dart:135,156`, `model_viewer_screen.dart:307`, `materi_detail_screen.dart:160,352`, `admin_ar_management_screen.dart:66`, `guru_ar_management_screen.dart:65` |
| H-6 | **`TextEditingController` dibuat di dalam `build()`**, tidak di-dispose → alokasi ulang tiap frame deteksi (~30 fps), caret reset | `ar_uco_scanner_screen.dart:1049` |
| H-7 | **`POST /admin/login` tanpa rate limiting** (API login punya `throttle:10,1`) | `routes/admin.php:20` |

### 🟢 SEDANG

| # | Temuan | Lokasi |
|---|--------|--------|
| S-1 | 2 HTTP client (`Dio` + `package:http`) dengan `_token` masing-masing; `main.dart:101-102` harus sync manual | `api_client.dart:8`, `api_service.dart:13` |
| S-2 | `IndexedStack` memicu ≥5 request network di frame pertama dashboard (3 tab punya `initState` fetch) | `student_dashboard.dart:154` |
| S-3 | `setState` tiap frame deteksi AR → rebuild seluruh `Stack` termasuk subtree `ModelViewer` | `ar_uco_scanner_screen.dart:222` |
| S-4 | `questions.text` varchar(255) divalidasi `max:1000` → **HTTP 500** di MySQL strict mode | migration `2026_09_17_051731` vs `QuestionStoreRequest.php:20` |
| S-5 | 21 query di `GET /api/v1/app/config` (1 SELECT per key, tanpa cache) — request pertama tiap cold start | `AppConfigController.php:16-64` |
| S-6 | N+1 di loop scoring + lazy load di hot path scan AR | `QuizController.php:87`, `ArContentController.php:147` |
| S-7 | Uniqueness hanya dijaga PHP, tanpa unique index di DB | `2026_09_17_052941` |
| S-8 | Admin bisa delete/demote akun sendiri atau admin terakhir | `AdminController.php:121` |
| S-9 | Ganti password tidak mencabut token lama | `ProfileController.php:54` |
| S-10 | 895 literal `Color(0x…)`, **252** di antaranya warna brand `0xFF0A8477` yang sama. Tidak ada `app_colors.dart` | seluruh `lib/` |
| S-11 | ~1.800 LOC duplikat: `_buildProfileOption` ×13, `_buildQuickAction` ×12, `_buildBody` ×10. `admin_tp_atp_screen.dart` vs `guru_...` 47% identik | `lib/screens/` |
| S-12 | `ArDiagnosticScreen` (fingerprint perangkat) terbuka untuk siswa | `ar_hub_screen.dart:222` |
| S-13 | Exception mentah ditampilkan ke user dalam UI Indonesia | `ar_uco_scanner_screen.dart:158`, `ar_scanner_screen.dart:215`, `guru_dashboard.dart:328` |
| S-14 | 10 asset marker mati (`marker_0..9.png`) tidak direferensikan; `default_marker.png` hanya **67 byte** (placeholder, tidak bisa jadi target ARCore) | `assets/markers/` |
| S-15 | 2 script dev berada di root backend (`create_placeholders.php`, `fix_paths.php`); `fix_paths.php` menjalankan UPDATE DB tanpa konfirmasi | `backend/` |
| S-16 | Raw model dikembalikan di ~19 endpoint `/api/ar/*` + `TpAtpController`, padahal Resource tersedia | `ArController.php`, `TpAtpController.php` |

---

## 9. PRIORITAS SELANJUTNYA

### P0-1 → P0-3 — SELESAI (rilis `v1.0.6`, 3 Okt 2026)
1. ✅ `QuizSubmitRequest` → `distinct` + `integer` + `max:200`; `QuizController::submit` kini menghitung
   dari soal milik quiz (server-side) + `min(100, ...)`. N+1 ikut hilang (41 → 2 query).
2. ✅ Validasi upload diperketat. **Catatan penting:** `mimes:glb` **ditolak** untuk GLB asli
   (`guessExtension()` → `bin`), jadi dipakai `file|extensions:glb,gltf` — sudah diuji empiris.
3. ✅ Tombol marker-ID manual di-gate `kDebugMode`; panel input manual tak terjangkau di release.
4. ✅ **Bug tambahan ditemukan saat menulis test:** `ar_models.description`/`category` NOT NULL padahal API
   `nullable` → upload GLB tanpa deskripsi = HTTP 500. Diperbaiki migrasi
   `2026_10_03_120000_make_description_and_category_nullable_in_ar_models_table`.
5. ✅ Backend 133 → **148 test** (683 assertions), `flutter analyze` bersih, `flutter test` 120/120.

### P0-4 → P0-6 — SELESAI (rilis `v1.0.7`, 3 Okt 2026)
6. ✅ 9× `replaceFirst('/api','')` → `ApiConfig.baseHost` / `stripApiSuffix()`. Test lama hanya memakai
   `10.0.2.2` (satu-satunya bentuk yang menyembunyikan bug); kini ada `api_config_test.dart` + kasus
   `api.domain.com`. Flutter 120 → **131 test**.
7. ✅ `usesCleartextTraffic` dipindah ke `src/debug`. Produksi diverifikasi memakai HTTPS:
   `https://api.arlearning.my.id` → 200 (sertifikat valid), HTTP → 301 ke HTTPS.
8. ✅ `README.md`, `AGENTS.md`, `frontend/README.md`, `backend/README.md`, `AUDIT_REPORT.md` ditulis
   ulang agar sesuai kode (Riverpod/Augen/GoRouter tidak pernah dipakai; 148 + 131 test).
9. ✅ Migrasi `ar_models` divalidasi di **MariaDB 10.4** dan 148 test backend dijalankan di MySQL
   (sebelumnya hanya SQLite), memakai database scratch terpisah.

### Catatan rilis
- `v1.0.6` masih berjalan saat `v1.0.7`/tag dibuat. Karena `landing/index.html` memakai
  `downloads/versions.json` yang **ditimpa** tiap rilis, job yang selesai **terakhir** menang.
- AppVersion di CMS masih `1.0.4` / build `5` → siswa tidak akan prompted update
  sampai diubah lewat **Admin CMS → System → Versions** ke `1.0.7` / build `8`.

### P0 — Selesai hari ini (~2 jam)
1. Ganti 9× `replaceFirst('/api','')` → `ApiConfig.stripApiSuffix(...)`; tambah test `https://api.domain.com/api`
2. Perbaiki `README.md` (hapus Riverpod/Augen/GoRouter, perbaiki jumlah test) + `AGENTS.md` + tulis ulang `AUDIT_REPORT.md` yang memuat klaim salah
3. Pindahkan `usesCleartextTraffic` ke `src/debug/AndroidManifest.xml`

### P1 — Sprint berikutnya (~1 minggu)
7. `network_security_config.xml` + cert pinning host produksi
8. Gabung `ApiClient` + `ApiService` jadi satu Dio (hapus 2 `_token`)
9. Route guard `/admin` + `/guru`; bedakan 403 vs 401
10. Hoist `TextEditingController` ke State field + `dispose()`
11. Lazy tab di dashboard; `ValueListenableBuilder` + `RepaintBoundary` untuk overlay AR
12. Widen `questions.text` + `question_options.text` ke `text`; tambah test tipe kolom
13. `throttle` pada `POST /admin/login`
14. Auto-resolve marker saat terdeteksi (debounce) + ganti `default_marker.png` dengan placeholder ≥512×512

### P2 — Jangka panjang
15. `app/Policies/` + kolom kepemilikan `created_by` (butuh kerja schema)
16. Ekstrak ~1.800 LOC duplikat + `AppColors` untuk 252 literal
17. Jalankan test backend **juga** di MySQL di CI
18. Pecah `ArController` (500 LOC) dan `models.dart` (697 LOC)
19. Geser struktur ke `app/ core/ features/ shared/` **atau** amend `AGENTS.md` agar tidak bertentangan dengan implementasi
20. Autentikasi password `min:6` → `min:8`

---

## 10. YANG SUDAH BAGUS — JANGAN DIRUSAK

- **Pipeline ARCore asli** (bukan fake): `AugmentedImageDatabase` → `AugmentedImageNode` → Filament, dengan `arsceneview 4.32.0` + ARCore 1.54.0
- **Deteksi ArUco yang matang**: async native thread, detector reuse, fast-path plane Y, disposisi benar di `finally`, unit-tested 30 test
- **`SecureStorageService` benar** — token di secure storage; tidak ada PII/kredensial di SharedPreferences
- **Zero kebocoran log** — 14 `print` semuanya di balik `if (kDebugMode)`; `ArDebugLog` juga gated
- **Konfigurasi API compliant** — `--dart-define` + fallback emulator; tidak ada `127.0.0.1` di jalur produksi
- **Server-side RBAC tetap mengkap** meskipun tidak ada Policy
- **133 test backend** dengan cakupan security yang di luar yang wajar untuk sebuah tugas akhir
- **CI/CD + release APK + landing page** berfungsi
- **19 `AppSetting` CMS-driven** membuat konten UI bisa diubah admin tanpa rilis app

---

*Laporan ini dibuat sebagai referensi pengerjaan selanjutnya, ditulis dari pembacaan kode langsung
pada 3 Oktober 2026 (commit `b5310b3`).*