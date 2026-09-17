# AR MOBILE LEARNING — PROJECT STATUS REPORT

> **Tanggal:** 17 September 2026
> **Versi:** 0.1.0-alpha
> **Stack:** Flutter (Frontend) + Laravel 12 (Backend) + MySQL

---

## RINGKASAN EKSEKUTIF

| Komponen | Status | Persentase |
|----------|--------|------------|
| Backend API | Partial | ~35% |
| Frontend UI | Partial | ~40% |
| Database Schema | Partial | ~60% |
| AR System | Belum ada | 0% |
| Integrasi FE↔BE | Partial | ~30% |

---

## 1. BACKEND (Laravel 12 + Sanctum)

### 1.1 API Endpoint yang Sudah Berfungsi ✅

| Endpoint | Method | Deskripsi | Auth |
|----------|--------|-----------|------|
| `/api/register` | POST | Register siswa + token | Publik |
| `/api/login` | POST | Login semua role + token | Publik |
| `/api/logout` | POST | Hapus token | Sanctum |
| `/api/user` | GET | Data user dari token | Sanctum |
| `/api/dashboard` | GET | Dashboard stats per role | Sanctum |
| `/api/admin/users` | GET | List semua user | Admin |
| `/api/admin/users` | POST | Tambah user baru | Admin |
| `/api/admin/users/{id}` | PUT | Edit user | Admin |
| `/api/admin/users/{id}` | DELETE | Hapus user | Admin |
| `/api/quizzes` | GET | List quiz + jumlah soal | Sanctum |
| `/api/quizzes/{id}` | GET | Detail quiz + soal + opsi | Sanctum |
| `/api/quizzes/{id}/submit` | POST | Submit jawaban + scoring | Sanctum |
| `/api/guru/quizzes` | GET | List quiz (guru) | Guru/Admin |
| `/api/guru/quizzes` | POST | Buat quiz baru | Guru/Admin |
| `/api/guru/quizzes/{id}` | PUT | Edit quiz | Guru/Admin |
| `/api/guru/quizzes/{id}` | DELETE | Hapus quiz | Guru/Admin |
| `/api/guru/quizzes/{id}/questions` | POST | Tambah soal + opsi | Guru/Admin |
| `/api/guru/questions/{id}` | DELETE | Hapus soal | Guru/Admin |

### 1.2 Models

| Model | Table | Fillable | Relationships | Status |
|-------|-------|----------|---------------|--------|
| User | users | name, email, password, role, avatar | HasApiTokens | ✅ |
| Quiz | quizzes | title, description, time_limit, passing_score | hasMany Questions, hasMany Attempts | ✅ |
| Question | questions | quiz_id, text, order | belongsTo Quiz, hasMany Options | ✅ |
| QuestionOption | question_options | question_id, text, is_correct, order | belongsTo Question | ✅ |
| QuizAttempt | quiz_attempts | user_id, quiz_id, score, passed | belongsTo User, belongsTo Quiz | ✅ |

### 1.3 Middleware

| Middleware | Fungsi | Status |
|------------|--------|--------|
| CorsMiddleware | Allow CORS untuk Flutter web | ✅ |
| RoleMiddleware | Cek role user (admin/guru/siswa) | ✅ |
| Sanctum | API token authentication | ✅ |

### 1.4 Database Schema (14 Migrations)

| Tabel | Kolom Utama | Foreign Keys | Status |
|-------|-------------|--------------|--------|
| `users` | id, name, email, password, role, avatar | — | ✅ |
| `quizzes` | id, title, description, time_limit, passing_score | — | ✅ |
| `questions` | id, quiz_id, text, order | quiz_id → quizzes | ✅ |
| `question_options` | id, question_id, text, is_correct, order | question_id → questions | ✅ |
| `quiz_attempts` | id, user_id, quiz_id, score, passed | user_id → users, quiz_id → quizzes | ✅ |
| `ar_markers` | id, marker_id, marker_type, image_path, status | — | ⚠️ Tabel ada, tidak ada Model/API |
| `ar_models` | id, model_name, glb_path, thumbnail_path, description, category, is_active | — | ⚠️ Tabel ada, tidak ada Model/API |
| `ar_marker_models` | id, ar_marker_id, ar_model_id | ar_marker_id → ar_markers, ar_model_id → ar_models | ⚠️ Tabel ada, tidak ada Model/API |
| `ar_hotspots` | id, ar_model_id, title, description, latitude, longitude, image_path, is_active | ar_model_id → ar_models | ⚠️ Tabel ada, tidak ada Model/API |
| `marker_3d_mappings` | id, ar_marker_id, ar_model_id, mapping_method, mapping_status, mapping_notes | ar_marker_id → ar_markers, ar_model_id → ar_models | ⚠️ Tabel ada, tidak ada Model/API |
| `personal_access_tokens` | id, tokenable_type, tokenable_id, name, token, abilities | (Sanctum) | ✅ |
| `cache` | key, value, expiration | — | ✅ |
| `cache_locks` | key, owner, expiration | — | ✅ |
| `jobs` / `job_batches` / `failed_jobs` | Standard Laravel | — | ✅ |

### 1.5 Seeder

| Data | Jumlah | Status |
|------|--------|--------|
| Users (admin, guru, 2 siswa) | 4 | ✅ |
| Quiz (Algoritma, Jaringan, Basis Data) | 3 | ✅ |
| Questions | 6 | ✅ |
| Question Options | 24 | ✅ |
| TP/ATP | 0 | ❌ Belum ada |
| Materi | 0 | ❌ Belum ada |
| AR Markers | 0 | ❌ Belum ada |
| AR Models | 0 | ❌ Belum ada |

### 1.6 Akun Demo

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@demo.com` | `password` |
| Guru | `guru@demo.com` | `password` |
| Siswa | `siswa@demo.com` | `password` |
| Siswa 2 | `siswa2@demo.com` | `password` |

---

## 2. FRONTEND (Flutter)

### 2.1 File Structure

```
frontend/lib/
├── main.dart                          # App entry + routing + theme
├── splash_screen.dart                 # Splash screen (auto-navigate)
├── onboarding_screen.dart             # 3 slide onboarding
├── login_screen.dart                  # Login form + API integration
├── register_screen.dart               # Register form + API integration
├── student_dashboard.dart             # Dashboard siswa + bottom nav + logout
├── guru_dashboard.dart                # Dashboard guru + quiz CRUD + logout
├── admin_dashboard.dart               # Dashboard admin + user CRUD + logout
├── services/
│   └── api_service.dart               # HTTP client ke backend
└── features/                          # (kosong)
```

### 2.2 Screens yang Sudah Berfungsi ✅

| Screen | Fitur Utama |
|--------|-------------|
| **Splash Screen** | Logo + nama app + loading spinner + auto-navigate 2 detik |
| **Onboarding** | 3 slide (Belajar, AR, Quiz) + page indicator + Next/Skip/Mulai Belajar |
| **Login** | Email + password + show/hide + loading/error state + validasi + link Daftar + panggil API |
| **Register** | Nama + email + password + konfirmasi + loading/error + validasi + panggil API |
| **Student Dashboard** | Header nama + progress card + 3 learning cards (Materi/AR/Quiz) + bottom nav 5 tab + Logout |
| **Guru Dashboard** | Header + summary stats + quick actions + **Quiz Management** (list/buat/hapus/tambah soal) + bottom nav + Logout |
| **Admin Dashboard** | Header + stats cards (Users/Guru/Siswa/Quiz) + **User Management** (list/tambah/edit/hapus + role) + bottom nav + Logout |
| **ApiService** | Token management + semua endpoint terhubung + error handling |

### 2.3 Screens yang BELUM ❌

| Screen | Deskripsi | Prioritas |
|--------|-----------|-----------|
| **Siswa — TP/ATP Selection** | Pilih tujuan pembelajaran | 🔴 Tinggi |
| **Siswa — Materi List** | Daftar materi per TP/ATP | 🔴 Tinggi |
| **Siswa — Materi Detail** | Baca materi (judul, konten, gambar) | 🔴 Tinggi |
| **Siswa — Quiz List** | Daftar quiz tersedia | 🔴 Tinggi |
| **Siswa — Quiz Take** | Kerjakan soal pilihan ganda | 🔴 Tinggi |
| **Siswa — Quiz Result** | Lihat skor + pembahasan | 🔴 Tinggi |
| **Siswa — Profile** | Edit profil | 🟡 Sedang |
| **Guru — Materi Management** | CRUD materi | 🔴 Tinggi |
| **Guru — AR Management** | Upload marker + model + hotspot | 🔴 Tinggi |
| **Guru — Hasil Quiz Siswa** | Lihat skor siswa | 🟡 Sedang |
| **Guru — TP/ATP Management** | Kelola tujuan pembelajaran | 🟡 Sedang |
| **Admin — TP/ATP Management** | CRUD TP/ATP | 🔴 Tinggi |
| **Admin — Materi Management** | CRUD materi | 🔴 Tinggi |
| **Admin — AR Management** | CRUD marker + model + hotspot + mapping | 🔴 Tinggi |
| **Admin — Quiz Management** | Lihat semua quiz + soal | 🟡 Sedang |
| **Admin — Hasil Quiz** | Lihat semua hasil siswa | 🟡 Sedang |
| **AR Camera Screen** | Scan marker AR | 🔴 Tinggi |
| **AR 3D Viewer** | Render model + interaksi | 🔴 Tinggi |

### 2.4 Dependencies

| Package | Fungsi | Status |
|---------|--------|--------|
| `shared_preferences` | Token + role storage | ✅ |
| `http` | HTTP client ke API | ✅ |
| `cupertino_icons` | Icon | ✅ |
| AR package | Marker detection + 3D rendering | ❌ Belum dipilih |

---

## 3. FLOW YANG SUDAH BERJALAN END-TO-END

```
Splash Screen (2 detik)
    ↓
Onboarding Slide 1 → Slide 2 → Slide 3 ("Mulai Belajar")
    ↓
Login (email + password) → API → Token + Role
    ↓
Register (nama + email + password) → API → Token + Role
    ↓
Dashboard (data dari API berdasarkan role):
    ├── admin@demo.com → Admin Panel (stats real dari DB + User CRUD)
    ├── guru@demo.com  → Guru Dashboard (stats + Quiz CRUD)
    └── siswa@demo.com → Student Dashboard (stats + learning cards)
    ↓
Logout → Konfirmasi → Hapus token → Kembali ke Login
```

## 4. FLOW YANG BELUM BERJALAN

```
Siswa:
  Pilih TP/ATP → Pilih Materi → Baca Materi → Buka AR
  → Scan Marker → Marker Detected → Load 3D Model → Render
  → Interaksi (rotate/zoom) → Buka Hotspot → Baca Penjelasan
  → Kerjakan Quiz → Submit → Lihat Skor → Lihat Pembahasan

Guru:
  Buat Materi → Edit Materi → Hapus Materi
  → Upload Marker → Upload Model 3D → Hubungkan Marker↔Model
  → Buat Hotspot → Buat Quiz → Tambah Soal → Lihat Hasil Siswa

Admin:
  Kelola TP/ATP → Kelola Materi
  → Kelola Marker → Kelola Model 3D → Kelola Hotspot → Kelola Mapping
  → Kelola Quiz → Kelola Soal → Lihat Semua Hasil
```

---

## 5. PRIORITAS PENGERJAAN

### Fase 1 — Data Foundation 🔴 Mendesak

| # | Task | Tipe | File Terkait |
|---|------|------|-------------|
| 1 | Migration + Model + API **TP/ATP** | Backend | `database/migrations/`, `app/Models/`, `app/Http/Controllers/`, `routes/api.php` |
| 2 | Migration + Model + API **Materi** | Backend | Sama + relasi ke TP/ATP |
| 3 | Seeder data dummy **TP/ATP + Materi** | Backend | `database/seeders/DatabaseSeeder.php` |
| 4 | Storage config untuk **file upload** | Backend | `config/filesystems.php` |

### Fase 2 — Siswa Learning Flow 🔴

| # | Task | Tipe |
|---|------|------|
| 5 | Screen **TP/ATP Selection** | Flutter |
| 6 | Screen **Materi List** + **Materi Detail** | Flutter |
| 7 | Screen **Quiz List** + **Quiz Take** + **Quiz Result** | Flutter |
| 8 | Integrasi semua ke API | Flutter + BE |

### Fase 3 — Guru Content Management 🔴

| # | Task | Tipe |
|---|------|------|
| 9 | Screen **Materi Management** (CRUD) | Flutter + BE |
| 10 | Screen **AR Management** (CRUD marker + model + hotspot) | Flutter + BE |
| 11 | Screen **Lihat Hasil Quiz Siswa** | Flutter + BE |
| 12 | Seeder data dummy **AR markers + models** | Backend |

### Fase 4 — Admin Management 🔴

| # | Task | Tipe |
|---|------|------|
| 13 | Screen **TP/ATP Management** | Flutter + BE |
| 14 | Screen **Materi Management** | Flutter + BE |
| 15 | Screen **AR Management** | Flutter + BE |
| 16 | Screen **Quiz Management** (view semua) | Flutter + BE |

### Fase 5 — AR System 🔴 Kompleks

| # | Task | Tipe |
|---|------|------|
| 17 | Pilih AR package (compatibility check) | Research |
| 18 | Camera permission + preview | Flutter |
| 19 | Marker detection pipeline | Flutter + AR |
| 20 | 3D model loading (.glb) + rendering | Flutter + AR |
| 21 | Interaksi (rotate, zoom, reposition) | Flutter + AR |
| 22 | Hotspot overlay + information panel | Flutter |

### Fase 6 — Finishing 🟡

| # | Task | Tipe |
|---|------|------|
| 23 | Error handling global | Flutter |
| 24 | Loading states konsisten | Flutter |
| 25 | Empty states untuk semua halaman | Flutter |
| 26 | Android build + release | Flutter |
| 27 | Testing di physical device | All |

---

## 6. CATATAN TEKNIS

### Backend
- Laravel 12 dengan struktur baru (tidak ada Kernel.php)
- Sanctum untuk API token authentication
- CORS middleware manual untuk Flutter web
- Role middleware untuk otorisasi per endpoint
- Database: MySQL `armobile_learning`

### Frontend
- Flutter dengan Material 3
- State: StatefulWidget + shared_preferences
- HTTP: `package:http` (bukan Dio)
- Routing: `Navigator.pushReplacementNamed` + routes di MaterialApp
- API URL: `127.0.0.1:8000` (Chrome) / `10.0.2.2:8000` (Android emulator)

### Known Issues
- `flutter analyze`: 0 issues
- Backend berjalan di `http://127.0.0.1:8000`
- Frontend berjalan di Chrome via `flutter run -d chrome`
- Untuk Android physical device: ganti URL ke IP laptop + pastikan USB debugging aktif

---

## 7. REFERENSI MASTER PROMPT

Bagian-bagian master prompt yang sudah diimplementasi:
- ✅ First Install Experience (Splash → Onboarding → Login)
- ✅ 3 Onboarding Slides (Belajar, AR, Quiz)
- ✅ Login Experience (modern, email, password, show/hide, loading/error)
- ✅ Register (nama, email, password)
- ✅ Student Dashboard (header, progress, learning cards)
- ✅ Guru Dashboard (summary, quick actions, quiz management)
- ✅ Admin Dashboard (user management, stats)
- ✅ Role-based routing
- ✅ Logout dengan konfirmasi

Bagian master prompt yang belum diimplementasi:
- ❌ Materi system (CRUD + baca)
- ❌ TP/ATP system
- ❌ AR system (camera, marker, 3D, hotspot)
- ❌ Quiz taking flow (siswa kerjakan soal)
- ❌ Quiz result + pembahasan
- ❌ Guru content management lengkap
- ❌ Admin content management lengkap
- ❌ File upload (gambar, GLB)
- ❌ Bottom navigation yang fully functional
- ❌ Profile edit screen
- ❌ Error/empty states yang konsisten

---

*Report ini dibuat untuk referensi pengerjaan selanjutnya.*
*Terakhir diperbarui: 17 September 2026*
