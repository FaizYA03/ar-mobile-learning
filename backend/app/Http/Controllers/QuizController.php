<?php

namespace App\Http\Controllers;

use App\Models\Quiz;
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
            $option = \App\Models\QuestionOption::find($answer['option_id']);
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
}