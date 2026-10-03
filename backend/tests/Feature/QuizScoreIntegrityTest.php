<?php

namespace Tests\Feature;

use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class QuizScoreIntegrityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    private function siswa(): User
    {
        return User::where('role', 'siswa')->first();
    }

    private function quizWithQuestions(): Quiz
    {
        $quiz = Quiz::with('questions.options')->first();

        if ($quiz->questions->isEmpty()) {
            $this->markTestSkipped('Seed tidak menyediakan soal untuk quiz.');
        }

        return $quiz;
    }

    private function correctOptionFor($question)
    {
        return $question->options->firstWhere('is_correct', true);
    }

    private function wrongOptionFor($question)
    {
        return $question->options->firstWhere('is_correct', false);
    }

    public function test_duplicate_question_id_is_rejected(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->quizWithQuestions();
        $question = $quiz->questions->first();
        $correct = $this->correctOptionFor($question) ?? $question->options->first();

        $response = $this->postJson("/api/quizzes/{$quiz->id}/submit", [
            'answers' => [
                ['question_id' => $question->id, 'option_id' => $correct->id],
                ['question_id' => $question->id, 'option_id' => $correct->id],
            ],
        ]);

        $response->assertStatus(422);
        $this->assertIsArray($response->json('errors'));
        $this->assertNotEmpty(
            collect(array_keys($response->json('errors')))
                ->filter(fn ($key) => str_ends_with($key, 'question_id'))
                ->all(),
            'Harus ada error validasi pada question_id yang duplikat.'
        );
    }

    public function test_repeating_one_correct_answer_cannot_inflate_score(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->quizWithQuestions();
        $question = $quiz->questions->first();
        $correct = $this->correctOptionFor($question) ?? $question->options->first();

        $answers = array_fill(0, 100, [
            'question_id' => $question->id,
            'option_id' => $correct->id,
        ]);

        $response = $this->postJson("/api/quizzes/{$quiz->id}/submit", [
            'answers' => $answers,
        ]);

        $this->assertSame(422, $response->status());

        $attempt = QuizAttempt::where('user_id', $this->siswa()->id)
            ->where('quiz_id', $quiz->id)
            ->latest('id')
            ->first();

        if ($attempt) {
            $this->assertLessThanOrEqual(100, $attempt->score);
        }
    }

    public function test_all_correct_answers_scores_exactly_100(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->quizWithQuestions();

        $answers = [];
        foreach ($quiz->questions as $question) {
            $option = $this->correctOptionFor($question) ?? $question->options->first();
            $answers[] = ['question_id' => $question->id, 'option_id' => $option->id];
        }

        $response = $this->postJson("/api/quizzes/{$quiz->id}/submit", [
            'answers' => $answers,
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $this->assertLessThanOrEqual(100, $response->json('data.score'));
        $this->assertSame(
            $quiz->questions->count(),
            $response->json('data.correct')
        );
    }

    public function test_score_is_computed_from_quiz_questions_only(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->quizWithQuestions();
        $questions = $quiz->questions->values();

        $answers = [];
        foreach ($questions as $index => $question) {
            if ($index === 0) {
                continue;
            }

            $correct = $this->correctOptionFor($question);
            $wrong = $this->wrongOptionFor($question);

            $option = $index % 2 === 0 ? ($correct ?? $wrong) : $wrong;
            if ($option) {
                $answers[] = ['question_id' => $question->id, 'option_id' => $option->id];
            }
        }

        $response = $this->postJson("/api/quizzes/{$quiz->id}/submit", [
            'answers' => $answers,
        ]);

        $response->assertStatus(200);

        $correct = $response->json('data.correct');
        $total = $response->json('data.total');

        $this->assertSame($questions->count(), $total);
        $this->assertLessThanOrEqual($total, $correct);
        $this->assertLessThanOrEqual(100, $response->json('data.score'));
    }

    public function test_answering_only_one_question_does_not_count_as_full_score(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->quizWithQuestions();

        if ($quiz->questions->count() < 2) {
            $this->markTestSkipped('Butuh minimal 2 soal.');
        }

        $question = $quiz->questions->first();
        $correct = $this->correctOptionFor($question) ?? $question->options->first();

        $response = $this->postJson("/api/quizzes/{$quiz->id}/submit", [
            'answers' => [
                ['question_id' => $question->id, 'option_id' => $correct->id],
            ],
        ]);

        $response->assertStatus(200);

        $total = $response->json('data.total');
        $score = $response->json('data.score');

        $this->assertSame(1, $response->json('data.correct'));
        $this->assertLessThan(100, $score, 'Satu jawaban benar tidak boleh menghasilkan nilai 100.');
        $this->assertSame((int) round((1 / $total) * 100), $score);
    }

    public function test_stored_attempt_score_is_never_above_100(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->quizWithQuestions();

        $answers = [];
        foreach ($quiz->questions as $question) {
            $correct = $this->correctOptionFor($question) ?? $question->options->first();
            $answers[] = ['question_id' => $question->id, 'option_id' => $correct->id];
        }

        $this->postJson("/api/quizzes/{$quiz->id}/submit", ['answers' => $answers])
            ->assertStatus(200);

        $attempt = QuizAttempt::where('quiz_id', $quiz->id)
            ->where('user_id', $this->siswa()->id)
            ->latest('id')
            ->first();

        $this->assertNotNull($attempt);
        $this->assertLessThanOrEqual(100, $attempt->score);
        $this->assertSame(100, $attempt->score);
    }
}
