<?php

namespace Tests\Feature;

use App\Models\Question;
use App\Models\Quiz;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Pembuatan soal (API guru/admin) wajib menyertakan tepat satu kunci jawaban,
 * agar setiap soal selalu bisa dinilai dan skor siswa bisa mencapai 100.
 */
class QuestionStoreValidationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    private function guru(): User
    {
        return User::where('role', 'guru')->first();
    }

    private function quiz(): Quiz
    {
        return Quiz::first();
    }

    private function payload(array $flags): array
    {
        $options = [];

        foreach ($flags as $index => $isCorrect) {
            $options[] = [
                'text' => 'Opsi '.($index + 1),
                'is_correct' => $isCorrect,
            ];
        }

        return [
            'text' => 'Soal baru?',
            'options' => $options,
        ];
    }

    public function test_guru_can_create_question_with_exactly_one_correct_option(): void
    {
        Sanctum::actingAs($this->guru());

        $quiz = $this->quiz();
        $before = $quiz->questions()->count();

        $response = $this->postJson(
            "/api/guru/quizzes/{$quiz->id}/questions",
            $this->payload([true, false, false, false])
        );

        $response->assertStatus(201)->assertJson(['success' => true]);

        $this->assertSame($before + 1, $quiz->questions()->count());

        $question = Question::latest('id')->first();
        $this->assertSame($quiz->id, $question->quiz_id);
        $this->assertSame(1, $question->options()->where('is_correct', true)->count());
    }

    public function test_question_without_correct_answer_is_rejected(): void
    {
        Sanctum::actingAs($this->guru());

        $response = $this->postJson(
            "/api/guru/quizzes/{$this->quiz()->id}/questions",
            $this->payload([false, false, false, false])
        );

        $response->assertStatus(422);
        $this->assertArrayHasKey('options', $response->json('errors'));
    }

    public function test_question_with_multiple_correct_answers_is_rejected(): void
    {
        Sanctum::actingAs($this->guru());

        $response = $this->postJson(
            "/api/guru/quizzes/{$this->quiz()->id}/questions",
            $this->payload([true, true, false, false])
        );

        $response->assertStatus(422);
        $this->assertArrayHasKey('options', $response->json('errors'));
    }

    public function test_question_and_option_can_store_at_validation_limits(): void
    {
        Sanctum::actingAs($this->guru());

        $questionText = str_repeat('S', 1000);
        $optionText = str_repeat('O', 500);

        $response = $this->postJson(
            "/api/guru/quizzes/{$this->quiz()->id}/questions",
            [
                'text' => $questionText,
                'options' => [
                    ['text' => $optionText, 'is_correct' => true],
                    ['text' => 'Opsi pendek', 'is_correct' => false],
                ],
            ]
        );

        $response->assertStatus(201);

        $question = Question::latest('id')->first();
        $this->assertSame($questionText, $question->text);
        $this->assertSame(
            $optionText,
            $question->options()->where('is_correct', true)->first()->text
        );
    }

    public function test_question_with_more_than_ten_options_is_rejected(): void
    {
        Sanctum::actingAs($this->guru());

        $flags = array_fill(0, 11, false);
        $flags[0] = true;

        $response = $this->postJson(
            "/api/guru/quizzes/{$this->quiz()->id}/questions",
            $this->payload($flags)
        );

        $response->assertStatus(422);
        $this->assertArrayHasKey('options', $response->json('errors'));
    }
}
