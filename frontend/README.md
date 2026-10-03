# Frontend - AR Mobile Learning

Flutter Android app untuk pembelajaran Informatika berbasis AR.

## Requirements

- Flutter 3.47+
- Dart SDK 3.6.2+
- Android SDK (API 24+)
- Physical Android device (untuk AR testing)

## Setup

```bash
flutter pub get
flutter run
```

### API Configuration

JANGAN edit kode untuk ganti server — pakai `--dart-define=API_BASE_URL`:

```bash
# Chrome / web (default http://127.0.0.1:8000/api)
flutter run -d chrome

# Android emulator (default http://10.0.2.2:8000/api)
flutter run

# HP fisik — isi IP LAN laptop (lihat via ipconfig), contoh:
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api

# Release production (HTTPS wajib):
flutter build apk --release --dart-define=API_BASE_URL=https://api.domain.com/api
```

| Environment | URL default | Override |
|-------------|-------------|----------|
| Web/Chrome | `http://127.0.0.1:8000/api` | `--dart-define=API_BASE_URL=...` |
| Android Emulator | `http://10.0.2.2:8000/api` | `--dart-define=API_BASE_URL=...` |
| HP fisik | — (wajib override) | `--dart-define=API_BASE_URL=http://<LAPTOP_LAN_IP>:8000/api` |
| Production | — (wajib override) | `--dart-define=API_BASE_URL=https://<DOMAIN>/api` |

Sumber tunggal: `lib/config/api_config.dart` (dipakai `api_service.dart` + `api_client.dart`).

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                    # Entry point + startup lifecycle
│   ├── splash_screen.dart           # Splash screen
│   ├── onboarding_screen.dart       # Onboarding flow
│   ├── login_screen.dart            # Login
│   ├── register_screen.dart         # Register siswa
│   ├── student_dashboard.dart       # Student home
│   ├── guru_dashboard.dart          # Guru home (quiz + profile)
│   ├── admin_dashboard.dart         # Admin home
│   ├── models/
│   │   └── models.dart              # All data models
│   ├── services/
│   │   ├── api_service.dart         # API methods
│   │   ├── api_client.dart          # Dio HTTP client
│   │   ├── api_config.dart          # Base URL config
│   │   ├── secure_storage_service.dart  # Token storage
│   │   ├── app_config_service.dart  # Startup config
│   │   ├── ar_content_resolver.dart # AR marker/model resolver
│   │   └── content_sync_service.dart    # Content sync
│   ├── screens/
│   │   ├── ar_hub_screen.dart           # AR model catalog
│   │   ├── ar_camera_screen.dart        # AR camera + marker detection
│   │   ├── ar_model_viewer_screen.dart  # 3D model viewer
│   │   ├── materi_list_screen.dart      # Materi browser
│   │   ├── materi_detail_screen.dart    # Materi detail + cover
│   │   ├── quiz_list_screen.dart        # Quiz browser
│   │   ├── quiz_take_screen.dart        # Quiz attempt + timer
│   │   ├── quiz_result_screen.dart      # Score display
│   │   ├── admin_quiz_management_screen.dart  # Admin quiz CRUD
│   │   ├── admin_hasil_quiz_screen.dart       # Quiz attempt results
│   │   ├── guru_tp_atp_screen.dart      # Guru TP/ATP management
│   │   ├── guru_materi_screen.dart      # Guru materi management
│   │   └── guru_ar_management_screen.dart    # Guru AR management
│   └── shared/                       # Shared widgets
├── assets/
│   └── markers/                      # Marker images
├── test/
│   ├── app_config_service_test.dart  # 8 tests
│   ├── ar_content_resolver_test.dart # 11 tests
│   ├── content_sync_test.dart        # 12 tests
│   ├── models_test.dart             # 16 tests
│   └── widget_test.dart             # 1 test (splash)
└── pubspec.yaml
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `dio` | HTTP client (API v1) |
| `http` | HTTP client (CRUD & multipart upload) |
| `flutter_secure_storage` | Secure token storage |
| `shared_preferences` | Local preferences |
| `path_provider` | File paths |
| `model_viewer_plus` | 3D model viewer (GLB) |
| `webview_flutter` | Backend for `model_viewer_plus` |
| `camera` | Kamera + image stream untuk deteksi ArUco |
| `dartcv4` | OpenCV ArUco detection (`include_modules: [aruco]`) |
| `permission_handler` | Izin kamera |
| `image_picker` | Camera/gallery |
| `file_picker` | File selection |
| `url_launcher`, `share_plus` | Kontak bantuan / bagikan |

> AR 3D rendering memakai **ARCore + SceneView native** (`io.github.sceneview:arsceneview:4.32.0`,
> `com.google.ar:core:1.54.0`) lewat `PlatformChannel` — bukan paket `augen`.

## Testing

```bash
flutter test                  # 131 test
flutter analyze               # Static analysis
dart format --set-exit-if-changed .
```

## Key Architecture Decisions

- **Typed Models**: `QuizItem`, `QuizQuestion`, `QuizOption`, `QuizAttemptResult` for quiz system
- **Startup Lifecycle**: App config fetch -> content sync -> AR content resolver
- **Sync Metadata**: Persisted to SharedPreferences (`content_last_sync`, `cached_ar_model_count`)
- **Quiz Timer**: Countdown auto-submit when `time_limit` is set
- **Question Privacy**: `is_correct` hidden from siswa responses (enforced by backend)

## Known Limitations

- AR requires physical Android device with camera
- Cannot build APK on current machine (dart SDK PATH limitation)
- Flutter 3.47 deprecation: `Radio.groupValue`/`onChanged` (info level only)
