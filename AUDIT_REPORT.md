# AR Mobile Learning — AUDIT REPORT

> **Audit terakhir:** 3 Oktober 2026 (commit `5d2d3b5`, rilis `v1.0.6`)
> **Metode:** pembacaan kode langsung + uji empiris terhadap validasi Laravel
> **Tidak ada file yang diubah tanpa persetujuan pengguna**

---

## 0. Catatan tentang laporan sebelumnya

Laporan bertanggal 20 September 2026 (versi sebelumnya dari file ini) memuat beberapa klaim
yang **tidak sesuai dengan kode**. Klaim berikut terbukti salah:

| Klaim lama | Kenyataan |
|---|---|
| `api_v1.php` route tidak terdaftar | **Terdaftar** di `bootstrap/app.php:14-18` (prefix `api/v1`, `throttle:60,1`) |
| `augen` hilang → AR tidak bisa jalan | **`augen` memang tidak pernah dipakai.** AR berjalan lewat ARCore + SceneView native: `arsceneview:4.32.0` + `com.google.ar:core:1.54.0`, dengan 4 file Kotlin di `android/app/src/main/kotlin/com/ar/mobilelearning/` |
| Native AR engine tidak ada | **Ada**: `MainActivity.kt`, `ArEngineView.kt`, `ArEngineViewFactory.kt`, `FlutterArPermissions.kt` |
| Riverpod ada di `pubspec.yaml` tapi tidak dipakai | **Riverpod tidak ada di `pubspec.yaml`** sama sekali |
| API URL hardcoded `10.42.37.181` | Tidak ada. Konfigurasi via `--dart-define` + fallback emulator |
| 0 backend Feature test | **133** test di 20 file (kini 148 setelah perbaikan ini) |
| 5 test file frontend / ~47 test | 12 file / 120 test (kini 13 file / 131 test) |

 Kesimpulan: laporan lama harus dianggap tidak valid.Laporan ini menggantikannya.

---

## 1. Ringkasan

| Aspek | Nilai |
|-------|-------|
| Kualitas arsitektur | Baik — backend/frontend terpisah bersih, AR nyata, test kuat |
| Keamanan | **Perlu perbaikan** — sudah banyak yang diperbaiki di `v1.0.6`, sisanya terbuka |
| Kesesuaian dokumentasi | **Diperbaiki di `v1.0.6`** |
| Skor keseluruhan | **~82/100** (naik dari ~72 sebelum perbaikan `v1.0.6`) |

---

## 2. Temuan yang SUDAH DIPERBAIKI (rilis v1.0.6)

### K-1 · Nilai quiz bisa dimanipulasi klien — ✅ DIPERBAIKI

**Sebelum:** `answers.*.question_id` tanpa `distinct`; `QuizController` menghitung setiap
jawaban yang dikirim. Kirim 1 jawaban benar ×100 pada quiz 3 soal → `score = 3333`, `passed = true`.
Ini melanggar aturan `AGENTS.md`: "Backend is the source of truth for quiz scoring".

**Perbaikan:**
- `app/Http/Requests/QuizSubmitRequest.php` — `distinct`, `integer`, `max:200`
- `app/Http/Controllers/QuizController.php:84-114` — penskoran iterasi **soal milik quiz**
  (bukan jawaban kiriman), `min(100, ...)` sebagai pengaman
- Bonus: N+1 hilang (41 → 2 query per submit)
- Test: `tests/Feature/QuizScoreIntegrityTest.php` (7 test)

### K-2 · Unggah file tanpa validasi tipe — ✅ DIPERBAIKI

**Sebelum:** `gambar_cover` = `nullable` tanpa filter; `glb_path` tanpa rule `file:` sehingga
**string biasa** pun lolos dan tersimpan sebagai path; 6 rule `image_path` kehilangan rule `image`.

**Perbaikan** (10 titik):

| Rule | Lokasi |
|------|--------|
| `file\|extensions:glb,gltf\|max:102400` | `ArController.php:48,90` · `Admin/ArModelController.php:38,84` |
| `nullable\|image\|mimes:jpg,jpeg,png,webp\|max:5120` | `MateriStoreRequest.php:25` · `MateriUpdateRequest.php:25` |
| `sometimes\|image\|mimes:jpg,jpeg,png,webp` | `ArController.php:236,356` · `Admin/ArMarkerController.php:139` · `Admin/ArHotspotController.php:77` |

> **Keputusan penting — jangan ganti `extensions:` dengan `mimes:` untuk GLB.**
> Sudah diuji empiris terhadap file GLB asli di repo:
>
> | File | `mimes:glb,gltf` | `extensions:glb,gltf` |
> |------|------------------|----------------------|
> | `real_model.glb` (GLB asli) | ❌ **DITOLAK** | ✅ diterima |
> | `crafted.glb` (magic `glTF`) | ❌ **DITOLAK** | ✅ diterima |
> | `shell.php` | ❌ ditolak | ❌ ditolak |
> | `double.glb.php` | ❌ ditolak | ❌ ditolak |
> | `xss.svg` | ❌ ditolak | ❌ ditolak |
>
> Sebab: rule `mimes` memakai `UploadedFile::guessExtension()` (deteksi **isi file** via `finfo`).
> GLB dilaporkan sebagai `application/octet-stream` → `guessExtension()` mengembalikan `bin`,
> bukan `glb`. Rule `extensions:` memakai `getClientOriginalExtension()` plus
> `shouldBlockPhpUpload()` sebagai lapisan kedua.
> Sumber: `vendor/.../Validation/Concerns/ValidatesAttributes.php:1725` (`validateMimes`)
> dan `:1237` (`validateExtensions`).

- Test: `tests/Feature/UploadValidationTest.php` (8 test)

### K-3 · Tombol marker-ID manual aktif di release — ✅ DIPERBAIKI

`AGENTS.md` §AR RULES melarang layar AR yang hanya berisi "manually typed marker IDs".

**Sebelum:** `ar_uco_scanner_screen.dart:750` menampilkan tombol `_showManualIdInput` tanpa gate,
padahal tombol debug tepat di bawahnya (`761`) sudah memakai `if (kDebugMode)` — indikasi
kelalaian, bukan keputusan desain.

**Perbaikan:** tombol dibungkus `if (kDebugMode)` (`ar_uco_scanner_screen.dart:749`).
Diverifikasi `_showManualInput = true` hanya terjadi di `_showManualIdInput()` (`:422`) yang kini
hanya terjangkau dari tombol debug-gated.

### K-4 · Dokumen bertentangan dengan kode — ✅ DIPERBAIKI

`README.md` pernah mengklaim **Riverpod**, **Augen**, dan **GoRouter** — ketiganya tidak ada
di proyek. `AGENTS.md` juga mewajibkan Riverpod + GoRouter sebagai aturan, padahal tidak ada
di `pubspec.yaml`.

**Perbaikan:** `README.md` ditulis ulang sesuai kode nyata; `frontend/README.md` dan
`backend/README.md` diperbarui (dependensi + jumlah test); `AGENTS.md` diberi penanda
"ARSITEKTUR TARGET — BELUM DIIMPLEMENTASI" agar tidak menyesatkan.

### H-5 · `replaceFirst('/api','')` merusak URL produksi — ✅ DIPERBAIKI

`replaceFirst('/api', '')` menghapus kemunculan **pertama**, sehingga host yang subdomainnya
dimulai `api` ikut rusak:

| baseUrl | `replaceFirst('/api','')` | `stripApiSuffix` |
|---------|---------------------------|------------------|
| `https://api.domain.com/api` | `https:/.domain.com` ❌ | `https://api.domain.com` ✅ |
| `https://api.sekolah.sch.id/api` | `https:/.sekolah.sch.id` ❌ | `https://api.sekolah.sch.id` ✅ |
| `https://apiclient.myapi.co.id/api` | `https:/client.myapi.co.id` ❌ | `https://apiclient.myapi.co.id` ✅ |
| `http://10.0.2.2:8000/api` | `http://10.0.2.2:8000` ✅ | sama ✅ |

Helper benar `ApiConfig.stripApiSuffix()` sudah ada sejak awal tapi hanya dipakai 2×.
**9 situs** masih memakai pola rusak.

**Perbaikan:** 9 situs diganti ke `ApiConfig.baseHost` / `ApiConfig.stripApiSuffix()`:
`admin_ar_management_screen.dart:66` · `guru_ar_management_screen.dart:65` ·
`app_config_service.dart:55` · `ar_content_resolver.dart:135,156` ·
`materi_detail_screen.dart:160,352` · `profile_screen.dart:27` · `model_viewer_screen.dart:307`

**Test:** test lama hanya memakai `10.0.2.2:8000/api` — satu-satunya bentuk yang **menyembunyikan**
bug ini. Sekarang ada `api_config_test.dart` (7 test) + kasus `api.domain.com` di
`ui_content_test.dart` dan `profile_screen_test.dart`.

### H-4 · `usesCleartextTraffic="true"` di manifest utama — ✅ DIPERBAIKI

Setiap APK release mengizinkan HTTP plaintext ke host mana pun, sementara header
`Authorization: Bearer <token>` dikirim pada setiap request.

**Perbaikan:** main manifest → `android:usesCleartextTraffic="false"`;
izin cleartext dipindah ke `android/app/src/debug/AndroidManifest.xml` sehingga
`flutter run` tetap berfungsi.

### BUG BARU · `ar_models.description` NOT NULL → HTTP 500 — ✅ DIPERBAIKI

Ditemukan saat menulis test P0-2. Kolom `description` dan `category` NOT NULL tanpa default,
padahal API menetapkannya `nullable`.

Pemicu nyata: Flutter mengirim `'description': descCtrl.text`; string kosong
`''` → middleware `ConvertEmptyStringsToNull` → `null` → melanggar NOT NULL → **HTTP 500**.
Artinya admin/guru yang mengunggah GLB tanpa mengisi deskripsi mendapat error.

**Perbaikan:** `2026_10_03_120000_make_description_and_category_nullable_in_ar_models_table.php`.

**Validasi di MariaDB 10.4** (DB scratch terpisah, DB developer tidak disentuh):
`SHOW COLUMNS` → `description`/`category` = `NULL: YES` · insert tanpa deskripsi berhasil ·
`migrate:rollback` mengembalikan `NO` · re-migrate kembali `YES`.

---

## 3. Temuan yang MASIH TERBUKA

### 🔴 TINGGI

#### H-1 · Tidak ada Policy/Gate sama sekali

`app/Policies/` **tidak ada**. `AppServiceProvider::boot()` kosong. Otorisasi seluruhnya
string matching di `RoleMiddleware.php:14`.

Konsekuensi: setiap endpoint `PUT/DELETE /api/guru/*/{id}` mempercayai parameter URL.
Guru dapat menghapus soal/materi/quiz milik guru lain.

Endpoint terdampak: `QuizController` (`guruUpdate`, `guruDestroy`, `deleteQuestion`) ·
`MateriController::update/destroy` · `TpAtpController::update/destroy` ·
`ArController` (model/marker/hotspot/mapping update & destroy).

**Catatan:** tidak ada kolom kepemilikan (`created_by`) di `quizzes`, `materi`, `tp_atp`,
sehingga perbaikan memerlukan pekerjaan schema, bukan hanya Policy. Jadwalkan, jangan dipaksakan.

#### H-2 · Tidak ada route guard di Flutter

`MaterialApp` memakai map `routes:` statis tanpa `redirect` (`main.dart:184-200`).
`Navigator.pushNamed(context, '/admin')` dari layar mana pun membuka `AdminDashboard`
tanpa cek role/token. Satu-satunya cek role berjalan sekali di `_buildInitialRoute()`.

**Mitigasi sudah ada:** server tetap mengkap lewat `RoleMiddleware` dan register memaksa
`role = 'siswa'` (`AuthController.php:28`). Jadi siswa yang nyasar ke `/admin` melihat shell
admin yang seluruh panelnya gagal 403 — masalah UX + defense-in-depth, bukan kebocoran data.

#### H-3 · HTTP 403 tidak dibedakan dari 401

`api_service.dart:57-82` hanya menandai 401/419. 403 jatuh ke
"Server mengembalikan respons tidak valid (HTTP 403)" — pesan menyesatkan untuk kegagalan izin,
dan pengguna tidak diarahkan keluar.

#### H-7 · `POST /admin/login` tanpa rate limiting

API login sudah ada `throttle:10,1` (`routes/api.php:13`), tetapi `routes/admin.php:20`
tidak. Admin panel terbuka untuk credential stuffing.

### 🟡 SEDANG

| # | Temuan | Lokasi |
|---|--------|--------|
| M-1 | 2 HTTP client (`dio` + `package:http`) dengan `_token` masing-masing; `main.dart:101-102` harus sync manual + komentar 8 barihindah memperingatkannya | `api_client.dart:8`, `api_service.dart:13` |
| M-2 | 21 query di `GET /api/v1/app/config` — satu SELECT per key, tanpa cache. Request pertama tiap cold start | `AppConfigController.php:16-64`, `AppSetting::getValue()` |
| M-3 | N+1 di hot path AR: `models.hotspots` di-eager-load tanpa filter, lalu diakses lazy | `Api/V1/ArContentController.php:95-147` |
| M-4 | `questions.text` varchar(255) divalidasi `max:1000` → **HTTP 500** di MySQL strict mode | migration `2026_09_17_051731` vs `QuestionStoreRequest.php:20` |
| M-5 | Uniqueness hanya dijaga PHP, tanpa unique index di DB → race condition | `2026_09_17_052941` (`ar_markers.marker_id`) |
| M-6 | Admin bisa menghapus/demote akun sendiri atau admin terakhir → sistem tidak bisa dikelola | `AdminController.php:121`, `Admin/UserController.php:92` |
| M-7 | Ganti password tidak mencabut token lama yang sudah terbit | `ProfileController.php:54` |
| M-8 | ~19 endpoint mengembalikan raw Eloquent model, bukan Resource | `ArController.php`, `TpAtpController.php`, `Admin/ArHotspotApiController.php` |
| M-9 | `bootstrap/app.php:30-32` `withExceptions()` kosong → error tidak konsisten dengan format `{success, message, errors}` | `bootstrap/app.php` |
| M-10 | Root database tiap scan tidak punya indeks komposit | `ar_markers(aruco_dictionary, ar_uco_id)` |
| M-11 | `IndexedStack` memicu ≥5 request network di frame pertama dashboard | `student_dashboard.dart:154` |
| M-12 | `TextEditingController` dibuat di dalam `build()`, tidak di-dispose → alokasi tiap frame (~30 fps) | `ar_uco_scanner_screen.dart:1049` |
| M-13 | `setState` pada setiap frame deteksi AR → rebuild seluruh `Stack` termasuk subtree `ModelViewer` | `ar_uco_scanner_screen.dart:222` |
| M-14 | `ArDiagnosticScreen` (fingerprint perangkat) terbuka untuk siswa dari app-bar | `ar_hub_screen.dart:222` |
| M-15 | 895 literal `Color(0x…)`, 252 di antaranya warna brand `0xFF0A8477` yang sama; tidak ada `app_colors.dart` | seluruh `frontend/lib` |
| M-16 | ~1.800 LOC duplikat: `_buildProfileOption` ×13, `_buildQuickAction` ×12, `_buildBody` ×10; `admin_tp_atp_screen.dart` vs `guru_...` 47% identik | `frontend/lib/screens` |
| M-17 | 5 test tautologis (`expect(15 == 15, true)`) yang tidak memanggil `shouldDownloadMarker` | `test/content_sync_test.dart:125-220` |
| M-18 | `widget_test.dart` melakukan real network I/O → rawan hang di CI | `test/widget_test.dart:13` |

### 🟢 RENDAH

| # | Temuan | Lokasi |
|---|--------|--------|
| L-1 | `assets/markers/default_marker.png` hanya **67 byte** — dipakai sebagai target ARCore saat cache miss, pasti gagal dilacak | `ar_scanner_screen.dart:167` |
| L-2 | 10 asset marker mati (`marker_0..9.png`) tidak direferensikan | `assets/markers/` |
| L-3 | 2 script dev di root backend yang menjalankan `DB::table()->update()` tanpa konfirmasi | `backend/fix_paths.php`, `create_placeholders.php` |
| L-4 | Import tidak terpakai di `QuizController.php:19` (`AnonymousResourceCollection`) | `QuizController.php:19` |
| L-5 | Formatting: `vendor/bin/pint --test` gagal pada 5 file **sudah gagal sebelum perubahan ini** (utang format bawaan, tidak saya perbaiki agar diff tetap ringkas, dan tidak diabaikan CI) | `QuizController.php`, `ArController.php`, `Admin/Ar*Controller.php` |

---

## 4. Yang sudah bagus — jangan dirusak

- **Pipeline ARCore nyata** (bukan fake): `ArEngineView.kt:234` `AugmentedImageDatabase`,
  `:244` `addImage(...)`, `:326` `AugmentedImageNode` + Filament. MemENUHI pipeline wajib `AGENTS.md`.
- **Deteksi OpenCV ArUco yang matang**: async di native thread, detector di-reuse, fast-path
  plane Y, `Mat`/`Vec*` di-dispose di `finally`, mapping orientasi sensor aware. 30 unit test.
- **Keamanan kredensial benar**: token di `flutter_secure_storage`; tidak ada PII/kredensial di
  `SharedPreferences`.
- **Zero kebocoran log**: 14 `print` semuanya di balik `if (kDebugMode)`; `ArDebugLog` juga gated.
- **Konfigurasi API compliant**: `--dart-define` + fallback emulator. Tidak ada `127.0.0.1`
  di jalur request produksi.
- **Server-side RBAC tetap mengkap** meski belum ada Policy.
- **Test backend abnormality baik**: 148 test, termasuk cakupan security yang tidak biasa
  (`QuizSecurityTest`, `MarkerArucoParityTest`, `AuthorizationTest`).

---

## 5. Rekomendasi

### Sudah dikerjakan (v1.0.6)
K-1 integritas skor · K-2 validasi upload · K-3 gate marker-ID manual ·
K-4 konsistensi dokumen · H-5 URL aset produksi · H-4 cleartext traffic · bug `ar_models` NOT NULL

### Berikutnya (P1)
1. `network_security_config.xml` + certificate pinning host produksi
2. Gabung `ApiClient` + `ApiService` menjadi satu client Dio
3. Route guard + bedakan 403 vs 401
4. Hoist `TextEditingController`, `ValueListenableBuilder` + `RepaintBoundary` untuk overlay AR
5. Lazy tabs di dashboard
6. Widen `questions.text` + `question_options.text` ke `text`
7. `throttle` pada `POST /admin/login`
8. Ganti `default_marker.png` dengan placeholder ≥512×512

### Jangka panjang (P2)
9. `app/Policies/` + kolom `created_by` (butuh kerja schema)
10. Ekstrak ~1.800 LOC duplikat + `AppColors`
11. Jalankan test backend juga di MySQL di CI (sudah pernah diverifikasi lokal: 148/148 hijau)
12. Pecah `ArController` (550 LOC) dan `models.dart` (697 LOC)
13. Tentukan: migrasi ke struktur `app/ core/ features/ shared/` **atau** amend `AGENTS.md` lagi

---

*Laporan ini menggantikan audit 20 September 2026 yang memuat klaim tidak sesuai kode.
Seluruh temuan di atas diverifikasi terhadap kode pada commit `5d2d3b5`.*