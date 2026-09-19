# Backend - AR Mobile Learning

Laravel 12 REST API + Admin CMS untuk sistem AR Mobile Learning.

## Requirements

- PHP 8.2+
- Composer
- MySQL 8+ atau SQLite
- Node.js (untuk Vite/Tailwind)

## Setup

```bash
composer install
cp .env.example .env
php artisan key:generate
```

### Database

**SQLite (development):**
```bash
touch database/database.sqlite
php artisan migrate --seed
```

**MySQL (production):**
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ar_mobile_learning
DB_USERNAME=root
DB_PASSWORD=
```

```bash
php artisan migrate --seed
```

### Run Server

```bash
php artisan serve
```

Admin CMS: `http://localhost/admin/login`

Default admin: `admin@admin.com` / `password`

## Project Structure

```
backend/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Admin/          # Admin CMS controllers (Blade)
│   │   │   ├── Api/V1/         # REST API controllers (Sanctum)
│   │   │   ├── ArController.php
│   │   │   ├── AuthController.php
│   │   │   ├── DashboardController.php
│   │   │   ├── MateriController.php
│   │   │   ├── QuizController.php
│   │   │   └── TpAtpController.php
│   │   ├── Middleware/
│   │   │   ├── CorsMiddleware.php
│   │   │   └── RoleMiddleware.php
│   │   └── Requests/
│   │       ├── MateriStoreRequest.php
│   │       ├── MateriUpdateRequest.php
│   │       ├── QuestionStoreRequest.php
│   │       ├── QuizStoreRequest.php
│   │       ├── QuizSubmitRequest.php
│   │       └── QuizUpdateRequest.php
│   ├── Models/
│   │   ├── ArHotspot.php
│   │   ├── ArMarker.php
│   │   ├── ArMarker3dMapping.php
│   │   ├── ArModel.php
│   │   ├── AppSetting.php
│   │   ├── AppVersion.php
│   │   ├── Materi.php
│   │   ├── Question.php
│   │   ├── QuestionOption.php
│   │   ├── Quiz.php
│   │   ├── QuizAttempt.php
│   │   ├── TpAtp.php
│   │   └── User.php
│   ├── Http/Resources/       # API Resources (JSON format)
│   └── Services/
│       └── ActivityLogger.php
├── routes/
│   ├── api.php               # API v1 routes (Sanctum)
│   ├── api_v1.php            # Public + auth API v1 routes
│   ├── admin.php             # Admin CMS routes (session)
│   └── web.php
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/views/admin/    # Blade templates
├── storage/app/public/       # Uploaded files
└── tests/Feature/
```

## API Routes

### Public (no auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/register` | Register siswa |
| POST | `/api/login` | Login (all roles) |
| GET | `/api/v1/app/config` | App config + version info |
| GET | `/api/v1/content/version` | Content version number |

### Authenticated (Sanctum)

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| POST | `/api/logout` | any | Logout |
| GET | `/api/user` | any | Current user |
| GET | `/api/dashboard` | any | Dashboard stats |
| GET | `/api/quizzes` | any | List quizzes |
| GET | `/api/quizzes/{id}` | any | Quiz detail + questions |
| POST | `/api/quizzes/{id}/submit` | siswa | Submit quiz answers |
| GET | `/api/tp-atp` | any | List TP/ATP |
| GET | `/api/materi` | any | List materi |
| GET | `/api/materi/{id}` | any | Materi detail |
| GET | `/api/v1/ar/content` | any | AR content (models+markers) |

### Guru/Admin - Quiz Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/guru/quizzes` | List quizzes |
| POST | `/api/guru/quizzes` | Create quiz |
| PUT | `/api/guru/quizzes/{id}` | Update quiz |
| DELETE | `/api/guru/quizzes/{id}` | Delete quiz |
| POST | `/api/guru/quizzes/{id}/questions` | Add question |
| DELETE | `/api/guru/questions/{id}` | Delete question |

### Guru/Admin - TP/ATP & Materi

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/guru/tp-atp` | Create TP/ATP |
| PUT | `/api/guru/tp-atp/{id}` | Update TP/ATP |
| DELETE | `/api/guru/tp-atp/{id}` | Delete TP/ATP |
| POST | `/api/guru/materi` | Create materi |
| POST/PUT | `/api/guru/materi/{id}` | Update materi |
| DELETE | `/api/guru/materi/{id}` | Delete materi |

### Guru/Admin - AR Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST | `/api/ar/models` | List/Create AR models |
| PUT/DELETE | `/api/ar/models/{id}` | Update/Delete model |
| GET/POST | `/api/ar/markers` | List/Create markers |
| PUT/DELETE | `/api/ar/markers/{id}` | Update/Delete marker |
| GET/POST | `/api/ar/hotspots` | List/Create hotspots |
| PUT/DELETE | `/api/ar/hotspots/{id}` | Update/Delete hotspot |
| GET/POST | `/api/ar/mappings` | List/Create mappings |
| POST | `/api/ar/markers/{id}/attach` | Attach model to marker |
| DELETE | `/api/ar/markers/{id}/detach/{modelId}` | Detach model |

### Admin - User & System

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST | `/api/admin/users` | List/Create users |
| PUT/DELETE | `/api/admin/users/{id}` | Update/Delete user |
| GET | `/api/admin/quiz-attempts` | All quiz attempts |
| GET | `/admin/activity-logs` | Activity logs |
| GET/POST | `/admin/system/settings` | System settings |
| GET/POST | `/admin/system/versions` | App versions |

## Testing

```bash
php artisan test              # Run all 71 tests
php artisan test --filter=Quiz   # Filter by name
```

## Key Behaviors

- **Auth**: Session guard for Admin CMS (`web`), Sanctum tokens for Flutter API
- **Roles**: Enforced via `RoleMiddleware` — never trust client-sent role info
- **Content Version**: Aggregate formula based on active AR model versions, marker count, hotspot count, mapping count
- **Activity Logging**: Login, CRUD operations logged via `ActivityLogger`
- **File Uploads**: Stored in `storage/app/public/`, served via symbolic link
