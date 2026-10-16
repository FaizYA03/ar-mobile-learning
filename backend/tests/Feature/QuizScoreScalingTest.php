<?php

namespace Tests\Feature;

use App\Models\Question;
use App\Models\QuestionOption;
use App\Models\Quiz;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Penilaian quiz harus konsisten terhadap JUMLAH SOAL:
 * skor = round(benar / total_soal * 100).
 *
 * 10, 15, ataupun 20 soal -> semua benar tetap 100.
 * Soal yang tidak dijawab tetap dihitung dalam total.
 */
class QuizScoreScalingTest extends TestCase
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

    private function createQuiz(int $questionCount): Quiz
    {
        $quiz = Quiz::create([
            'title' => "Quiz {$questionCount} Soal",
            'description' => 'Digunakan untuk menguji konsistensi penilaian.',
            'time_limit' => 30,
            'passing_score' => 70,
        ]);

        for ($i = 1; $i <= $questionCount; $i++) {
            $question = Question::create([
                'quiz_id' => $quiz->id,
                'text' => "Soal #{$i}",
                'order' => $i,
            ]);

            foreach (range(1, 4) as $optionNumber) {
                QuestionOption::create([
                    'question_id' => $question->id,
                    'text' => "Opsi {$optionNumber}",
                    'is_correct' => $optionNumber === 1,
                    'order' => $optionNumber,
                ]);
            }
        }

        return $quiz->load('questions.options');
    }

    private function allCorrectAnswers(Quiz $quiz): array
    {
        return $quiz->questions->map(fn ($question) => [
            'question_id' => $question->id,
            'option_id' => $question->options->firstWhere('is_correct', true)->id,
        ])->values()->all();
    }

    private function submit(Quiz $quiz, array $answers)
    {
        return $this->postJson("/api/quizzes/{$quiz->id}/submit", [
            'answers' => $answers,
        ]);
    }

    public function test_ten_questions_all_correct_is_exactly_100(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->createQuiz(10);

        $response = $this->submit($quiz, $this->allCorrectAnswers($quiz));

        $response->assertStatus(200);
        $this->assertSame(10, $response->json('data.total'));
        $this->assertSame(10, $response->json('data.correct'));
        $this->assertSame(100, $response->json('data.score'));
        $this->assertTrue($response->json('data.passed'));
    }

    public function test_fifteen_questions_all_correct_is_exactly_100(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->createQuiz(15);

        $response = $this->submit($quiz, $this->allCorrectAnswers($quiz));

        $response->assertStatus(200);
        $this->assertSame(15, $response->json('data.total'));
        $this->assertSame(15, $response->json('data.correct'));
        $this->assertSame(100, $response->json('data.score'));
    }

    public function test_twenty_questions_all_correct_is_exactly_100(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->createQuiz(20);

        $response = $this->submit($quiz, $this->allCorrectAnswers($quiz));

        $response->assertStatus(200);
        $this->assertSame(20, $response->json('data.total'));
        $this->assertSame(20, $response->json('data.correct'));
        $this->assertSame(100, $response->json('data.score'));
    }

    public function test_partial_score_is_percentage_of_total_questions(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->createQuiz(15);

        $answers = $quiz->questions->take(10)->map(fn ($question) => [
            'question_id' => $question->id,
            'option_id' => $question->options->firstWhere('is_correct', true)->id,
        ])->values()->all();

        $response = $this->submit($quiz, $answers);

        $response->assertStatus(200);
        $this->assertSame(15, $response->json('data.total'), 'Total harus jumlah soal quiz, bukan jumlah jawaban.');
        $this->assertSame(10, $response->json('data.correct'));
        $this->assertSame((int) round((10 / 15) * 100), $response->json('data.score'));
        $this->assertFalse($response->json('data.passed'), 'Nilai 67 dengan KKM 70 tidak boleh dinyatakan lulus.');
    }

    public function test_unanswered_questions_are_counted_in_the_total(): void
    {
        Sanctum::actingAs($this->siswa());

        $quiz = $this->createQuiz(20);

        // Hanya 13 soal dijawab, semuanya benar.
        $answers = $quiz->questions->take(13)->map(fn ($question) => [
            'question_id' => $question->id,
            'option_id' => $question->options->firstWhere('is_correct', true)->id,
        ])->values()->all();

        $response = $this->submit($quiz, $answers);

        $response->assertStatus(200);
        $this->assertSame(20, $response->json('data.total'));
        $this->assertSame(13, $response->json('data.correct'));
        $this->assertSame((int) round((13 / 20) * 100), $response->json('data.score'));
        $this->assertLessThan(100, $response->json('data.score'));
    }

    public function test_score_never_exceeds_100_for_any_question_count(): void
    {
        Sanctum::actingAs($this->siswa());

        foreach ([10, 15, 20] as $count) {
            $quiz = $this->createQuiz($count);

            $response = $this->submit($quiz, $this->allCorrectAnswers($quiz));

            $response->assertStatus(200);
            $this->assertSame(100, $response->json('data.score'));
            $this->assertLessThanOrEqual(100, $response->json('data.score'));
        }
    }
}
