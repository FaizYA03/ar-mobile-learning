# Draf Bab 3 — Metode Penelitian (R&D + ADDIE)

> **Status:** draf kerangka + isi berbasis bukti nyata pada repo (commit `74573d5`, rilis `v1.0.7`).
>
> **Cara pakai:** bagian yang sudah terisi bersumber dari kode dan dokumen proyek, sehingga dapat
> dipakai langsung. Bagian bertanda `[ ... ]` **harus Anda isi sendiri** dari data penelitian
> yang hanya Anda miliki (hasil wawancara/observasi, jumlah responden, nilai validasi penguji).
> Jangan mengarang angka pada bagian tersebut.
>
> **Peringatan akurasi:** lihat §3.9 — ada klaim pada dokumen milistone lama yang **tidak
> sesuai implementasi**. Jangan mengutip klaim tersebut di skripsi.

---

## 3.1 Metode Penelitian

Penelitian ini menggunakan metode **Research and Development (R&D)** dengan pendekatan
**Pengembangan Sistem Instruksional (*Instructional System Development*, ISD)**.

R&D dipilih karena objek penelitian berupa **produk sistem** — perangkat lunak yang
dibangun untuk memecahkan masalah nyata, bukan phenomena yang hanya dideskripsikan.
Produk 최종 yang dihasilkan adalah aplikasi **AR Mobile Learning**: sistem pembelajaran
Informatika berbasis Augmented Reality untuk siswa SMA/SMK.

Sistem ini terdiri dari tiga komponen bertegrasi:

```
┌──────────────────────────┐        ┌──────────────────────────┐
│   FRONTEND               │  HTTP  │   BACKEND                │
│   Flutter (Android)      │◄──────►│   Laravel 12 REST API    │
│   AR: ARCore + OpenCV     │  JSON  │   + Admin CMS (Blade)    │
└──────────────────────────┘        └───────────┬──────────────┘
                                                │
                                       ┌────────▼────────┐
                                       │  MySQL          │
                                       │  14 tabel       │
                                       └─────────────────┘
```

Alasan pemilihan R&D:

1. Produk akhir berupa sistem kerja yang dapat langsung digunakan sekolah.
2. Ada kebutuhan adaptor AR yang nyata (lihat §3.3.b) sehingga proses pemilihan teknologi
   bukan sekadarFormalitas.
3. Kualitas dapat diverifikasi secara objektif melalui pengujian otomatis dan uji perangkat.

---

## 3.2 Metode Pengembangan: ADDIE

Model pengembangan yang digunakan adalah **ADDIE**, yaitu lima tahap berurutan:

| Tahap | Nama | Fokus | Hasil Utama |
|-------|------|-------|-------------|
| 1 | **Analysis** (Analisis) | Kebutuhan, kendala, pemilihan teknologi | Rumusan kebutuhan & keputusan teknologi |
| 2 | **Design** (Desain) | Arsitektur, basis data, antarmuka, kontrak API |-blueprint sistem |
| 3 | **Development** (Pengembangan) | Penulisan kode | Sistem fungsional |
| 4 | **Implementation** (Implementasi) | Instalasi, konfigurasi, distribusi | Sistem berjalan di perangkat pengguna |
| 5 | **Evaluation** (Evaluasi) | Pengujian & perbaikan | Bukti kelayakan & daftar perbaikan |

> **Catatan sitasi.** ADDIE lazim dikaitkan dengan Molnár & Molnár (1979) dalam konteks
> *computer-based instructional design*, dengan akar pada ISD Branch. Bentuk modern ini
> dipakai dalam Gagné, Wager, Golas & Keller (2005). **Verifikasi kembali ke sumber yang
> Anda kutip** — atribusi model ini berbeda antar-buku teks, jadi jangan memakai rujukan
> ini tanpa diperiksa.

### 3.2.1 Sifat Iteratif ADDIE pada Proyek Ini

ADDIE dalam R&D bukan liniyer satu kali. Proyek ini menjalaninya **tiga siklus penuh**:

```
Siklus 1 (17–22 Sep 2026)   Milestone 1–6  : fondasi → alur siswa → CMS → AR → build
Siklus 2 (23–24 Sep 2026)   Implementasi massal, CMS konten, CI/CD, rilis
Siklus 3 (3 Okt 2026)       Audit keamanan → perbaikan → rilis v1.0.6 & v1.0.7

     ANALYSIS ─► DESIGN ─► DEVELOPMENT ─► IMPLEMENTATION ─► EVALUATION
         ▲                                                            │
         └──────────────────── hasil evaluasi menjadi revisi ◄───────┘
```

### 3.2.2 Bukti Iterasi dalam Repositori

Iterasi tersebut terdokumentasi, bukan klaim. Tiap laporan milistone memuat bagian
`Verification`, `Errors`, `Warnings`, `Known Issues`, dan `Next Milestone` — fungsi-fungsi
**evaluasi formatif**. Contoh konkret: `milestone6_report.md` dan `milestone8_report.md`
keduanya menutup dengan bagian `Next Steps (Pending Package Approval)`, yang menjadi dasar
tahap Developing berikutnya.

---

## 3.3 Tahap 1 — ANALISIS

### 3.3.a Analisis Kebutuhan Fungsional

Kebutuhan diturunkan dari tiga peran pengguna yang ditetapkan pada aturan proyek:

| Peran | Kebutuhan Fungsional | Diterapkan di |
|-------|----------------------|---------------|
| `siswa` | Memilih TP/ATP, membaca materi published, mengerjakan quiz, memindai marker AR | 7 screen siswa |
| `guru` | CRUD TP/ATP, materi, quiz & soal; unggah model 3D & marker; membuat marker ArUco | 4 screen guru |
| `admin` | Kelola pengguna, seluruh konten, branding, versi aplikasi, log aktivitas | 7 screen admin + CMS Blade |

Konten awal diturunkan dari **Kurikulum Informatika Fase E** — terkonfirmasi pada
`backend/database/seeders/DatabaseSeeder.php` (3 TP/ATP, 4 materi, 3 quiz, 6 soal, 24 opsi).

> `[ ... ]` **Isi dari analisis kebutuhan Anda sendiri.** Bila melakukan wawancara,
> observasi kelas, atau survei kebutuhan guru/siswa, sajikan hasilnya di sini
> (jumlah responden, teknik, temuan utama). Tanpa data ini, tahap Analysis tends
> dinilai lemah oleh penguji meskipun kode sudah matang.

### 3.3.b Analisis Pemilihan Teknologi AR

Ini merupakan temuan analisis yang paling substantif dan **sudah terdokumentasi**
dalam `milestone6_report.md` §"AR Package Compliance".

Aturan proyek (`AGENTS.md` §AR RULES) menetapkan bahwa paket AR tidak boleh dipilih
tanpa pemeriksaan kompatibilitas. Analisis inibuilding *compatibility chain*:

```
Flutter 3.27.4 + Dart 3.6.2
      ↓
Android SDK · compileSdk · minSdk · NDK
      ↓
JDK · Gradle · AGP · Kotlin
      ↓
ARPackage
      ↓
ARCore
```

Kandidat yang dievaluasi: `ar_core` dan sejenisnya. Kesimpulan analisis: **bangun
infrastruktur yang *package-agnostic* terlebih dahulu, integrasikan setelah paket
disetujui.** Hasil akhir: **ARCore native** melalui SceneView.

| Aspek | Nilai |
|-------|-------|
| SceneView | `io.github.sceneview:arsceneview:4.32.0` |
| ARCore | `com.google.ar:core:1.54.0` |
| Pendeteksi Alternatif | `dartcv4: ^2.2.2` (`include_modules: [aruco]`) |
| Manifest | `com.google.ar.core` = `optional` (agar tetap jalan di device tanpa ARCore) |

> Catatan: paket `augen` pernah tercatat dalam dokumen lama sebagai pilihan, namun
> **tidak pernah dipakai** dalam implementasi. Coil lah yang benar: SceneView + ARCore.

### 3.3.c Analisis Kebutuhan Non-Fungsional

| Kategori | Kebutuhan | Rencana Solving |
|----------|------------|-----------------|
| Autentikasi | Token-based, aman | Laravel Sanctum + Flutter Secure Storage |
| Otorisasi | 3 tingkat akses | `RoleMiddleware` pada route; register memaksa `role = siswa` |
| Jaringan | Tidak ada `127.0.0.1` di produksi | `--dart-define` + fallback emulator |
| Skor quiz | Server adalah sumber kebenaran | Penskoran iteratif server-side |
| Unggah berkas | Cegah berkas berbahaya | Validasi tipe/ekstensi berlapis |
| AR | Harus pipeline nyata | `AugmentedImageDatabase` → `AugmentedImageNode` (Filament) |

---

## 3.4 Tahap 2 — DESAIN

### 3.4.a Desain Arsitektur

Prinsip yang ditetapkan `AGENTS.md`: pisahkan frontend–backend–database, komunikasi via
REST API, autentikasi berbasis token.

```
frontend/  Flutter 3.47 · Material 3 · 52 file Dart · 20.620 baris
   ├── screens/   (22)  screen peran siswa/guru/admin + AR
   ├── services/  (14)  API, AR, sinkronisasi, penyimpanan aman
   ├── widgets/   (4)   tampilan AR, banner, dialog pengaturan
   ├── config/         ApiConfig (resolusi base URL)
   └── models/         model data

backend/   Laravel 12 · Sanctum · 25 controller · 14 model · 29 migrasi
   ├── Http/Controllers/        (API v0)
   ├── Http/Controllers/Admin/  (CMS Blade, 15 controller)
   ├── Http/Controllers/Api/V1/ (config, konten, resolusi marker)
   ├── Http/Requests/           (8 — validasi request)
   └── Http/Resources/          (8 — serialisasi keluaran)

.github/workflows/  (3)  ci.yml · deploy-backend.yml · release-apk.yml
```

### 3.4.b Desain Basis Data

14 tabel domain (di luar tabel framework Laravel):

| Kelompok | Tabel |
|----------|-------|
| Identitas | `users`, `personal_access_tokens` |
| Kurikulum | `tp_atp`, `materi` |
| Penilaian | `quizzes`, `questions`, `question_options`, `quiz_attempts` |
| AR | `ar_markers`, `ar_models`, `ar_marker_models` *(pivot)*, `ar_hotspots` |
| Sistem | `app_settings`, `app_versions`, `activity_logs` |

Relasi kunci perancangan AR — inilah yang memungkinkan alur *marker → model → hotspot*:

```
ar_markers ──┬── (ar_marker_models) ──┬── ar_models ── ar_hotspots
             │                         │
             └─ marker_id              └─ glb_path, thumbnail_path
                aruco_dictionary
                ar_uco_id
```

Penanda `aruco_dictionary` + `ar_uco_id` memungkinkan identifikasi marker secara **otomatis**
(hasil deteksi ArUco) tanpa input manual — memenuhi aturan §MARKER SYSTEM.

### 3.4.c Desain Pipeline AR

```
Camera
  → deteksi marker          (ARCore AugmentedImageDatabase / OpenCV ArUco)
  → identifikasi marker     (marker_id  |  aruco_dictionary + ar_uco_id)
  → mapping backend         (GET /api/v1/ar/resolve)
  → pemuatan model 3D       (.glb dari cache lokal, fallback URL)
  → render AR               (AugmentedImageNode + Filament)
  → hotspot informasi       (ArHotspotSpeechBubble)
```

### 3.4.d Desain Antarmuka-API

Kontrak respons ditetapkan `AGENTS.md` §API RULES dan diimplementasikan konsisten:

```json
{ "success": true,  "message": "Berhasil …", "data": { } }
{ "success": false, "message": "Validasi gagal",  "errors": { } }
```

Rujukan lengkap tersedia di `docs/API.md` (public, authenticated, guru/admin, AR, CMS,
profile, pagination, filter, error responses).

### 3.4.e Desain Infrastruktur

Rancangan CI/CD dan deploy terdokumentasi di `docs/DEPLOY.md`, mencakup:
persyaratan VPS (PHP 8.2, MySQL, nginx, certbot), daftar GitHub Secrets, serta prosedur rilis.

---

## 3.5 Tahap 3 — DEVELOPMENT

### 3.5.a Ringkasan Output

| Komponen | Jumlah | Keterangan |
|----------|--------|------------|
| Controller backend | 25 | 10 API v0 · 15 CMS Blade |
| Model Eloquent | 14 | 13 domain + `User` |
| Migrasi | 29 | termasuk 1 migrasi nullable `ar_models` |
| Form Request | 8 | validasi input |
| API Resource | 8 | serialisasi keluaran |
| Seeder | 1 | data demo Kurikulum Fase E |
| File Dart | 52 | 20.620 baris kode |
| Screen | 22 | siswa, guru, admin, AR |
| Service | 14 | API, AR, sinkronisasi, keamanan |
| Workflow CI/CD | 3 | CI · deploy backend · rilis APK |

### 3.5.b Pengembangan Modul AR

Tahap ini membangun **dua jalur** AR.

**Jalur A — ARCore 6DoF (utama, nyata).** Berpusat pada 4 file Kotlin di
`frontend/android/app/src/main/kotlin/com/ar/mobilelearning/`:

| Langkah | Bukti Implementasi |
|---------|--------------------|
| Session ARCore | `MainActivity.kt` + pre-flight `ARCoreApk.checkAvailability` |
| Pendaftaran marker | `ArEngineView.kt:234` `AugmentedImageDatabase(session)` |
|          | `:244` `addImage(name, bitmap, widthMeters)` |
|          | `:255` `config.augmentedImageDatabase = database` |
| Render 3D | `ArEngineView.kt:326` `AugmentedImageNode` · `:334` `ModelNode` |
| Komunikasi | `PlatformChannel` (`ar_engine_controller.dart`) |

**Jalur B — OpenCV ArUco (pendeteksi alternatif).** Deteksi genuine dengan
`detectMarkersAsync` di native thread (`ar_uco_service.dart`), termasuk:
reuse detektor antar frame, *fast-path* plane Y, dan disposisi `Mat`/`Vec*`
di blok `finally`.

### 3.5.c Pengembangan Pengujian

Pengujian otomatis dibangun **bersamaan** dengan pengembangan, bukan setelahnya —
ini yang membuat tahap Evaluation kuantitatif.

| Sisi | File test | Test | Baris |
|------|-----------|------|-------|
| Backend | 22 | **148** | — |
| Frontend | 13 | **131** | 1.690 |
| **Total** | 35 | **279** | — |

---

## 3.6 Tahap 4 — IMPLEMENTATION

### 3.6.a Implementasi Server

Backend berhasil diimplementasikan pada server virtual production dan **sudah diverifikasi**:

| Verifikasi | Hasil |
|------------|-------|
| `GET https://api.arlearning.my.id/api/v1/app/config` | `200 OK`, sertifikat TLS valid |
| Skema HTTP (tanpa TLS) | `301` dialihkan ke HTTPS |
| Migrasi | 29 migrasi berjalan di **MariaDB 10.4** |
| Proses otomatis | `deploy-backend.yml` menjalankan `migrate`, cache, dan restart queue |

### 3.6.b Implementasi Perangkat Lunak Mobile

| Aspek | Nilai |
|-------|-------|
| Format | APK (Android), `minSdk 24` (Android 7.0+) |
| Penandatanganan | Signed APK via keystore dari GitHub Secrets |
| Rilis | `v1.0.0` … `v1.0.7` (8 tag) |
| Distribusi | GitHub Release + mirror `download.arlearning.my.id` |
| Auto-start | Scanner AR mulai otomatis, *full-bleed* |

### 3.6.c Implementasi CMS

Admin CMS (Blade + Tailwind) memungkinkan pengelolaan konten **tanpa perlu rilis ulang** —
19 `AppSetting` mencakup branding, splash screen, greetings, pengumuman, bantuan,
dan onboarding.

### 3.6.d Implementasi Case Awal

| Peran | Email | Password |
|-------|-------|----------|
| Admin | `admin@demo.com` | `password` |
| Guru | `guru@demo.com` | `password` |
| Siswa | `siswa@demo.com` | `password` |
| Siswa 2 | `siswa2@demo.com` | `password` |

> **Catatan metodologis:** akun demo di atas **hanya untuk tahap pengembangan dan
> demonstrasi**. Dalam penulisan skripsi, nyatakan bahwa kredensial ini wajib diganti
> pada lingkungan production.

---

## 3.7 Tahap 5 — EVALUATION

### 3.7.a Evaluasi Formatif (Sepanjang Siklus)

Evaluasi formatif dijalankan pada **setiap milistone**, dengan output:

| Elemen | Tujuan |
|--------|--------|
| `Verification` | Konfirmasi perubahan berjalan sesuai harapan |
| `Errors` | Catatan kegagalan yang harus diperbaiki |
| `Warnings` | Potensi masalah lanjutan |
| `Known Issues` | Kendala yang belum selesai |
| `Next Milestone` | Basis rencana iterasi berikutnya |

**Studi kasus — 5 bug dari uji perangkat Android** (periode 21 Sep 2026):

| # | Gejala | Akar Masalah | Solusi |
|---|--------|--------------|--------|
| 1 | Badge "OpenCV NOT loaded" | Status native library tanpa probe nyata | Probe `cv.Mat` + `ArucoDetector` saat inisialisasi |
| 2 | Preview 3D kosong (guru/admin) | WebView `model_viewer_plus` di dalam `AlertDialog` (flaky) | Buka full-screen + normalisasi prefix `storage/` |
| 3 | "Tambah Soal" tanpa umpan balik | 2 `return` senyap tanpa `try/catch` | Validasi + `try/catch` + `SnackBar` |
| 4 | Dashboard guru "0 Materi"/"0 AR" | Nilai `'0'` hardcode di Flutter | Backend mengirim `total_materi` & `total_ar_models` |
| 5 | Dropdown meluber | `DropdownButtonFormField` tanpa `isExpanded` | Tambah `isExpanded: true` |

### 3.7.b Evaluasi Sumatif (Akhir Proyek)

#### (1) Pengujian otomatis

| Sisi | Hasil | Durasi |
|------|-------|--------|
| Backend — SQLite in-memory | **148 passed**, 1 skipped, 683 assertions | ±10 detik |
| Backend — **MariaDB 10.4** | **148 passed** (sama) | ±35 detik |
| Frontend | **131 passed** | ±23 detik |
| `flutter analyze` | **0 issue** | — |
| `dart format` | 0 berkas berubah | — |

> **Kontribusi metodologis:** pengujian backend dijalankan pada **dua mesin basis data**.
> Skema SQLite (yang dipakai CI) dan MariaDB (yang dipakai production) bisa berbeda,
> dan perbedaan seperti kolom `NOT NULL` hanya terlihat pada mesin kedua.

#### (2) Audit perangkat lunak

Audit dilakukan terhadap kode yang sama dan menemukan empat cacat kritis pada
rilis sebelum `v1.0.6`:

| # | Temuan | Dampak | Status |
|---|--------|--------|--------|
| 1 | Skor quiz dapat dimanipulasi klien | Kirim 1 jawaban benar berulang → nilai jauh melebihi 100 | ✅ Diperbaiki |
| 2 | Unggah berkas tanpa validasi tipe | Potensi stored XSS / RCE | ✅ Diperbaiki |
| 3 | Tombol marker-ID manual aktif di rilis | Melanggar aturan main marker sistem | ✅ Diperbaiki |
| 4 | Dokumen bertentangan dengan kode | Klaim teknologi yang tidak sesuai implementasi | ✅ Diperbaiki |

Rekomendasi auditodiarsipkan di `AUDIT_REPORT.md` beserta daftar temuan yang masih
terbuka (tidak ada Policy pada backend, belum ada route guard, dan lainnya).

#### (3) Uji validasi empiris

Salah satu perbaikanGQll underwent validasi empiris sebelum diterapkan. Ditemukan
bahwa aturan `mimes:glb` **akan menolak berkas GLB asli**, karena Laravel memvalidasi
`mimes` berdasarkan hasil deteksi isi berkas (`guessExtension()`), sementara GLB
terdeteksi sebagai `application/octet-stream`. Karena ituydiadecimalama `extensions:`
yang dipakai (memeriksa nama berkas). Matriks uji:

| Berkas | `mimes:glb,gltf` | `extensions:glb,gltf` |
|-------|------------------|----------------------|
| `real_model.glb` (asli) | ❌ ditolak | ✅ diterima |
| `crafted.glb` | ❌ ditolak | ✅ diterima |
| `shell.php` | ❌ ditolak | ❌ ditolak |
| `double.glb.php` | ❌ ditolak | ❌ ditolak |

#### (4) Uji konfigurasi jaringan

Untuk memastikan perbaikan `cleartext` tidak merusak produksi, konfigurasi server
diperiksa langsung:

| Target | Hasil |
|--------|-------|
| `https://api.arlearning.my.id/api/v1/app/config` | `200`, TLS valid |
| `http://api.arlearning.my.id/…` | `301` → HTTPS |

---

## 3.8 Instrumen Pengujian

| Instrumen | Sasaran | Keterangan |
|-----------|---------|------------|
| PHPUnit (Laravel) | API, otorisasi, validasi, query | 22 berkas, 148 test |
| `flutter_test` | Service murni, model, widget | 13 berkas, 131 test |
| Uji perangkat Android | AR, kamera, performa, kompatibilitas | `[ ... ]` jumlah & tipe perangkat |
| Audit kode | Keamanan & kualitas | `AUDIT_REPORT.md` |
| Verifikasi skema | Konsistensi migrasi | SQLite & MariaDB |

> `[ ... ]` **Isi tabel perangkat uji Anda.** Sebutkan jumlah perangkat, merek, versi
> Android, dan ketersediaan ARCore. Data ini memperkuat klaim "AR berfungsi nyata".

---

## 3.9 Catatan Kesesuaian Klaim (Penting untuk Integritas)

Ditemukan selaama audit bahwa **beberapa klaim pada dokumen milistone lama tidak sesuai
dengan implementasi akhir**. Untuk menjaga integritasscientific paper, klaim berikut
**tidak boleh dikutip**:

| Klaim Lama | Status Sebenarnya | Bukti |
|------------|-------------------|-------|
| Tabel `ar_interactions` dan `ar_hotspot_views` | **Pernah tidak dibuat** — tidak ada di migrasi mana pun | `backend/database/migrations/` |
| Berkas `ar_provider.dart` / `ChangeNotifier` | **Pernah tidak ada** — tidak ada di `frontend/lib/`, paket `provider` pun tidak ada di `pubspec.yaml` | — |
| Paket `augen` sebagai mesin AR | **Tidak pernah dipakai** — yang dipakai ARCore + SceneView | `frontend/android/app/build.gradle` |
| `api_v1.php` tidak terdaftar | **Sudah terdaftar** di `bootstrap/app.php:14-18` | — |
| Jumlah test lama (71 backend / 47 frontend) | **Kini 148 backend / 131 frontend** | — |

Semua klaim pada dokumen ini telah diverifikasi ulang terhadap kode pada commit
`74573d5` (rilis `v1.0.7`).

---

## 3.10 Ringkasan Tahapan ADDIE

| Tahap | Aktivitas Inti | Luaran | Status |
|-------|----------------|--------|--------|
| **Analysis** | Identifikasi 3 peran; evaluasi paket AR via *compatibility chain* | Rumusan kebutuhan, keputusan teknologi | ✅ |
| **Design** | Arsitektur, 14 tabel, pipeline AR, kontrak API, rancangan CI/CD | Blueprint + `docs/API.md` + `docs/DEPLOY.md` | ✅ |
| **Development** | 25 controller, 14 model, 52 file Dart, AR native Kotlin | Sistem fungsional + 279 test | ✅ |
| **Implementation** | Deploy VPS, 8 rilis APK, CMS, akun demo | Sistem aktif & terdistribusi | ✅ |
| **Evaluation** | Audit, 279 test, 2 mesin basis data, uji perangkat | 4 cacat kritis diperbaiki | ✅ |

**Kesimpulan:** kelima tahap ADDIE telah dilalui secara iteratif tiga kali. Produk
menghasilkan sistem yang terverifikasi otomatis, terdeploy, dan terdistribusi.

---

## Daftar Gambar & Tabel yang Disarankan

**Gambar:** (1) Diagram blok sistem · (2) Diagram *compatibility chain* AR · (3) Skema
tabel AR · (4) Alur pipeline AR · (5) Screenshot tiaprole · (6) Diagram alur
ADDIE iteratif · (7) Screenshot Admin CMS

**Tabel:** (1) Kebutuhan per peran · (2) Matriks pemilihan AR · (3) Daftar tabel basis data
· (4) Ringkasan endpoint API · (5) Hasil pengujian otomatis · (6) Hasil uji perangkat
· (7) Daftar temuan audit & status perbaikan · (8) Ringkasan tahap ADDIE

---

*Draf ini disusun dari pembacaan kode langsung pada repositori
`FaizYA03/ar-mobile-learning`, commit `74573d5`, rilis `v1.0.7`.*