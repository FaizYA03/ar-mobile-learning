<?php

namespace Tests\Feature;

use App\Models\Quiz;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminQuizAttemptsWebTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_guest_redirected_from_quiz_attempts(): void
    {
        $this->get('/admin/quiz-attempts')->assertRedirect();
    }

    public function test_siswa_forbidden_from_quiz_attempts(): void
    {
        $this->actingAs(User::where('role', 'siswa')->first());
        $this->get('/admin/quiz-attempts')->assertStatus(403);
    }

    public function test_admin_can_view_quiz_attempts(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());
        $this->get('/admin/quiz-attempts')
            ->assertStatus(200)
            ->assertSee('Hasil Quiz Siswa');
    }

    public function test_admin_can_filter_quiz_attempts_by_quiz(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());
        $quiz = Quiz::first();
        $this->get("/admin/quiz-attempts?quiz_id={$quiz->id}")
            ->assertStatus(200)
            ->assertSee($quiz->title);
    }
}
