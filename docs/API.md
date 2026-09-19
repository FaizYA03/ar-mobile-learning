# API Reference - AR Mobile Learning

Base URL: `http://<host>:8000`

Semua response mengikuti format:

```json
{
  "success": true|false,
  "message": "Description",
  "data": {}
}
```

---

## Public Endpoints

### POST `/api/register`

Register siswa baru.

**Request:**
```json
{
  "name": "Budi",
  "email": "budi@mail.com",
  "password": "password",
  "password_confirmation": "password"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "user": { "id": 1, "name": "Budi", "email": "budi@mail.com", "role": "siswa" },
    "token": "1|abc123..."
  }
}
```

---

### POST `/api/login`

Login untuk semua role.

**Request:**
```json
{
  "email": "user@mail.com",
  "password": "password"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "user": { "id": 1, "name": "User", "role": "siswa" },
    "token": "1|abc123..."
  }
}
```

---

### GET `/api/v1/app/config`

App configuration (public, no auth).

**Response (200):**
```json
{
  "success": true,
  "data": {
    "maintenance_mode": false,
    "latest_version": "1.0.0",
    "minimum_supported_version": "1.0.0",
    "build_number": 1,
    "release_notes": "...",
    "download_url": "...",
    "content_version": 12345
  }
}
```

---

### GET `/api/v1/content/version`

Content version number only (public).

**Response (200):**
```json
{
  "success": true,
  "data": {
    "content_version": 12345,
    "updated_at": "2026-09-19T10:00:00Z"
  }
}
```

---

## Authenticated Endpoints

Semua endpoints di bawah memerlukan header:
```
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
```

---

### GET `/api/user`

Current authenticated user.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Budi",
    "email": "budi@mail.com",
    "role": "siswa"
  }
}
```

---

### POST `/api/logout`

Logout (invalidate token).

---

### GET `/api/dashboard`

Dashboard statistics.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "stats": {
      "total_users": 30,
      "total_quizzes": 5,
      "total_materi": 10,
      "total_ar_models": 8
    }
  }
}
```

---

## Quiz

### GET `/api/quizzes`

List all quizzes (authenticated).

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Quiz Pemrograman Dasar",
      "description": "Evaluasi bab 1-3",
      "time_limit": 10,
      "passing_score": 70,
      "questions_count": 5,
      "created_at": "2026-09-01T00:00:00Z"
    }
  ]
}
```

---

### GET `/api/quizzes/{id}`

Quiz detail dengan soal + opsi.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "Quiz Pemrograman Dasar",
    "description": "...",
    "time_limit": 10,
    "passing_score": 70,
    "questions": [
      {
        "id": 1,
        "quiz_id": 1,
        "text": "Apa itu variabel?",
        "order": 1,
        "options": [
          { "id": 1, "question_id": 1, "text": "Tempat menyimpan data", "order": 1 },
          { "id": 2, "question_id": 1, "text": "Fungsi", "order": 2 }
        ]
      }
    ]
  }
}
```

> **Note:** `is_correct` hanya ditampilkan untuk admin/guru.

---

### POST `/api/quizzes/{id}/submit`

Submit quiz jawaban (siswa only).

**Request:**
```json
{
  "answers": [
    { "question_id": 1, "option_id": 1 },
    { "question_id": 2, "option_id": 5 }
  ]
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Quiz selesai",
  "data": {
    "attempt_id": 1,
    "score": 80,
    "correct": 4,
    "total": 5,
    "passed": true
  }
}
```

---

## Guru/Admin - Quiz Management

### GET `/api/guru/quizzes`

List quizzes (includes `questions_count`).

### POST `/api/guru/quizzes`

Create quiz.

**Request:**
```json
{
  "title": "Quiz Baru",
  "description": "Deskripsi",
  "time_limit": 15,
  "passing_score": 75
}
```

### PUT `/api/guru/quizzes/{id}`

Update quiz.

### DELETE `/api/guru/quizzes/{id}`

Delete quiz + all questions + attempts.

---

### POST `/api/guru/quizzes/{id}/questions`

Add question with options.

**Request:**
```json
{
  "text": "Apa itu loop?",
  "options": [
    { "text": "Perulangan", "is_correct": true },
    { "text": "Percabangan", "is_correct": false },
    { "text": "Fungsi", "is_correct": false },
    { "text": "Variabel", "is_correct": false }
  ]
}
```

### DELETE `/api/guru/questions/{id}`

Delete question.

---

## TP/ATP

### GET `/api/tp-atp`

List all TP/ATP.

### GET `/api/tp-atp/{id}`

Detail TP/ATP.

### POST `/api/guru/tp-atp` (guru/admin)

Create TP/ATP.

### PUT `/api/guru/tp-atp/{id}` (guru/admin)

Update TP/ATP.

### DELETE `/api/guru/tp-atp/{id}` (guru/admin)

Delete TP/ATP.

---

## Materi

### GET `/api/materi`

List all materi.

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "judul": "Pemrograman Dasar",
      "slug": "pemrograman-dasar",
      "isi": "Konten materi...",
      "gambar_cover_url": "/storage/materi/cover.jpg",
      "tp_atp_id": 1,
      "created_at": "..."
    }
  ]
}
```

### GET `/api/materi/{id}`

Detail materi.

### POST `/api/guru/materi` (guru/admin)

Create materi (multipart: `judul`, `isi`, `gambar_cover`).

### POST/PUT `/api/guru/materi/{id}` (guru/admin)

Update materi.

### DELETE `/api/guru/materi/{id}` (guru/admin)

Delete materi.

---

## AR Content

### GET `/api/v1/ar/content`

AR content untuk Flutter (authenticated). Mengembalikan semua active models + markers + hotspots.

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "model_name": "CPU 3D",
      "description": "Model 3D CPU",
      "category": "Hardware",
      "version": 3,
      "is_active": true,
      "glb_url": "/storage/ar_models/cpu.glb",
      "thumbnail_url": "/storage/ar_thumbnails/cpu.jpg",
      "markers": [
        {
          "id": 1,
          "marker_id": "MARKER_CPU_001",
          "marker_type": "image",
          "image_url": "/storage/markers/cpu_marker.jpg",
          "status": "active"
        }
      ],
      "hotspots": [
        {
          "id": 1,
          "title": "CPU Socket",
          "description": "Lokasi socket CPU",
          "latitude": 0.0,
          "longitude": 0.0,
          "image_url": null
        }
      ]
    }
  ]
}
```

---

### Guru/Admin - AR Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/ar/models` | List AR models |
| POST | `/api/ar/models` | Create model (multipart) |
| PUT | `/api/ar/models/{id}` | Update model |
| DELETE | `/api/ar/models/{id}` | Delete model |
| GET | `/api/ar/markers` | List markers |
| POST | `/api/ar/markers` | Create marker (multipart) |
| PUT | `/api/ar/markers/{id}` | Update marker |
| DELETE | `/api/ar/markers/{id}` | Delete marker |
| GET | `/api/ar/hotspots` | List hotspots |
| POST | `/api/ar/hotspots` | Create hotspot |
| PUT | `/api/ar/hotspots/{id}` | Update hotspot |
| DELETE | `/api/ar/hotspots/{id}` | Delete hotspot |
| GET | `/api/ar/mappings` | List marker-model mappings |
| POST | `/api/ar/mappings` | Create mapping |
| POST | `/api/ar/markers/{id}/attach` | Attach model to marker |
| DELETE | `/api/ar/markers/{id}/detach/{modelId}` | Detach model |

---

## Admin - User Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/users` | List users |
| POST | `/api/admin/users` | Create user |
| PUT | `/api/admin/users/{id}` | Update user |
| DELETE | `/api/admin/users/{id}` | Delete user |
| GET | `/api/admin/quiz-attempts` | All quiz attempts |

---

## Admin CMS Routes (Blade)

| Route | Description |
|-------|-------------|
| `/admin/login` | Admin login |
| `/admin/dashboard` | Dashboard |
| `/admin/users` | User management |
| `/admin/tp-atp` | TP/ATP management |
| `/admin/materi` | Materi management |
| `/admin/quiz` | Quiz management |
| `/admin/ar/models` | AR model management |
| `/admin/ar/markers` | AR marker management |
| `/admin/ar/hotspots` | AR hotspot management |
| `/admin/ar/mappings` | AR mapping management |
| `/admin/activity-logs` | Activity logs |
| `/admin/system/settings` | System settings |
| `/admin/system/versions` | App version management |

---

## Error Responses

### 422 Validation Error
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "title": ["The title field is required."],
    "email": ["The email has already been taken."]
  }
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Not found"
}
```
