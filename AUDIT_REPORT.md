# AR Mobile Learning — AUDIT REPORT

> **Audit terakhir:** 5 Oktober 2026 (commit `80c8e1a`, rilis `v1.0.7`)
> **Metode:** pembacaan kode langsung + uji empiris (backend test dijalankan, `dart format`/`flutter analyze` dijalankan)
> **Tidak ada file yang diubah tanpa persetujuan pengguna**

---

## 0. Hasil audit/update sebelumnya (3 Oktober 2026, commit `5d2d3b5`)

Audit sebelumnya melaporkan 7 cacat yang sudah diperbaiki (K-1 s/d K-4, H-4, H-5, bug `ar_models` NOT NULL).
Semua perbaikan itu **terverifikasi masih ada** di `80c8e1a` — tidak ada regresi.

Yang berubah sejak audit tersebut:

| Commit | Isi | Verifikasi |
|--------|-----|------------|
| `74573d5` | URL aset produksi, cleartext traffic, konsistensi dokumentasi | ✅ masih ada |
| `c4b174b` | Draft Bab 3 metodologi R&D + ADDIE (`docs/ADDIE.md`) | ✅ klaim angka test cocok |
| `0864182` | `.gitattributes` normalisasi line ending | ✅ |
| `80c8e1a` | Fix model 3D tidak tampil + preview kamera ArUco putih (`v1.0.7`) | ✅ **bagus, tapi membuka 2 celah baru — lihat §2** |

---

## 1. Ringkasan

| Aspek | Nilai | Perubahan |
|-------|-------|------------|
| Kualitas arsitektur | Baik — backend/frontend terpisah bersih, AR nyata, test kuat | — |
| Keamanan | **Perlu perbaikan** — H-4/H-5 ditutup, H-1/H-2/H-3/H-7 masih terbuka | — |
| Kesesuaian dokumentasi | **Baik** — `README.md`, `AGENTS.md`, `docs/ADDIE.md` sinkron dengan kode | ↑ |
| Skor keseluruhan | **~85/100** (naik dari ~82) | ↑ |

---

## 2. Temuan yang SUDAH DIPERBAIKI (rilis v1.0.7)

### ✅ FIX-1 · Model 3D tidak tampil — regresi kebijakan jaringan

**Gejala:** model gagal dimuat dengan `"halaman web di http://127.0.0.1:41099 tidak dapat dimuat"`.

**Analisis akar (verifikasi ulang oleh audit ini):** benar. `model_viewer_plus` **tidak pernah**
memuat GLB langsung dari URL — ia selalu menjalankan proxy HTTP lokal:

```
frontend/.pub-cache/model_viewer_plus-1.10.0/lib/src/model_viewer_plus_mobile.dart:234
  _proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);   // port acak
:37-39
  _proxyURL = 'http://$host:$port/';                                  // selalu http://
:229
  await webViewController.loadRequest(Uri.parse(_proxyURL));
```

`_proxyURL` **selalu** `http://` dan **selalu** `loopbackIPv4`. `usesCleartextTraffic="false"`
(v1.0.6) memblokirnya → WebView menampilkan halaman error.

**Perbaikan:** Android Network Security Config yang mengizinkan cleartext hanya untuk
`127.0.0.1` + `localhost` (`src/main/res/xml/network_security_config.xml`).
Host lain tetap wajib HTTPS. Build debug punya NSC sendiri dengan `cleartextTrafficPermitted="true"`.

> **Catatan audit:** NSC **benar-benar dipakai** — `android:networkSecurityConfig="@xml/network_security_config"`
> ada di `main/AndroidManifest.xml:14`. Pendekatan "opensource + `tools:replace`" tidak dipilih,
> dan itu keputusan yang tepat karena tidak ada main manifest terpisah untuk Library.

### ✅ FIX-2 · Preview kamera ArUco putih

**Penyebab:** `ar_uco_service.dart` mengunci exposure tepat setelah `initialize()`, sebelum
auto-exposure sempat converge → exposure terkunci pada nilai yang belum benar.

**Perbaikan:** exposure tidak dikunci lagi; fokus dikunci setelah jeda 800 ms lewat
`_stabilizeCamera()` dengan fallback ke `FocusMode.auto` bila device menolak.

**Penilaian:** benar secara teknis. Auto-exposure memang membantu deteksi saat cahaya berubah.
`_stabilizeCamera()` dijaga dengan `_disposeRequested || _controller != controller` sehingga
aman terhadap race dengan `dispose()`.

---

## 3. Temuan BARU yang muncul dari v1.0.7

### 🟡 SEDANG · N-1 · NSC melonggarkan proteksi tanpa test pendukung

`src/main/res/xml/network_security_config.xml` mengizinkan cleartext untuk `127.0.0.1`.
Secara keamanan ini **risikonya rendah** (loopback tidak bisa dieksploitasi app lain), dan
memang **wajib** untuk `model_viewer_plus`.

Namun ada dua konsekuensi yang belum dipertimbangkan:

1. **Tidak ada CI test** yang memverifikasi NSC ini masih sinkron dengan main manifest.
   Kalau suatu saat `model_viewer_plus` diubah / dihapus, allowance-nya menjadi sia-sia
   dan tidak ada yang memperingatkan.
2. **Tidak ada cert pinning** — item P1 di audit sebelumnya masih 0% dikerjakan.
   NSC hanyaOTAL "cleartext atau tidak", **bukan** "hanya cert asli".

### 🟡 SEDANG · N-2 · Preview kamera bisa putih lagi di kondisi tertentu

`_stabilizeCamera()` mengunci fokus setelah 800 ms. Jika pengguna memindaikan marker lalu
mendekatkan/menjauhkan, fokus terkunci bisa membuat marker kecil berada di luar fokus → gagal terdeteksi.
Dulu ini terkunci **selalu** (lebih buruk), jadi ini **perbaikan**, bukan regresi —
tapi masih belum ada penyesuaian fokus ulang saat marker hilang.

### 🟢 RENDAH · N-3 · Fallback `10.0.2.2:8000` masih bisa dipakai di release

`api_config.dart:19` fallback Android adalah `http://10.0.2.2:8000/api`. Di build release
NSC menolak cleartext untuk `10.0.2.2` → app gagal total jika `API_BASE_URL` tidak di-set.

**Belum terverifikasi** apakah release selalu punya `PROD_API_URL`. Kalau secret itu kosong,
`--dart-define=API_BASE_URL=` kosong → fallback emulator → **release rusak total**.

> Ini pre-existing, **bukan** regresi v1.0.7. Tapi sebelumnya cleartext diizinkan sehingga
> setidaknya LAN IP masih jalan; sekarang tidak. **Penting untuk diverifikasi.**

---

## 4. Temuan yang MASIH TERBUKA (belum ada yang berubah sejak audit sebelumnya)

### 🔴 TINGGI

#### H-1 · Tidak ada Policy/Gate sama sekali — ❌ MASIH TERBUKA

Verifikasi ulang:

```
Test-Path backend/app/Policies        → False
Get-Content AppServiceProvider.php    → boot() kosong, register() kosong
Select-String app/Http/Controllers/*.php "authorize\(|Gate::|can\("  → 0 hasil
```

`RoleMiddleware.php` masih satu-satunya lapisan otorisasi — string matching
`in_array($user->role, $roles)`.

**Konsekuensi:** setiap `PUT/DELETE /api/guru/*/{id}` mempercayai parameter URL.
Guru dapat menghapus soal/materi/quiz milik guru lain. Tidak ada kolom kepemilikan
(`created_by`) di `quizzes`, `materi`, `tp_atp` → **perbaikan butuh kerja schema, bukan Policy saja.**

#### H-2 · Tidak ada route guard di Flutter — ❌ MASIH TERBUKA

`main.dart:184-200` masih `initialRoute: '/'` + map `routes:` statis. Tidak ada `redirect`.
Satu-satunya cek role di `_buildInitialRoute()` (`:204`) — **hanya sekali, saat app start.**

> Audit sebelumnya menyebut `Navigator.pushNamed(context, '/admin')` terbuka dari layar mana pun.
> Verifikasi ulang: `Select-String "pushNamed('/admin'"` → **0 hasil**. Jadi jalur serang
> yang *dokumen* sebutkan tidak ada di kode; yang ada adalah `admin_dashboard.dart:874` yang
> memanggil `ServerSettingsDialog.show(context)` (dialog pengaturan server, bukan navigasi).

**Reassessment:** temuan ini **berubah sifat** — bukan "route publik terbuka", tapi
"cek role hanya di cold start". Kalau token berubah (mis. setelah admin reset password),
user tidak di-revalidasi sampai app restart. Prioritas: TINGGI → **SEDANG**.

#### H-3 · HTTP 403 tidak dibedakan dari 401 — ❌ MASIH TERBUKA

`api_service.dart:57` masih `statusCode == 401 || statusCode == 419`.
403 → `"Server mengembalikan respons tidak valid (HTTP 403)"` — pesan menyesatkan untuk
kegagalan izin.

#### H-7 · `POST /admin/login` tanpa rate limiting — ❌ MASIH TERBUKA

`routes/admin.php:20` — `Route::post('/login', [AuthController::class, 'login'])`.
Tidak ada `throttle`. Bandingkan `routes/api.php:13` yang punya `throttle:10,1`.

### 🟡 SEDANG (semua masih terbuka)

| # | Temuan | Verifikasi ulang |
|---|--------|-----------------|
| M-1 | 2 HTTP client (`dio` + `package:http`) dengan `_token` masing-masing | `api_client.dart:118` & `api_service.dart:21` — keduanya punya `setToken` terpisah |
| M-2 | 18 query `AppSetting::getValue()` + `AppVersion::getLatest()` + 5 query agregat di `GET /api/v1/app/config` | `AppConfigController.php` — 18 call, tanpa cache |
| M-3 | `$model->hotspots` di-eager-load tanpa filter, diakses lazy | `ArContentController.php:147,225` — hotspot difilter di PHP, bukan di SQL |
| M-4 | `questions.text` varchar(255) divalidasi `max:1000` → HTTP 500 di MySQL strict mode | Migration `2026_09_17_051731:14` `$table->string('text')` vs `QuestionStoreRequest.php:18` `max:1000` |
| M-5 | Uniqueness hanya dijaga PHP, tanpa unique index di DB | `2026_09_17_052941:16` `$table->string('marker_id')` — tidak ada `->unique()` |
| M-6 | Admin bisa menghapus/demote akun sendiri / admin terakhir | `AdminController.php:122`, `Admin/UserController.php:93` — tidak ada cek `user->id !== auth()->id()` |
| M-7 | Ganti password tidak mencabut token lama | `ProfileController.php:54-55` — hanya `save()`, tidak ada `tokens()->delete()` |
| M-8 | ~19 endpoint mengembalikan raw Eloquent model, bukan Resource | `ArController.php` — 29 `response()->json` langsung |
| M-9 | `bootstrap/app.php` `withExceptions()` kosong | Terverifikasi masih `//` kosong |
| M-10 | Root database tiap scan tanpa indeks komposit | `ar_markers(aruco_dictionary, ar_uco_id)` — tidak ada index |
| M-11 | `IndexedStack` memicu ≥5 request network di frame pertama dashboard | `student_dashboard.dart:154` — masih `IndexedStack` |
| M-12 | `TextEditingController` dibuat di dalam `build()`, tidak di-dispose | `ar_uco_scanner_screen.dart:1050` — masih di dalam `_buildManualInputField()` |
| M-13 | `setState` pada setiap frame deteksi AR | `ar_uco_scanner_screen.dart` — 30 call `setState` |
| M-14 | `ArDiagnosticScreen` (fingerprint perangkat) terbuka untuk siswa | `ar_hub_screen.dart:230` — tidak ada gate `kDebugMode` |
| M-15 | 895 literal `Color(0x…)`, 252 warna brand `0xFF0A8477`; tidak ada `app_colors.dart` | Verifikasi ulang: **tepat 895 / 252** |
| M-16 | ~1.800 LOC duplikat | 10 method `_build*` duplikat terverifikasi |
| M-17 | 5 test tautologis (`expect(15 == 15, true)`) | `content_sync_test.dart:125-220` — **masih ada** |
| M-18 | `widget_test.dart` melakukan real network I/O | `test/widget_test.dart` — masih `runAsync` + fetch config |

### 🟢 RENDAH

| # | Temuan | Verifikasi ulang |
|---|--------|-----------------|
| L-1 | `assets/markers/default_marker.png` hanya **67 byte** | **Terverifikasi: 67 byte** |
| L-2 | 10 asset marker mati (`marker_0..9.png`, ~2.2–2.7 KB masing-masing) | Terverifikasi ada, tidak direferensikan |
| L-3 | 2 script dev di root backend menjalankan `DB::table()->update()` tanpa konfirmasi | `backend/fix_paths.php`, `backend/create_placeholders.php` |
| L-4 | Import tidak terpakai di `QuizController.php:19` (`AnonymousResourceCollection`) | **Terverifikasi masih ada** |
| L-5 | `vendor/bin/pint --test` gagal pada **73 file** (68 file bila memakai scope yang didokumentasikan `README.md`) | **Jumlah naik dari 5 → 73** (lihat catatan di bawah) |

> **Catatan L-5 — koreksi terhadap audit sebelumnya.** Audit sebelumnya melaporkan
> "gagal pada 5 file". Verifikasi ulang pada `80c8e1a` menunjukkan **73 file** gagal
> pada `pint --test` penuh, atau **68 file** bila memakai scope yang didokumentasikan
> di `README.md:129` (`vendor/bin/pint --test app database routes tests`).
>
> Peningkatan ini **bukan** regresi `v1.0.7` — sebagian besar berasal dari fixer
> `fully_qualified_strict_types` + `ordered_imports` yang aktif, dan 10 file
> karena masalah line ending (lihat **A-4**).
>
> **Tidak ada `pint.json` di repo** dan `ci.yml` **tidak menjalankan `pint` sama sekali**
> (hanya `php artisan test`). Jadi kondisi ini tidak akan pernah terdeteksi otomatis.

---

## 5. Status Test — hasil eksekusi nyata

| Perintah | Hasil |
|----------|-------|
| `php artisan test` (backend) | ✅ **148 passed, 1 skipped, 683 assertions** — 63,19 dtk |
| `flutter analyze` | ✅ **No issues found** — 157,4 dtk |
| `dart format --set-exit-if-changed .` | ✅ **65 files, 0 changed** |
| `flutter test` (frontend) | ⚠️ **Tidak bisa dijalankan di mesin ini** |
| `vendor/bin/pint --test` | ❌ 73 file gagal formatting |

### Kenapa `flutter test` tidak bisa diverifikasi di mesin audit

```
dartcv_exports.def : error LNK2001: unresolved external symbol cv_ximgproc_EdgeDrawing_close
  ... 10 unresolved externals
Building native assets failed.
-- Failed to find installed gflags CMake configuration
-- Failed to find glog
```

Ini **masalah lingkungan Windows**, bukan regresi kode:
- `dartcv4` butuh build native OpenCV via CMake + Visual Studio
- `gflags` dan `glog` tidak terpasang → 10 simbol tidak ter-resolve
- Test yang butuh `dartcv` (`ar_uco_service_test.dart`, 30 test) **tidak bisa compile**

**Yang bisa diverifikasi:** 131 deklarasi `test()`/`testWidgets()` di 13 file.
**Yang tidak:** apakah semuanya hijau. Klaim "131 passed" di commit `80c8e1a`
dan `docs/ADDIE.md:366` **belum bisa dikonfirmasi ulang secara independen** —
hanya.android/CI. Verifikasi di Android/CI tetap diperlukan.

---

## 6. Yang sudah bagus — jangan dirusak

- **Pipeline ARCore nyata** (bukan fake): `ArEngineView.kt` `AugmentedImageDatabase` → `AugmentedImageNode` + Filament.
- **Deteksi OpenCV ArUco matang**: async di native thread, detector di-reuse, fast-path plane Y,
  `Mat`/`Vec*` di-dispose di `finally`. 30 unit test.
- **v1.0.7 menunjukkan kedalaman diagnosis**: membaca source `model_viewer_plus` untuk menemukan
  HTTP proxy internal, bukan menebak. Ini kualitas kerja yang tinggi.
- **NSC dikonfigurasi per-build dengan benar**: `src/debug/` vs `src/main/` — tidak ada cleartext
  di release kecuali loopback yang wajib.
- **Keamanan kredensial benar**: token di `flutter_secure_storage`; tidak ada PII di `SharedPreferences`.
- **Zero kebocoran log**: semua `print` di balik `if (kDebugMode)`.
- **Konfigurasi API compliant**: `--dart-define` + fallback; tidak ada `127.0.0.1` di jalur produksi.
- **Test backend abnormality baik**: 148 test, termasuk cakupan security yang tidak biasa
  (`QuizScoreIntegrityTest`, `QuizSecurityTest`, `MarkerArucoParityTest`, `UploadValidationTest`).
- **Dokumentasi sudah sinkron**: `docs/ADDIE.md` secara eksplisit mencatat bahwa `augen` **tidak pernah dipakai**
  dan mengoreksi jumlah test lama (71/47 → 148/131). Ini kejujuran dokumentasi yang jarang.

---

## 7. Temuan tambahan dari audit ini (baru ditemukan)

### 🔴 TINGGI · A-1 · Tidak ada guard atas `--dart-define` kosong di CI

`release-apk.yml:71`:
```yaml
flutter build apk --release --dart-define=API_BASE_URL=${{ secrets.PROD_API_URL }}
```

Kalau `PROD_API_URL` tidak diset di repo settings:
- `--dart-define=API_BASE_URL=` → `String.fromEnvironment('API_BASE_URL', defaultValue: '')`
  menghasilkan `''` → `ApiConfig.baseUrl` jatuh ke fallback `http://10.0.2.2:8000/api`
- v1.0.6: masih jalan kalau ada cleartext
- **v1.0.7 + NSC: release mati total** — `10.0.2.2` ditolak cleartext

**Perbaikan yang disarankan (satu baris, biaya nol):**
```yaml
- name: Verify PROD_API_URL secret
  run: |
    test -n "${{ secrets.PROD_API_URL }}" || (echo "::error::PROD_API_URL kosong" && exit 1)
```
Tambahkan juga guard di `ApiConfig.baseUrl` yang melempar di release kalau `_envBaseUrl` kosong.

### 🟡 SEDANG · A-2 · `pint` tidak pernah dijalankan di CI

`ci.yml` tidak memanggil `vendor/bin/pint`, dan tidak ada `pint.json` di repo.
73 file tidak sesuai format standar Laravel, dan tidak ada yang akan pernah diberi tahu.
Dua opsi yang masuk akal (pilih salah satu, jangan biarkan keduanya absen):
- tambahkan `vendor/bin/pint --test` ke CI **dan** perbaiki 73 file, atau
- buat `pint.json` eksplisit (toggle-off fixer yang tidak relevan), lalu perbaiki sisanya

Membiarkan keduanya tidak ada berarti utang format yang terus diam.

### 🟡 SEDANG · A-3 · Tidak ada indeks komposit pada hot path AR

`ArContentController::resolve` melakukan:
```php
ArMarker::where('aruco_dictionary', ...)->where('ar_uco_id', ...)->where('status', 'active')
```
tanpa index komposit. Tabel `ar_markers` tidak punya index apa pun pada kombinasi itu
(`2026_09_20_130000` hanya menambah kolom). Setiap scan marker = **full table scan**.
Dengan `marker_id` juga tanpa unique index (M-5).

Untuk dataset kecil ini belum terasa, tapi ini persis hot path yang dipakai setiap scan.

### 🟡 SEDANG · A-4 · `.gitattributes` deklarasi `eol=lf` tapi working tree Windows masih CRLF

`.gitattributes:11` menyatakan `* text=auto eol=lf`. Verifikasi dengan `git ls-files --eol`:

```
i/crlf  (CRLF tersimpan di index)  :   0  dari 456 file tracked   ← index SEHAT
w/crlf  (CRLF di working tree)     : 129  dari 456 file tracked   ← working tree TIDAK
```

Jadi **tidak ada korupsi yang ter-commit** — index bersih LF. Yang terjadi: `eol=lf`
hanya berlaku saat git melakukan checkout, sedangkan working tree di mesin ini ditulis ulang
oleh tooling Windows yang emits CRLF setelah checkout terakhir.

**Dampak nyata:**
- 10 file PHP gagal di `pint` karena fixer `line_ending`:
  `MateriController.php`, `TpAtpController.php`, `ArMarker.php`, `ArModel.php`,
  `Materi.php`, `TpAtp.php`, migrasi `2026_09_18_020000` + `2026_09_18_020001`,
  `DatabaseSeeder.php`, `routes/api.php`
- Pengembang di Windows akan melihat `pint --test` gagal terus-menerus →
  lint eventually diabaikan total
- Potensi konflik *"Failed to save: the content of the file is newer"* — masalah persis
  yang dicoba diselesaikan oleh `0864182`, jadi **solusinya belum tuntas**

**Perbaikan:** `git add --renormalize .` lalu commit (memaksa index ditulis ulang mengikuti
`.gitattributes`), dan set `git config core.autocrlf false` di repo agar tidak bertengkar
dengan `eol=lf`.

---

## 8. Rekomendasi

### Sudah dikerjakan
- **v1.0.6** — K-1 integritas skor · K-2 validasi upload · K-3 gate marker-ID manual ·
  K-4 konsistensi dokumen · H-5 URL aset produksi · H-4 cleartext traffic · bug `ar_models` NOT NULL
- **v1.0.7** — FIX-1 NSC loopback (model 3D) · FIX-2 auto-exposure (preview ArUco)

### P0 — sebelum rilis berikutnya (biaya rendah, dampak tinggi)
1. **A-1** — guard `PROD_API_URL` kosong di `release-apk.yml` + guard runtime di `ApiConfig`
2. **N-3** — verifikasi `PROD_API_URL` benar-benar ter-set di GitHub repo settings
3. **A-3** — index komposit `ar_markers(aruco_dictionary, ar_uco_id, status)` + unique `marker_id`
4. **M-4** — widen `questions.text` + `question_options.text` ke `text` (mencegah HTTP 500 di produksi MySQL)
5. **M-2** — cache `AppSetting::getValue()` (hemat 18 query tiap cold start)
6. **A-4** — `git add --renormalize .` + `core.autocrlf false` (menuntaskan `0864182`)

### P1 — sprint berikutnya
7. **H-7** — `throttle` pada `POST /admin/login`
8. **H-3** — bedakan 403 vs 401 di `api_service.dart`
9. **M-1** — gabung `ApiClient` + `ApiService` jadi satu Dio (hapus 2 `_token`)
10. **M-12/M-13** — hoist `TextEditingController`; `ValueListenableBuilder` + `RepaintBoundary` untuk overlay AR
11. **L-1** — ganti `default_marker.png` (67 byte) dengan placeholder ≥512×512
12. **A-2** — `pint` di CI + perbaiki 73 file (atau `pint.json` eksplisit)
13. **M-7** — `tokens()->delete()` saat ganti password
14. **M-17** — ganti 5 test tautologis dengan test yang memanggil `shouldDownloadMarker`
15. **M-18** — `widget_test.dart` jangan melakukan real network I/O

### P2 — jangka panjang
16. **H-1** — `app/Policies/` + kolom `created_by` (butuh kerja schema)
17. **N-1** — cert pinning host produksi + test yang memverifikasi NSC sinkron dengan main manifest
18. **M-16/M-15** — ekstrak ~1.800 LOC duplikat + `AppColors` untuk 252 literal
19. **M-14** — gate `ArDiagnosticScreen` di balik `kDebugMode`
20. Jalankan test backend juga di MySQL di CI
21. Pecah `ArController` (550 LOC) dan `models.dart` (697 LOC)
22. Tentukan: migrasi ke `app/ core/ features/ shared/` **atau** amend `AGENTS.md`

---

## 9. Catatan metodologi

**Yang diverifikasi langsung oleh audit ini:**
- `php artisan test` → **148 passed / 1 skipped / 683 assertions** (63,19 dtk)
- `flutter analyze` → **No issues found** (157,4 dtk)
- `dart format --set-exit-if-changed .` → **65 files, 0 changed**
- `vendor/bin/pint --test` → **73 file gagal** (68 file pada scope `README.md`)
- `git ls-files --eol` → **0 file CRLF di index**, 129 file CRLF di working tree
- Source `model_viewer_plus-1.10.0` dibaca langsung (loopback HTTP proxy terkonfirmasi di `:234`, `:37-39`, `:229`)
- Inventaris dihitung ulang: 25 controller · 14 model · 29 migration · 22 test file backend ·
  13 test file frontend · 20.648 LOC Dart · 895 literal warna
- Setiap temuan §4 diperiksa ulang di commit `80c8e1a`

**Yang TIDAK bisa diverifikasi di mesin ini:**
- `flutter test` (131 test) — gagal build native `dartcv4` di Windows
  (`gflags`/`glog` tidak terpasang, 10 `LNK2001 unresolved externals`).
  Hanya bisa diverifikasi di Android atau CI. Claims "131 passed" di `80c8e1a`
  dan `docs/ADDIE.md:366` **belum dikonfirmasi ulang secara independen**.
- Perilaku AR di perangkat nyata (preview kamera, deteksi marker, render 3D).
  Semua temuan AR di sini berbasis pembacaan kode, bukan pengujian.
- Apakah `PROD_API_URL` ter-set di GitHub repo settings (lihat **A-1**).

**Koreksi terhadap audit sebelumnya:**
- **L-5**: "5 file" → **73 file** (penaikannya karena fixer `fully_qualified_strict_types` +
  `ordered_imports`, dan 10 file karena line ending — **bukan** regresi `v1.0.7`)
- **H-2**: `pushNamed('/admin')` **tidak ada** di kode. Temuan direklasifikasi TINGGI → SEDANG
  dan findetinya diubah jadi "cek role hanya di cold start".
- **L-1/L-2/L-4** — dikonfirmasi ulang dengan angka persis (67 byte; 10 asset mati; 1 import tak terpakai).

---

*Laporan ini memperbarui audit 3 Oktober 2026 (commit `5d2d3b5`).
Seluruh temuan di atas diverifikasi terhadap kode pada commit `80c8e1a`.*