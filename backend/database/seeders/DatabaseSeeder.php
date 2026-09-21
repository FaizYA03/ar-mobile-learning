<?php

namespace Database\Seeders;

use App\Models\ArModel;
use App\Models\ArMarker;
use App\Models\ArHotspot;
use App\Models\AppSetting;
use App\Models\Materi;
use App\Models\Question;
use App\Models\QuestionOption;
use App\Models\Quiz;
use App\Models\TpAtp;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // === 1. USERS ===
        $admin = User::create([
            'name' => 'Admin Utama',
            'email' => 'admin@demo.com',
            'password' => Hash::make('password'),
            'role' => 'admin',
        ]);

        $guru = User::create([
            'name' => 'Budi Santoso, S.Kom.',
            'email' => 'guru@demo.com',
            'password' => Hash::make('password'),
            'role' => 'guru',
        ]);

        $siswa = User::create([
            'name' => 'Andi Saputra',
            'email' => 'siswa@demo.com',
            'password' => Hash::make('password'),
            'role' => 'siswa',
        ]);

        User::create([
            'name' => 'Siti Rahayu',
            'email' => 'siswa2@demo.com',
            'password' => Hash::make('password'),
            'role' => 'siswa',
        ]);

        // === 1b. APP SETTINGS ===
        AppSetting::create(['key' => 'arcore_enabled', 'value' => 'true', 'type' => 'boolean', 'description' => 'Enable/disable ARCore on client devices']);

        // === 2. AR MODELS (Demo sample untuk 3D viewing) ===
        // wireless_router.glb is the only GLB on disk; all active models point to it for demo.
        // Real GLB files should be uploaded per-model via admin CMS.
        $modelCpu = ArModel::create([
            'model_name' => 'Microprocessor CPU 3D',
            'glb_path' => 'models/wireless_router.glb',
            'thumbnail_path' => 'thumbnails/cpu_thumb.png',
            'description' => 'Model interaktif 3D prosesor komputer dengan arsitektur multi-core dan pin socket.',
            'category' => 'Hardware Komputer',
            'is_active' => true,
        ]);

        $modelRouter = ArModel::create([
            'model_name' => 'Wireless Router Dual-Band',
            'glb_path' => 'models/wireless_router.glb',
            'thumbnail_path' => 'thumbnails/router_thumb.png',
            'description' => 'Model 3D perangkat router jaringan dengan antena eksternal dan port RJ-45.',
            'category' => 'Jaringan Komputer',
            'is_active' => true,
        ]);

        $modelRam = ArModel::create([
            'model_name' => 'RAM DDR5 Module 3D',
            'glb_path' => 'models/wireless_router.glb',
            'thumbnail_path' => null,
            'description' => 'Model interaktif 3D modul memori DDR5 dengan komponen IC dan pin connector.',
            'category' => 'Hardware Komputer',
            'is_active' => true,
        ]);

        $modelKeyboard = ArModel::create([
            'model_name' => 'Mechanical Keyboard 3D',
            'glb_path' => 'models/wireless_router.glb',
            'thumbnail_path' => null,
            'description' => 'Model 3D keyboard mekanikal dengan switch, keycap, dan PCB.',
            'category' => 'Hardware Komputer',
            'is_active' => true,
        ]);

        // === 2b. AR MARKERS ===
        // DICT_4X4_50: ar_uco_id 0 → MARKER-CPU-001
        $marker1 = ArMarker::create([
            'marker_id' => 'MARKER-CPU-001',
            'ar_uco_id' => 0,
            'aruco_dictionary' => 'DICT_4X4_50',
            'marker_type' => 'pattern',
            'image_path' => 'markers/marker_cpu.png',
            'status' => 'active',
        ]);

        // DICT_4X4_50: ar_uco_id 1 → MARKER-RAM-001
        $marker2 = ArMarker::create([
            'marker_id' => 'MARKER-RAM-001',
            'ar_uco_id' => 1,
            'aruco_dictionary' => 'DICT_4X4_50',
            'marker_type' => 'pattern',
            'image_path' => 'markers/marker_ram.png',
            'status' => 'active',
        ]);

        // DICT_4X4_50: ar_uco_id 2 → MARKER-KEYBOARD-001
        $marker3 = ArMarker::create([
            'marker_id' => 'MARKER-KEYBOARD-001',
            'ar_uco_id' => 2,
            'aruco_dictionary' => 'DICT_4X4_50',
            'marker_type' => 'pattern',
            'image_path' => 'markers/marker_keyboard.png',
            'status' => 'active',
        ]);

        // DICT_4X4_50: ar_uco_id 3 → MARKER-ROUTER-001
        $marker4 = ArMarker::create([
            'marker_id' => 'MARKER-ROUTER-001',
            'ar_uco_id' => 3,
            'aruco_dictionary' => 'DICT_4X4_50',
            'marker_type' => 'pattern',
            'image_path' => 'markers/marker_router.png',
            'status' => 'active',
        ]);

        $marker1->models()->attach($modelCpu->id);
        $marker2->models()->attach($modelRam->id);
        $marker3->models()->attach($modelKeyboard->id);
        $marker4->models()->attach($modelRouter->id);

        // === 2c. AR HOTSPOTS ===
        ArHotspot::create([
            'ar_model_id' => $modelCpu->id,
            'title' => 'ALU (Arithmetic Logic Unit)',
            'description' => 'Unit yang melakukan operasi matematika dan logika: penjumlahan, pengurangan, AND, OR, NOT.',
            'latitude' => 0.02,
            'longitude' => 0.01,
            'image_path' => 'hotspots/cpu_alu.png',
            'is_active' => true,
        ]);

        ArHotspot::create([
            'ar_model_id' => $modelCpu->id,
            'title' => 'Control Unit',
            'description' => 'Mengarahkan aliran data dan instruksi antar komponen CPU dan memori.',
            'latitude' => -0.01,
            'longitude' => 0.02,
            'image_path' => 'hotspots/cpu_cu.png',
            'is_active' => true,
        ]);

        ArHotspot::create([
            'ar_model_id' => $modelCpu->id,
            'title' => 'Register',
            'description' => 'Memori internal berkecepatan tinggi di dalam CPU untuk menyimpan data sementara.',
            'latitude' => 0.01,
            'longitude' => -0.02,
            'image_path' => 'hotspots/cpu_register.png',
            'is_active' => true,
        ]);

        ArHotspot::create([
            'ar_model_id' => $modelRouter->id,
            'title' => 'WAN Port (RJ-45)',
            'description' => 'Port koneksi ke modem ISP untuk menerima sinyal internet dari provider.',
            'latitude' => 0.03,
            'longitude' => 0.0,
            'image_path' => 'hotspots/router_wan.png',
            'is_active' => true,
        ]);

        ArHotspot::create([
            'ar_model_id' => $modelRouter->id,
            'title' => 'LAN Ports',
            'description' => 'Port koneksi lokal untuk perangkat kabel seperti PC, printer, dan switch.',
            'latitude' => -0.02,
            'longitude' => 0.01,
            'image_path' => 'hotspots/router_lan.png',
            'is_active' => true,
        ]);

        ArHotspot::create([
            'ar_model_id' => $modelRouter->id,
            'title' => 'Antena Dual-Band',
            'description' => 'Memitarkan sinyal WiFi pada frekuensi 2.4 GHz dan 5 GHz untuk koneksi nirkabel.',
            'latitude' => 0.0,
            'longitude' => 0.03,
            'image_path' => 'hotspots/router_antena.png',
            'is_active' => true,
        ]);

        // === 2d. AR HOTSPOTS (RAM & Keyboard) ===
        ArHotspot::create([
            'ar_model_id' => $modelRam->id,
            'title' => 'DRAM Chips',
            'description' => 'Chip memori volatile yang menyimpan data sementara untuk akses cepat oleh CPU.',
            'latitude' => 0.01,
            'longitude' => 0.01,
            'image_path' => 'hotspots/ram_chips.png',
            'is_active' => true,
        ]);

        ArHotspot::create([
            'ar_model_id' => $modelRam->id,
            'title' => 'Pin Connector',
            'description' => 'Pin emas pada modul RAM yang terhubung ke slot DIMM pada motherboard.',
            'latitude' => -0.01,
            'longitude' => -0.01,
            'image_path' => 'hotspots/ram_pins.png',
            'is_active' => true,
        ]);

        ArHotspot::create([
            'ar_model_id' => $modelKeyboard->id,
            'title' => 'Mechanical Switch',
            'description' => 'Switch mekanikal pada keyboard yang memberikan umpan balik taktil dan auditory saat ditekan.',
            'latitude' => 0.02,
            'longitude' => 0.0,
            'image_path' => 'hotspots/keyboard_switch.png',
            'is_active' => true,
        ]);

        ArHotspot::create([
            'ar_model_id' => $modelKeyboard->id,
            'title' => 'Keycap Profile',
            'description' => 'Profil keycap yang dirancang ergonomis untuk kenyamanan mengetik jangka panjang.',
            'latitude' => -0.01,
            'longitude' => 0.02,
            'image_path' => 'hotspots/keyboard_keycap.png',
            'is_active' => true,
        ]);

        // === 3. TP / ATP (Kurikulum Merdeka Informatika - Fase E) ===
        $tp1 = TpAtp::create([
            'kode' => 'TP-SK-01',
            'fase' => 'E',
            'elemen' => 'Sistem Komputer',
            'judul' => 'Arsitektur Komputer dan Komponen Perangkat Keras',
            'deskripsi' => 'Memahami cara kerja sistem komputer, arsitektur Von Neumann, dan fungsi komponen perangkat keras internal.',
            'order' => 1,
            'is_active' => true,
        ]);

        $tp2 = TpAtp::create([
            'kode' => 'TP-JKI-02',
            'fase' => 'E',
            'elemen' => 'Jaringan Komputer dan Internet',
            'judul' => 'Jaringan Komputer dan Protokol Komunikasi Data',
            'deskripsi' => 'Menganalisis prinsip kerja jaringan komputer, topologi, model lapisan OSI, dan protokol TCP/IP.',
            'order' => 2,
            'is_active' => true,
        ]);

        $tp3 = TpAtp::create([
            'kode' => 'TP-AP-03',
            'fase' => 'E',
            'elemen' => 'Algoritma dan Pemrograman',
            'judul' => 'Berpikir Komputasional dan Struktur Data',
            'deskripsi' => 'Menerapkan konsep algoritma, notasi logika terstruktur, serta pengelolaan data menggunakan array, stack, dan queue.',
            'order' => 3,
            'is_active' => true,
        ]);

        // === 4. MATERI PEMBELAJARAN ===
        // Materi untuk TP 1
        $materiCpu = Materi::create([
            'tp_atp_id' => $tp1->id,
            'ar_model_id' => $modelCpu->id,
            'judul' => 'Unit Pemrosesan Sentral (CPU) dan Siklus Instruksi',
            'slug' => 'unit-pemrosesan-sentral-cpu-dan-siklus-instruksi',
            'ringkasan' => 'Pelajari komponen inti CPU: ALU, Control Unit, dan Register beserta siklus Fetch-Decode-Execute.',
            'konten' => "## Pengenalan CPU\n\nCentral Processing Unit (CPU) sering disebut sebagai 'otak' dari komputer. CPU bertugas memproses instruksi-instruksi yang diberikan oleh perangkat lunak dan mengkoordinasikan kerja seluruh komponen sistem.\n\n### Komponen Utama CPU\n1. **Arithmetic Logic Unit (ALU):** Melakukan seluruh operasi matematika (+, -, *, /) dan logika (AND, OR, NOT).\n2. **Control Unit (CU):** Mengarahkan lalu lintas data dan instruksi antar komponen komputer.\n3. **Register:** Memori internal berkecepatan tinggi yang menyimpan data sementara selama pemrosesan.\n\n### Siklus Fetch-Decode-Execute\nSetiap instruksi komputer dieksekusi melalui 3 langkah berulang:\n- **Fetch:** Mengambil instruksi dari memori utama (RAM).\n- **Decode:** Menerjemahkan maksud kode instruksi oleh Control Unit.\n- **Execute:** Menjalankan operasi komputasi melalui ALU.",
            'gambar_cover' => null,
            'estimasi_menit' => 20,
            'order' => 1,
            'is_published' => true,
        ]);

        Materi::create([
            'tp_atp_id' => $tp1->id,
            'ar_model_id' => null,
            'judul' => 'Hierarki Memori Komputer: Cache, RAM, dan Secondary Storage',
            'slug' => 'hierarki-memori-komputer',
            'ringkasan' => 'Memahami perbandingan kecepatan, kapasitas, dan biaya berbagai tingkat memori dalam sistem komputer.',
            'konten' => "## Hierarki Memori\n\nSistem memori komputer dirancang bertingkat berdasarkan kecepatan akses, kapasitas, dan biaya produksi per byte.\n\n### Tingkatan Memori:\n1. **Register:** Tercepat, berada di dalam CPU, kapasitas sangat kecil.\n2. **Cache Memory (L1, L2, L3):** Memori jembatan ultra cepat antara CPU dan RAM.\n3. **Main Memory (RAM):** Memori volatil tempat program yang sedang berjalan dimuat.\n4. **Secondary Storage (SSD/NVMe/HDD):** Memori non-volatil untuk menyimpan data permanen.",
            'gambar_cover' => null,
            'estimasi_menit' => 15,
            'order' => 2,
            'is_published' => true,
        ]);

        // Materi untuk TP 2
        $materiNetwork = Materi::create([
            'tp_atp_id' => $tp2->id,
            'ar_model_id' => $modelRouter->id,
            'judul' => 'Topologi Jaringan dan Perangkat Keras Penghubung',
            'slug' => 'topologi-jaringan-dan-perangkat-keras',
            'ringkasan' => 'Pelajari perbedaan topologi Star, Mesh, Ring, serta peran Switch dan Router dalam transmisi paket data.',
            'konten' => "## Topologi Jaringan\n\nTopologi jaringan adalah susunan fisik atau logis dari node/komputer yang saling terhubung dalam sebuah jaringan.\n\n### Jenis Topologi Populer:\n- **Topologi Star:** Semua node terhubung ke satu konsentrator pusat (Switch/Hub). Mudah dikelola dan jika satu kabel putus tidak mematikan seluruh jaringan.\n- **Topologi Mesh:** Setiap perangkat memiliki koneksi redundan ke beberapa perangkat lain. Sangat toleran terhadap kegagalan (fault tolerance tinggi).\n\n### Perangkat Penghubung:\n- **Switch:** Bekerja pada Data Link Layer (Layer 2) menggunakan MAC Address untuk mengarahkan frame data.\n- **Router:** Bekerja pada Network Layer (Layer 3) menggunakan IP Address untuk merutekan paket antar segmen jaringan yang berbeda.",
            'gambar_cover' => null,
            'estimasi_menit' => 25,
            'order' => 1,
            'is_published' => true,
        ]);

        // Materi untuk TP 3
        $materiAlgo = Materi::create([
            'tp_atp_id' => $tp3->id,
            'ar_model_id' => null,
            'judul' => 'Struktur Data Dasar: Stack (LIFO) dan Queue (FIFO)',
            'slug' => 'struktur-data-stack-dan-queue',
            'ringkasan' => 'Konsep tumpukan dan antrean beserta implementasi operasi push, pop, enqueue, dan dequeue.',
            'konten' => "## Stack vs Queue\n\nDalam komputasi, cara data disimpan menentukan efisiensi akses dan manipulasi data tersebut.\n\n### 1. Stack (Tumpukan)\nMenganut prinsip **LIFO (Last In, First Out)** — elemen yang terakhir masuk adalah yang pertama keluar.\n- Operasi: `push()` (menambah), `pop()` (mengambil), `peek()` (melihat puncak).\n- Contoh nyata: Riwayat tombol Back pada browser, fitur Undo (Ctrl+Z).\n\n### 2. Queue (Antrean)\nMenganut prinsip **FIFO (First In, First Out)** — elemen yang pertama kali masuk adalah yang pertama keluar.\n- Operasi: `enqueue()` (masuk antrean), `dequeue()` (keluar antrean).\n- Contoh nyata: Antrean cetak printer (print spooler), pemrosesan antrean pesan/job.",
            'gambar_cover' => null,
            'estimasi_menit' => 20,
            'order' => 1,
            'is_published' => true,
        ]);

        // === 5. QUIZZES (Terkait materi di atas) ===
        $quiz1 = Quiz::create([
            'title' => 'Algoritma dan Pemrograman Dasar',
            'description' => 'Quiz tentang konsep dasar algoritma dan pemrograman',
            'time_limit' => 10,
            'passing_score' => 70,
        ]);

        $q1 = Question::create([
            'quiz_id' => $quiz1->id,
            'text' => 'Apa itu algoritma?',
            'order' => 1,
        ]);
        QuestionOption::create(['question_id' => $q1->id, 'text' => 'Bahasa pemrograman', 'is_correct' => false, 'order' => 1]);
        QuestionOption::create(['question_id' => $q1->id, 'text' => 'Urutan langkah-langkah penyelesaian masalah', 'is_correct' => true, 'order' => 2]);
        QuestionOption::create(['question_id' => $q1->id, 'text' => 'Jenis komputer', 'is_correct' => false, 'order' => 3]);
        QuestionOption::create(['question_id' => $q1->id, 'text' => 'Perangkat lunak', 'is_correct' => false, 'order' => 4]);

        $q2 = Question::create([
            'quiz_id' => $quiz1->id,
            'text' => 'Struktur data yang menggunakan prinsip LIFO adalah...',
            'order' => 2,
        ]);
        QuestionOption::create(['question_id' => $q2->id, 'text' => 'Queue', 'is_correct' => false, 'order' => 1]);
        QuestionOption::create(['question_id' => $q2->id, 'text' => 'Stack', 'is_correct' => true, 'order' => 2]);
        QuestionOption::create(['question_id' => $q2->id, 'text' => 'Array', 'is_correct' => false, 'order' => 3]);
        QuestionOption::create(['question_id' => $q2->id, 'text' => 'Linked List', 'is_correct' => false, 'order' => 4]);

        $q3 = Question::create([
            'quiz_id' => $quiz1->id,
            'text' => 'Manakah yang merupakan bahasa pemrograman?',
            'order' => 3,
        ]);
        QuestionOption::create(['question_id' => $q3->id, 'text' => 'HTML', 'is_correct' => false, 'order' => 1]);
        QuestionOption::create(['question_id' => $q3->id, 'text' => 'CSS', 'is_correct' => false, 'order' => 2]);
        QuestionOption::create(['question_id' => $q3->id, 'text' => 'Python', 'is_correct' => true, 'order' => 3]);
        QuestionOption::create(['question_id' => $q3->id, 'text' => 'SQL', 'is_correct' => false, 'order' => 4]);

        $quiz2 = Quiz::create([
            'title' => 'Jaringan Komputer',
            'description' => 'Quiz tentang konsep dasar jaringan komputer',
            'time_limit' => 10,
            'passing_score' => 70,
        ]);

        $q4 = Question::create([
            'quiz_id' => $quiz2->id,
            'text' => 'Apa kepanjangan dari LAN?',
            'order' => 1,
        ]);
        QuestionOption::create(['question_id' => $q4->id, 'text' => 'Local Area Network', 'is_correct' => true, 'order' => 1]);
        QuestionOption::create(['question_id' => $q4->id, 'text' => 'Large Area Network', 'is_correct' => false, 'order' => 2]);
        QuestionOption::create(['question_id' => $q4->id, 'text' => 'Long Area Network', 'is_correct' => false, 'order' => 3]);
        QuestionOption::create(['question_id' => $q4->id, 'text' => 'Light Area Network', 'is_correct' => false, 'order' => 4]);

        $q5 = Question::create([
            'quiz_id' => $quiz2->id,
            'text' => 'Protokol untuk mengirim email adalah...',
            'order' => 2,
        ]);
        QuestionOption::create(['question_id' => $q5->id, 'text' => 'FTP', 'is_correct' => false, 'order' => 1]);
        QuestionOption::create(['question_id' => $q5->id, 'text' => 'SMTP', 'is_correct' => true, 'order' => 2]);
        QuestionOption::create(['question_id' => $q5->id, 'text' => 'HTTP', 'is_correct' => false, 'order' => 3]);
        QuestionOption::create(['question_id' => $q5->id, 'text' => 'SSH', 'is_correct' => false, 'order' => 4]);

        $quiz3 = Quiz::create([
            'title' => 'Basis Data Dasar',
            'description' => 'Quiz tentang konsep dasar basis data dan SQL',
            'time_limit' => 15,
            'passing_score' => 75,
        ]);

        $q6 = Question::create([
            'quiz_id' => $quiz3->id,
            'text' => 'Apa singkatan dari SQL?',
            'order' => 1,
        ]);
        QuestionOption::create(['question_id' => $q6->id, 'text' => 'Structured Query Language', 'is_correct' => true, 'order' => 1]);
        QuestionOption::create(['question_id' => $q6->id, 'text' => 'Simple Query Language', 'is_correct' => false, 'order' => 2]);
        QuestionOption::create(['question_id' => $q6->id, 'text' => 'Standard Query Logic', 'is_correct' => false, 'order' => 3]);
        QuestionOption::create(['question_id' => $q6->id, 'text' => 'System Query Language', 'is_correct' => false, 'order' => 4]);

        // === 6. LINK QUIZ TO MATERI ===
        $materiAlgo->update(['quiz_id' => $quiz1->id]);
        $materiNetwork->update(['quiz_id' => $quiz2->id]);
    }
}
