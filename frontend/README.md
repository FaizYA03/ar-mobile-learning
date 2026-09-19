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

Update IP address di file berikut sesuai environment:
- `lib/services/api_config.dart` — base URL utama
- `lib/services/api_service.dart` — API endpoint base
- `lib/services/api_client.dart` — Dio instance

| Environment | URL |
|-------------|-----|
| Android Emulator | `http://10.0.2.2:8000/api` |
| Physical Device | `http://<LAPTOP_IP>:8000/api` |

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
| `dio` | HTTP client |
| `flutter_secure_storage` | Secure token storage |
| `shared_preferences` | Local preferences |
| `path_provider` | File paths |
| `model_viewer_plus` | 3D model viewer (GLB) |
| `augen` | AR marker detection/tracking |
| `image_picker` | Camera/gallery |
| `file_picker` | File selection |

## Testing

```bash
flutter test                  # Run all 47 tests
dart analyze lib/             # Lint check
dart format --set-exit-if-changed .  # Format check
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
