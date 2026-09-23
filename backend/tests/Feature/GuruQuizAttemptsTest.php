<?php

namespace Tests\Feature;

use App\Models\Quiz;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GuruQuizAttemptsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_guru_can_list_all_quiz_attempts(): void
    {
        $guru = User::where('role', 'guru')->first();
        $siswa = User::where('role', 'siswa')->first();
        $quiz = Quiz::with('questions.options')->first();

        // Siswa mengerjakan satu quiz agar ada data attempt.
        $answers = [];
        foreach ($quiz->questions as $question) {
            $answers[] = [
                'question_id' => $question->id,
                'option_id' => $question->options->first()->id,
            ];
        }
        Sanctum::actingAs($siswa);
        $this->postJson("/api/quizzes/{$quiz->id}/submit", ['answers' => $answers])
            ->assertStatus(200);

        Sanctum::actingAs($guru);
        $response = $this->getJson('/api/guru/quiz-attempts');
        $response->assertStatus(200)->assertJson(['success' => true]);
        $this->assertNotEmpty($response->json('data'));
    }

    public function test_guru_can_filter_attempts_by_quiz(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $quiz = Quiz::first();
        $response = $this->getJson("/api/guru/quiz-attempts?quiz_id={$quiz->id}");
        $response->assertStatus(200)->assertJson(['success' => true]);

        foreach ($response->json('data') as $attempt) {
            $this->assertSame($quiz->id, $attempt['quiz_id']);
        }
    }

    public function test_guru_attempts_filter_rejects_unknown_quiz(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $this->getJson('/api/guru/quiz-attempts?quiz_id=999999')->assertStatus(422);
    }

    public function test_siswa_cannot_access_guru_attempts(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $this->getJson('/api/guru/quiz-attempts')->assertStatus(403);
    }

    public function test_list_supports_opt_in_pagination(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        // Tanpa per_page: format legacy tanpa meta.
        $legacy = $this->getJson('/api/materi');
        $legacy->assertStatus(200)->assertJsonMissing(['meta']);

        // Dengan per_page: envelope paginasi konsisten.
        $paged = $this->getJson('/api/materi?per_page=2');
        $paged->assertStatus(200)
            ->assertJsonStructure(['success', 'data', 'meta' => ['current_page', 'last_page', 'per_page', 'total']])
            ->assertJson(['meta' => ['per_page' => 2]]);

        // Validasi batas per_page.
        $this->getJson('/api/materi?per_page=500')->assertStatus(422);
    }

    public function test_guru_attempts_supports_pagination(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $this->getJson('/api/admin/quiz-attempts?per_page=1')
            ->assertStatus(200)
            ->assertJsonStructure(['success', 'data', 'meta' => ['total']]);
    }
}
