<?php

namespace Tests\Feature;

use App\Models\Question;
use App\Models\Quiz;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Form "Tambah Soal" di Admin CMS.
 *
 * Dua regresi yang dijaga di sini:
 * 1. Script Alpine questionForm() harus ikut ter-render (layout punya @stack('scripts'))
 *    sehingga daftar opsi benar-benar muncul di halaman.
 * 2. is_correct harus ikut terkirim untuk SEMUA opsi (hidden input), dan hanya
 *    boleh ada tepat satu opsi yang bernilai benar.
 */
class AdminQuizQuestionCmsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    private function actingAsAdmin(): User
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        return $admin;
    }

    private function quiz(): Quiz
    {
        return Quiz::first();
    }

    public function test_questions_page_renders_alpine_form_and_option_inputs(): void
    {
        $this->actingAsAdmin();

        $response = $this->get("/admin/quiz/{$this->quiz()->id}/questions");

        $response->assertStatus(200)
            // Bug A: fungsi x-data harus ter-render oleh @stack('scripts').
            ->assertSee('function questionForm()', false)
            ->assertSee('markCorrect(index)', false)
            // Bug B: setiap opsi harus membawa is_correct (hidden input).
            ->assertSee('type="hidden"', false)
            ->assertSee('[is_correct]', false);
    }

    public function test_admin_can_store_question_with_single_correct_answer(): void
    {
        $this->actingAsAdmin();

        $quiz = $this->quiz();
        $before = $quiz->questions()->count();

        $response = $this->post("/admin/quiz/{$quiz->id}/questions", [
            'text' => 'Soal dari CMS?',
            'options' => [
                ['text' => 'Jawaban A', 'is_correct' => '1'],
                ['text' => 'Jawaban B', 'is_correct' => '0'],
                ['text' => 'Jawaban C', 'is_correct' => '0'],
                ['text' => 'Jawaban D', 'is_correct' => '0'],
            ],
        ]);

        $response->assertRedirect(route('admin.quiz.questions', $quiz));
        $response->assertSessionHas('success');

        $this->assertSame($before + 1, $quiz->questions()->count());

        $question = Question::latest('id')->first();
        $this->assertSame('Soal dari CMS?', $question->text);
        $this->assertSame(4, $question->options()->count());
        $this->assertSame(1, $question->options()->where('is_correct', true)->count());
        $this->assertSame('Jawaban A', $question->options()->where('is_correct', true)->first()->text);
    }

    public function test_store_question_without_correct_answer_is_rejected(): void
    {
        $this->actingAsAdmin();

        $quiz = $this->quiz();

        $response = $this->post("/admin/quiz/{$quiz->id}/questions", [
            'text' => 'Tanpa kunci jawaban?',
            'options' => [
                ['text' => 'Jawaban A', 'is_correct' => '0'],
                ['text' => 'Jawaban B', 'is_correct' => '0'],
            ],
        ]);

        $response->assertSessionHasErrors('options');
        $this->assertFalse(
            Question::where('text', 'Tanpa kunci jawaban?')->exists(),
            'Soal tanpa kunci jawaban tidak boleh tersimpan.'
        );
    }

    public function test_store_question_with_multiple_correct_answers_is_rejected(): void
    {
        $this->actingAsAdmin();

        $quiz = $this->quiz();

        $response = $this->post("/admin/quiz/{$quiz->id}/questions", [
            'text' => 'Dua kunci jawaban?',
            'options' => [
                ['text' => 'Jawaban A', 'is_correct' => '1'],
                ['text' => 'Jawaban B', 'is_correct' => '1'],
                ['text' => 'Jawaban C', 'is_correct' => '0'],
            ],
        ]);

        $response->assertSessionHasErrors('options');
        $this->assertFalse(Question::where('text', 'Dua kunci jawaban?')->exists());
    }

    public function test_store_question_without_options_is_rejected(): void
    {
        $this->actingAsAdmin();

        $response = $this->post("/admin/quiz/{$this->quiz()->id}/questions", [
            'text' => 'Tanpa opsi?',
        ]);

        $response->assertSessionHasErrors('options');
        $this->assertFalse(Question::where('text', 'Tanpa opsi?')->exists());
    }
}
