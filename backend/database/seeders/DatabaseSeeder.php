<?php

namespace Database\Seeders;

use App\Models\Question;
use App\Models\QuestionOption;
use App\Models\Quiz;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // === USERS ===
        $admin = User::create([
            'name' => 'Admin Utama',
            'email' => 'admin@demo.com',
            'password' => Hash::make('password'),
            'role' => 'admin',
        ]);

        $guru = User::create([
            'name' => 'Budi Santoso',
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

        // === QUIZ: Algoritma dan Pemrograman ===
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

        // === QUIZ: Jaringan Komputer ===
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

        // === QUIZ: Basis Data ===
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
    }
}