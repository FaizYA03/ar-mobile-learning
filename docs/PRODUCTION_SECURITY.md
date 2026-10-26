# Production Security Hardening

Status: **belum dijalankan di server produksi**. Panduan ini disusun dari audit
26 Oktober 2026. Jalankan setelah kode P0/P1 direview, di-commit, dan lolos CI.

Temuan yang ditutup panduan ini:

- Akun demo (`admin@demo.com`, `guru@demo.com`, `siswa@demo.com`,
  `siswa2@demo.com`) masih aktif di produksi dengan password yang diketahui publik.
- `docs/DEPLOY.md` pernah menyuruh `migrate --seed`; seeder membuat akun demo.
- CMS masih mengiklankan versi `1.0.9` / build `10`, sedangkan APK `1.0.10+11`.
- CORS produksi `*` dan belum ada HSTS.
- Perlu memastikan tidak ada admin/token lain yang tidak dikenal.

---

## 0. Sebelum mulai

1. Backup database dan file `.env`.

   ```bash
   cd /var/www/ar-mobile-learning/backend
   php artisan db:show                 # catat nama database
   mysqldump -u <user> -p <nama_db> > ~/backup-$(date +%F-%H%M).sql
   cp .env ~/env-backup-$(date +%F-%H%M)
   ```

2. Catat commit yang sedang berjalan.

   ```bash
   cd /var/www/ar-mobile-learning
   git rev-parse HEAD
   ```

3. Lakukan pada jam sepi. Beberapa langkah (revoke semua token/session) akan
   memaksa semua pengguna login ulang.

---

## 1. Deploy kode P0/P1

Jangan deploy manual dari working tree yang kotor.

1. Review dan commit perubahan di lokal.
2. Push ke `main`.
3. Tunggu workflow **CI** hijau.
4. Workflow **Deploy Backend** akan menunggu CI untuk SHA yang sama, checkout
   SHA tersebut, lalu menjalankan `php artisan migrate --force`.

Migrasi baru yang akan berjalan:

- `2026_10_26_000000_expand_text_columns_for_validation_limits.php`
  (`questions.text`, `question_options.text`, `quizzes.description`,
  `ar_models.description` menjadi `TEXT`).
- `2026_10_26_000100_add_created_by_to_content_tables.php`
  (kolom `created_by` untuk kepemilikan konten).

Verifikasi setelah deploy:

```bash
cd /var/www/ar-mobile-learning/backend
php artisan migrate:status
php artisan about
```

Jika deploy manual (tanpa workflow), **jangan** memakai `--seed`:

```bash
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

## 2. Audit akses sebelum menghapus akun demo

Login CMS: `https://api.arlearning.my.id/login`

1. Pastikan ada admin non-demo yang bisa login.

   ```bash
   cd /var/www/ar-mobile-learning/backend
   php artisan tinker --execute='App\Models\User::where("role","admin")->get(["id","email"])->each(fn ($u) => print($u->id." ".$u->email.PHP_EOL));'
   ```

   Target: tersisa admin asli (id `14` pada audit). Jika hanya ada akun demo,
   buat admin baru terlebih dahulu dan uji login.

2. Periksa aktivitas mencurigakan **sebelum** akun demo dihapus.

   ```sql
   SELECT u.email, a.action, a.description, a.ip_address, a.created_at
   FROM activity_logs a
   LEFT JOIN users u ON u.id = a.user_id
   ORDER BY a.created_at DESC
   LIMIT 200;
   ```

   Cari login admin demo, perubahan user/role, upload file, perubahan AR, atau
   akses dari IP yang tidak dikenal. Simpan hasilnya sebagai bukti.

3. Periksa token API yang masih aktif.

   ```bash
   php artisan tinker --execute='App\Models\User::where("email","like","%@demo.com")->get()->each(fn ($u) => print($u->email." tokens=".$u->tokens()->count().PHP_EOL));'
   ```

---

## 3. Nonaktifkan dan hapus akun demo

Hapus token lebih dulu, lalu session, lalu user. `quiz_attempts` milik user demo
akan ikut terhapus (`cascadeOnDelete`); `activity_logs.user_id` menjadi `NULL`.

```bash
cd /var/www/ar-mobile-learning/backend
php artisan tinker --execute='
$emails = ["admin@demo.com", "guru@demo.com", "siswa@demo.com", "siswa2@demo.com"];
$users = App\Models\User::whereIn("email", $emails)->get();

foreach ($users as $user) {
    $user->tokens()->delete();
    DB::table("sessions")->where("user_id", $user->id)->delete();
    $user->delete();
}

echo "Deleted: ".$users->count().PHP_EOL;
echo "Admin left: ".App\Models\User::where("role", "admin")->where("email", "not like", "%@demo.com")->count().PHP_EOL;
'
```

Verifikasi:

```bash
php artisan tinker --execute='echo "Demo left: ".App\Models\User::where("email","like","%@demo.com")->count().PHP_EOL;'
```

Login dengan `admin@demo.com` / `password` harus gagal.

Jika akun demo tidak boleh dihapus (misalnya untuk demo dosen), minimal ganti
password dan revoke token:

```bash
php artisan tinker --execute='$u=App\Models\User::where("email","admin@demo.com")->firstOrFail(); $u->password=Hash::make("PASSWORD-BARU-YANG-KUAT"); $u->save(); $u->tokens()->delete(); echo "updated".PHP_EOL;'
```

---

## 4. Revoke semua token/session (opsional, jika ada indikasi kompromi)

Jika tidak yakin apakah token demo admin dipakai, lakukan ini. Semua pengguna
harus login ulang.

```bash
php artisan tinker --execute='DB::table("personal_access_tokens")->delete(); DB::table("sessions")->delete(); echo "all tokens and sessions revoked".PHP_EOL;'
```

Ganti juga password admin asli dan revoke token admin tersebut. Ganti `14`
dengan id admin yang sudah diverifikasi.

```bash
php artisan tinker --execute='$u=App\Models\User::where("id",14)->firstOrFail(); $u->password=Hash::make("PASSWORD-BARU-YANG-KUAT"); $u->save(); $u->tokens()->delete(); echo "admin password rotated".PHP_EOL;'
```

Rotasi `APP_KEY` hanya jika ada dugaan kebocoran kunci. Ini membatalkan session,
cookie terenkripsi, dan data terenkripsi, tetapi **tidak** membatalkan Sanctum
token (token disimpan sebagai hash). Revoke token tetap wajib.

```bash
php artisan key:generate --force
php artisan config:cache
```

---

## 5. Batasi CORS

Edit `.env` produksi:

```dotenv
# Ganti dengan origin web yang benar-benar memakai API.
# Mobile app tidak mengirim Origin, jadi tidak terpengaruh.
CORS_ALLOWED_ORIGINS=https://download.arlearning.my.id
```

Jika CMS dan API satu domain, CORS tidak dibutuhkan untuk CMS. Jangan tambahkan
`*`. Setelah itu:

```bash
php artisan config:cache
```

Verifikasi origin yang tidak diizinkan tidak mendapat header izin:

```bash
curl -s -i -X OPTIONS https://api.arlearning.my.id/api/v1/login \
  -H "Origin: https://evil.example" \
  -H "Access-Control-Request-Method: POST" | grep -i "access-control-allow-origin" \
  || echo "OK: origin ditolak"
```

Verifikasi origin yang diizinkan (ganti bila perlu):

```bash
curl -s -i -X OPTIONS https://api.arlearning.my.id/api/v1/login \
  -H "Origin: https://download.arlearning.my.id" \
  -H "Access-Control-Request-Method: POST" | grep -i "access-control-allow-origin"
```

Catatan: kode baru hanya memantulkan origin yang ada di daftar. Origin asing
tidak lagi menerima `Access-Control-Allow-Origin` milik domain lain.

---

## 6. Aktifkan HSTS

Pastikan HTTPS sudah benar untuk semua host sebelum menambah HSTS. Mulai tanpa
`includeSubDomains`.

Di blok `server` nginx untuk `api.arlearning.my.id` dan
`download.arlearning.my.id`:

```nginx
add_header Strict-Transport-Security "max-age=31536000" always;
```

Lalu:

```bash
nginx -t
systemctl reload nginx
```

Verifikasi:

```bash
curl -s -I https://api.arlearning.my.id | grep -i strict-transport-security
```

Jangan tambahkan `includeSubDomains` sebelum semua subdomain dipastikan HTTPS.
Jika memakai Cloudflare/proxy, pastikan header tidak terduplikasi.

---

## 7. Perbarui versi aplikasi di CMS

CMS: `https://api.arlearning.my.id/login` → System → Versions.

Tambahkan:

| Field | Nilai |
|---|---|
| Platform | `android` |
| Version | `1.0.10` |
| Build number | `11` |
| Minimum supported | nilai kebijakan saat ini (contoh `1.0.8`) |
| Download URL | `https://download.arlearning.my.id/downloads/ar-mobile-learning-v1.0.10.apk` |
| Active | ya |

Nonaktifkan versi `1.0.9` agar `/api/v1/app/config` mengembalikan `1.0.10`.

Alternatif tinker (sesuaikan minimum dan URL bila perlu):

```bash
cd /var/www/ar-mobile-learning/backend
php artisan tinker --execute='
App\Models\AppVersion::where("platform", "android")->update(["is_active" => false]);

App\Models\AppVersion::create([
    "platform" => "android",
    "version" => "1.0.10",
    "build_number" => "11",
    "minimum_supported_version" => "1.0.8",
    "release_notes" => "Perbaikan keamanan dan dukungan marker ArUco multi-dictionary.",
    "download_url" => "https://download.arlearning.my.id/downloads/ar-mobile-learning-v1.0.10.apk",
    "is_active" => true,
]);

echo "version updated".PHP_EOL;
'
```

Verifikasi:

```bash
curl -s https://api.arlearning.my.id/api/v1/app/config
```

Harus menampilkan `latest_version: "1.0.10"` dan `build_number: "11"`.

---

## 8. Checklist verifikasi akhir

- [ ] `APP_ENV=production`, `APP_DEBUG=false`.
- [ ] `php artisan migrate:status` tidak ada migrasi pending.
- [ ] Tidak ada user `%@demo.com`.
- [ ] Login demo gagal; login admin asli berhasil.
- [ ] Token/session demo sudah dicabut.
- [ ] `activity_logs` sudah direview.
- [ ] `CORS_ALLOWED_ORIGINS` bukan `*`; origin asing ditolak.
- [ ] HSTS muncul di response HTTPS.
- [ ] `/api/v1/app/config` mengembalikan `1.0.10` / `11`.
- [ ] APK `v1.0.10` bisa diunduh dari landing page.
- [ ] Uji AR di perangkat Android fisik: marker `DICT_5X5_100` terdeteksi dan
      model muncul (bukan hanya camera preview).
- [ ] `php artisan queue:restart` setelah deploy.

---

## 9. Rollback

Jika terjadi masalah setelah deploy:

```bash
cd /var/www/ar-mobile-learning
git checkout -f <SHA-SEBELUMNYA>
cd backend
composer install --no-dev --optimize-autoloader --no-interaction
php artisan migrate:rollback --step=1   # hanya jika migrasi baru bermasalah
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

Jangan rollback database tanpa backup. Migrasi `TEXT` dan `created_by` bersifat
aditif; rollback `TEXT` mengubah kolom kembali ke `varchar(255)` dan bisa
memotong data yang lebih panjang.
