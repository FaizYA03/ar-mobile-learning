<?php

namespace App\Http\Controllers;

use App\Http\Requests\QuestionStoreRequest;
use App\Http\Requests\QuizStoreRequest;
use App\Http\Requests\QuizSubmitRequest;
use App\Http\Requests\QuizUpdateRequest;
use App\Http\Resources\QuizAttemptResource;
use App\Http\Resources\QuizResource;
use App\Models\Question;
use App\Models\QuestionOption;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class QuizController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $quizzes = Quiz::withCount('questions')->get();

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil daftar quiz',
            'data' => QuizResource::collection($quizzes),
        ]);
    }

    public function show(Quiz $quiz, Request $request): JsonResponse
    {
        $quiz->load('questions.options');

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil detail quiz',
            'data' => new QuizResource($quiz),
        ]);
    }

    public function submit(QuizSubmitRequest $request, Quiz $quiz): JsonResponse
    {
        $validated = $request->validated();

        $quizQuestionIds = $quiz->questions()->pluck('questions.id')->toArray();

        foreach ($validated['answers'] as $answer) {
            if (!in_array($answer['question_id'], $quizQuestionIds)) {
                return response()->json([
                    'success' => false,
                    'message' => "Soal #{$answer['question_id']} bukan bagian dari quiz ini.",
                ], 422);
            }

            $optionBelongsToQuestion = QuestionOption::where('id', $answer['option_id'])
                ->where('question_id', $answer['question_id'])
                ->exists();

            if (!$optionBelongsToQuestion) {
                return response()->json([
                    'success' => false,
                    'message' => "Jawaban #{$answer['option_id']} tidak valid untuk soal #{$answer['question_id']}.",
                ], 422);
            }
        }

        $correctCount = 0;
        $totalCount = $quiz->questions()->count();

        foreach ($validated['answers'] as $answer) {
            $option = QuestionOption::find($answer['option_id']);
            if ($option && $option->is_correct) {
                $correctCount++;
            }
        }

        $score = $totalCount > 0 ? round(($correctCount / $totalCount) * 100) : 0;
        $passed = $score >= ($quiz->passing_score ?? 70);

        $attempt = QuizAttempt::create([
            'user_id' => $request->user()->id,
            'quiz_id' => $quiz->id,
            'score' => $score,
            'passed' => $passed,
        ]);

        ActivityLogger::created('quiz_attempt', $attempt->id, "Quiz '{$quiz->title}' attempted by user #{$request->user()->id} with score {$score}");

        return response()->json([
            'success' => true,
            'message' => $passed ? 'Selamat! Kamu lulus quiz ini.' : 'Quiz selesai. Semoga lebih baik next time!',
            'data' => [
                'attempt_id' => $attempt->id,
                'score' => $score,
                'correct' => $correctCount,
                'total' => $totalCount,
                'passed' => $passed,
            ],
        ]);
    }

    // Guru methods
    public function guruIndex(): JsonResponse
    {
        $quizzes = Quiz::withCount('questions')->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil daftar quiz guru',
            'data' => QuizResource::collection($quizzes),
        ]);
    }

    public function guruStore(QuizStoreRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $quiz = Quiz::create($validated);

        ActivityLogger::created('quiz', $quiz->id, "Quiz '{$quiz->title}' created");

        return response()->json([
            'success' => true,
            'message' => 'Quiz berhasil dibuat',
            'data' => new QuizResource($quiz),
        ], 201);
    }

    public function guruUpdate(QuizUpdateRequest $request, Quiz $quiz): JsonResponse
    {
        $quiz->update($request->validated());

        ActivityLogger::updated('quiz', $quiz->id, "Quiz '{$quiz->title}' updated");

        return response()->json([
            'success' => true,
            'message' => 'Quiz berhasil diperbarui',
            'data' => new QuizResource($quiz),
        ]);
    }

    public function guruDestroy(Quiz $quiz): JsonResponse
    {
        ActivityLogger::deleted('quiz', $quiz->id, "Quiz '{$quiz->title}' deleted");
        $quiz->delete();

        return response()->json([
            'success' => true,
            'message' => 'Quiz berhasil dihapus',
        ]);
    }

    public function addQuestion(QuestionStoreRequest $request, Quiz $quiz): JsonResponse
    {
        $validated = $request->validated();

        $maxOrder = $quiz->questions()->max('order') ?? 0;

        $question = Question::create([
            'quiz_id' => $quiz->id,
            'text' => $validated['text'],
            'order' => $maxOrder + 1,
        ]);

        foreach ($validated['options'] as $index => $option) {
            QuestionOption::create([
                'question_id' => $question->id,
                'text' => $option['text'],
                'is_correct' => $option['is_correct'],
                'order' => $index + 1,
            ]);
        }

        $question->load('options');

        ActivityLogger::created('quiz_question', $question->id, "Question added to quiz '{$quiz->title}'");

        return response()->json([
            'success' => true,
            'message' => 'Soal berhasil ditambahkan',
            'data' => $question,
        ], 201);
    }

    public function deleteQuestion(Question $question): JsonResponse
    {
        $quiz = $question->quiz;
        $question->delete();

        ActivityLogger::deleted('quiz_question', $question->id, "Question deleted from quiz '{$quiz->title}'");

        return response()->json([
            'success' => true,
            'message' => 'Soal berhasil dihapus',
        ]);
    }

    public function attempts(Quiz $quiz, Request $request): JsonResponse
    {
        $attempts = QuizAttempt::where('user_id', $request->user()->id)
            ->where('quiz_id', $quiz->id)
            ->orderBy('created_at', 'desc')
            ->get();

        $bestScore = $attempts->max('score');
        $passed = $attempts->where('passed', true)->isNotEmpty();

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil riwayat quiz',
            'data' => [
                'quiz_id' => $quiz->id,
                'quiz_title' => $quiz->title,
                'total_attempts' => $attempts->count(),
                'best_score' => $bestScore,
                'passed' => $passed,
                'attempts' => QuizAttemptResource::collection($attempts),
            ],
        ]);
    }
}
