<?php

use App\Models\AppSetting;
use Illuminate\Database\Migrations\Migration;

/**
 * Isi key konten UI (Batch 1 + 2) yang belum ada.
 * Aman untuk DB lama: firstOrCreate, tidak menimpa nilai
 * yang sudah diubah admin via CMS.
 */
return new class extends Migration
{
    public function up(): void
    {
        $defaults = [
            ['key' => 'app_name', 'value' => 'AR Mobile Learning', 'type' => 'string', 'description' => 'Nama aplikasi (splash, header)'],
            ['key' => 'app_tagline', 'value' => 'Informatika dengan Augmented Reality', 'type' => 'string', 'description' => 'Tagline aplikasi (splash)'],
            ['key' => 'app_logo', 'value' => '', 'type' => 'string', 'description' => 'Path logo aplikasi di storage (upload via CMS, kosong = icon bawaan)'],
            ['key' => 'splash_title', 'value' => 'AR Mobile Learning', 'type' => 'string', 'description' => 'Judul besar splash screen'],
            ['key' => 'splash_subtitle', 'value' => 'Informatika dengan Augmented Reality', 'type' => 'string', 'description' => 'Subjudul splash screen'],
            ['key' => 'greeting_siswa', 'value' => 'Selamat belajar hari ini', 'type' => 'string', 'description' => 'Sapaan dashboard siswa'],
            ['key' => 'greeting_guru', 'value' => 'Kelola pembelajaran Anda', 'type' => 'string', 'description' => 'Sapaan dashboard guru'],
            ['key' => 'greeting_admin', 'value' => 'Kelola sistem pembelajaran', 'type' => 'string', 'description' => 'Sapaan dashboard admin'],
            ['key' => 'ui_content_version', 'value' => '1', 'type' => 'integer', 'description' => 'Versi konten UI (auto-naik tiap simpan via CMS)'],
            ['key' => 'announcement_text', 'value' => '', 'type' => 'string', 'description' => 'Teks banner pengumuman Home (kosong = sembunyi)'],
            ['key' => 'announcement_active', 'value' => 'false', 'type' => 'boolean', 'description' => 'Tampilkan banner pengumuman'],
            ['key' => 'help_content', 'value' => "Cara menggunakan aplikasi:\n\n1. Login sesuai role Anda (siswa/guru/admin).\n2. Siswa: buka Materi untuk belajar, kerjakan Quiz, dan scan marker AR untuk melihat objek 3D.\n3. Pastikan koneksi internet aktif dan berikan izin kamera saat diminta.\n4. Hubungi kontak di bawah jika menemui kendala.", 'type' => 'string', 'description' => 'Isi halaman Bantuan'],
            ['key' => 'about_content', 'value' => "AR Mobile Learning adalah media pembelajaran Informatika berbasis Augmented Reality untuk siswa SMA/SMK.\n\nBelajar konsep abstrak menjadi nyata melalui model 3D interaktif yang dipindai dari marker.", 'type' => 'string', 'description' => 'Isi halaman Tentang'],
            ['key' => 'contact_email', 'value' => '', 'type' => 'string', 'description' => 'Email bantuan (kosong = sembunyi)'],
            ['key' => 'contact_wa', 'value' => '', 'type' => 'string', 'description' => 'Nomor WhatsApp bantuan, format 628xx (kosong = sembunyi)'],
        ];

        foreach ($defaults as $row) {
            AppSetting::firstOrCreate(['key' => $row['key']], $row);
        }

        AppSetting::firstOrCreate(
            ['key' => 'onboarding_slides'],
            [
                'value' => json_encode([
                    ['title' => "Belajar Informatika\nLebih Menarik", 'description' => 'Pelajari konsep Informatika melalui materi yang terstruktur dan mudah dipahami.'],
                    ['title' => "Temukan\nDunia 3D", 'description' => 'Scan marker dan lihat objek pembelajaran dalam bentuk 3D secara interaktif.'],
                    ['title' => "Uji\nPemahamanmu", 'description' => 'Uji pemahaman setelah belajar dan lihat hasilnya.'],
                ]),
                'type' => 'json',
                'description' => 'Slide onboarding (judul + deskripsi per slide)',
            ]
        );
    }

    public function down(): void
    {
        // Sengaja tidak menghapus: data konten milik admin.
    }
};
