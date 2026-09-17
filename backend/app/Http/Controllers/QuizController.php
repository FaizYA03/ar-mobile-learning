<?php

namespace App\Http\Controllers;

use App\Models\Quiz;
use App\Models\Question;
use App\Models\QuestionOption;
use App\Models\QuizAttempt;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    public function index()
    {
        $quizzes = Quiz::withCount('questions')->get();

        return response()->json([
            'success' => true,
            'data' => $quizzes,
        ]);
    }

    public function show(Quiz $quiz)
    {
        $quiz->load('questions.options');

        return response()->json([
            'success' => true,
            'data' => $quiz,
        ]);
    }

    public function submit(Request $request, Quiz $quiz)
    {
        $validated = $request->validate([
            'answers' => 'required|array',
            'answers.*.question_id' => 'required|exists:questions,id',
            'answers.*.option_id' => 'required|exists:question_options,id',
        ]);

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

        return response()->json([
            'success' => true,
            'message' => 'Quiz selesai',
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
    public function guruIndex()
    {
        $quizzes = Quiz::withCount('questions')->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $quizzes,
        ]);
    }

    public function guruStore(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'time_limit' => 'nullable|integer|min:1',
            'passing_score' => 'nullable|integer|min:0|max:100',
        ]);

        $quiz = Quiz::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Quiz berhasil dibuat',
            'data' => $quiz,
        ], 201);
    }

    public function guruUpdate(Request $request, Quiz $quiz)
    {
        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'time_limit' => 'nullable|integer|min:1',
            'passing_score' => 'nullable|integer|min:0|max:100',
        ]);

        $quiz->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Quiz berhasil diperbarui',
            'data' => $quiz,
        ]);
    }

    public function guruDestroy(Quiz $quiz)
    {
        $quiz->delete();

        return response()->json([
            'success' => true,
            'message' => 'Quiz berhasil dihapus',
        ]);
    }

    public function addQuestion(Request $request, Quiz $quiz)
    {
        $validated = $request->validate([
            'text' => 'required|string',
            'options' => 'required|array|min:2',
            'options.*.text' => 'required|string',
            'options.*.is_correct' => 'required|boolean',
        ]);

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

        return response()->json([
            'success' => true,
            'message' => 'Soal berhasil ditambahkan',
            'data' => $question,
        ], 201);
    }

    public function deleteQuestion(Question $question)
    {
        $question->delete();

        return response()->json([
            'success' => true,
            'message' => 'Soal berhasil dihapus',
        ]);
    }
}