<?php

namespace Tests\Feature;

use App\Models\Question;
use App\Models\QuestionOption;
use App\Models\Quiz;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class QuizSecurityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_student_cannot_see_correct_answer_before_submission(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $quiz = Quiz::with('questions.options')->first();
        $response = $this->getJson("/api/quizzes/{$quiz->id}");

        $response->assertStatus(200);

        $data = $response->json('data');
        foreach ($data['questions'] as $question) {
            foreach ($question['options'] as $option) {
                $this->assertArrayNotHasKey('is_correct', $option, 'Student should not see is_correct field');
                $this->assertArrayHasKey('id', $option);
                $this->assertArrayHasKey('text', $option);
            }
        }
    }

    public function test_admin_can_see_correct_answer(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $quiz = Quiz::with('questions.options')->first();
        $response = $this->getJson("/api/quizzes/{$quiz->id}");

        $response->assertStatus(200);

        $data = $response->json('data');
        foreach ($data['questions'] as $question) {
            foreach ($question['options'] as $option) {
                $this->assertArrayHasKey('is_correct', $option, 'Admin should see is_correct field');
            }
        }
    }

    public function test_guru_can_see_correct_answer(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $quiz = Quiz::with('questions.options')->first();
        $response = $this->getJson("/api/quizzes/{$quiz->id}");

        $response->assertStatus(200);

        $data = $response->json('data');
        foreach ($data['questions'] as $question) {
            foreach ($question['options'] as $option) {
                $this->assertArrayHasKey('is_correct', $option, 'Guru should see is_correct field');
            }
        }
    }

    public function test_student_cannot_submit_question_from_another_quiz(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $quizzes = Quiz::with('questions')->get();
        $quiz1 = $quizzes->first();
        $quiz2 = $quizzes->last();

        if ($quiz1->id === $quiz2->id || $quiz2->questions->isEmpty()) {
            $this->markTestSkipped('Need at least 2 quizzes with questions');
        }

        $foreignQuestion = $quiz2->questions->first();
        $option = QuestionOption::where('question_id', $foreignQuestion->id)->first();

        $response = $this->postJson("/api/quizzes/{$quiz1->id}/submit", [
            'answers' => [
                ['question_id' => $foreignQuestion->id, 'option_id' => $option->id],
            ],
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_valid_quiz_submission_works(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $quiz = Quiz::with('questions.options')->first();
        $answers = [];

        foreach ($quiz->questions as $question) {
            $option = $question->options->first();
            $answers[] = [
                'question_id' => $question->id,
                'option_id' => $option->id,
            ];
        }

        $response = $this->postJson("/api/quizzes/{$quiz->id}/submit", [
            'answers' => $answers,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'data' => ['attempt_id', 'score', 'correct', 'total', 'passed'],
            ]);
    }

    public function test_create_quiz_fails_without_title(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $response = $this->postJson('/api/guru/quizzes', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['title']);
    }

    public function test_create_quiz_fails_with_invalid_passing_score(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $response = $this->postJson('/api/guru/quizzes', [
            'title' => 'Quiz Test',
            'passing_score' => 150,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['passing_score']);
    }

    public function test_add_question_fails_without_options(): void
    {
        $guru = User::where('role', 'guru')->first();
        $quiz = Quiz::first();
        Sanctum::actingAs($guru);

        $response = $this->postJson("/api/guru/quizzes/{$quiz->id}/questions", [
            'text' => 'Soal tanpa opsi',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['options']);
    }

    public function test_submit_quiz_fails_without_answers(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        $quiz = Quiz::first();
        Sanctum::actingAs($siswa);

        $response = $this->postJson("/api/quizzes/{$quiz->id}/submit", []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['answers']);
    }
}
