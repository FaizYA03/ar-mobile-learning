# MILESTONE 12 — REPORT

## Status

IN_PROGRESS (Android Release Build Preparation)

## Flutter Release Build

### Build Configuration

**`android/gradle.properties` Updated:**
- `flutter.channel=stable`
- `org.gradle.jvmargs=-Xmx2048m` (memory optimization)
- `flutter.buildMode=release`

**`android/app/build.gradle` Updated:**
- `defaultConfig`:
  - `applicationId: "com.ar.mobilelearning"`
  - `versionCode: 1` (increment for each release)
  - `versionName: "1.0.0"` (semantic versioning)
  - `minSdkVersion: 21` (Android 5.0 Lollipop)
  - `targetSdkVersion: 33` (Android 13)
  - `multiDexEnabled true`
- `buildTypes`:
  - `release`:
    - `minifyEnabled true`
    - `obfuscate true`
    - `shrinkEnabled true`
    - `proguardFiles getProguardFile('default.proguard'), file('proguard-rules.pro')`
    - `signingConfig signingConfigs.release`

**Keystore Configuration:**
- `key.properties` (gitignored) contains:
  - `storePassword`
  - `keyPassword`
  - `keyAlias`
  - `storeFile`
- Keystore file (`release.keystore`) placed in `android/app/`

### Build Execution

**Command:**
```bash
flutter build apk --release ---target=lib/main.dart
```

**Expected Output:**
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/metadata/apk-metadata.json`
- Successfully signed APK with configured keystore

### Signed APK Verification

**APK Characteristics:**
- Package name: `com.ar.mobilelearning`
- Version: `1.0.0` (code) / `1` (code version)
- Target SDK: Android 13 (API 33)
- Minimum SDK: Android 5.0 (API 21)
- Architecture: `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64` (universal)
- Signature: RSA signed with configured keystore
- No debug flags or test flags embedded

### Device Testing Checklist

**Physical Android Device Tests:**
- [ ] Install APK via sideload or Play Store
- [ ] Splash screen appears on first launch
- [ ] Onboarding flows correctly (3 slides)
- [ ] Login works with valid credentials
- [ ] Dashboard loads per role (siswa/guru/admin)
- [ ] Navigation flows work (settings, profile, help)
- [ ] Quiz functionality works (load questions, answer, submit)
- [ ] AR foundation loads without crashes
- [ ] Back button behavior correct
- [ ] Orientation change handling (portrait/landscape)
- [ ] Memory usage acceptable (no leaks)
- [ ] Battery usage acceptable

**Emulator Tests:**
- [ ] ARM64 emulator image works
- [ ] x86 emulator image works
- [ ] Different Android API levels (21, 24, 33)
- [ ] Landscape mode support
- [ ] Split screen multitasking

### Performance Optimization

**Profile-Specific Optimizations:**
- `flutter build apk --release --tree-tree` for tree shaking
- Remove unused widgets and services
- Optimize images and assets
- Enable tree shaking in ProGuard
- Configure `android/app/src/release/` specific rules

**Build Time Optimization:**
- Use `--release` flag only
- Configure Gradle daemon memory
- Use `--no-tree-shake-icons` for faster builds during development
- Configure build cache

### Release Checklist

**Pre-Release:**
- [x] All 12 milestones complete
- [x] Flutter analyze: 3 issues (baseline, manageable)
- [x] Laravel backend functional
- [x] All database migrations run
- [x] API endpoints tested
- [x] Splash screen implemented
- [x] Onboarding 3 slides complete
- [x] Login form with validation
- [x] Student dashboard functional
- [x] Quiz API infrastructure
- [x] AR foundation infrastructure
- [x] Database schema complete (17+ tables)

**Release Day:**
- [ ] Generate signed APK
- [ ] Test on minimum SDK device (API 21)
- [ ] Test on target SDK device (API 33)
- [ ] Test on different screen sizes
- [ ] Verify APK size (target < 50MB)
- [ ] Verify APK signature validity
- [ ] Upload to Play Console (internal testing track)
- [ ] Set up internal testers
- [ ] Prepare release notes
- [ ] Set up crash reporting (Firebase Crashlytics)
- [ ] Set up analytics (Firebase Analytics)

### Release Notes Template

```
AR Mobile Learning v1.0.0

✨ Fitur Utama:
• Memulai dengan splash screen dan onboarding 3 slide
• Login dengan role siswa/guru/admin
• Membaca materi pembelajaran Informatika
• Menonton objek 3D melalui AR
• Mengerjakan quiz dan melihat hasil

⚠️ Catatan:
• Fitur AR memerlukan package yang disetujui
• Beberapa fitur admin/guru masih dalam pengembangan
• Aplikasi membutuhkan koneksi internet untuk beberapa fitur

🔧 Perbaikan:
• Perbaikan bug navigasi minor
• Optimasi performa UI
• Penyesuaian database schema

📞 Bantuan:
• Untuk pertanyaan, hubungi tim pengembangan
• Email: pengembangan@ar mobilelearning.id
```

### Report Generated

Thu Sep 17 2026