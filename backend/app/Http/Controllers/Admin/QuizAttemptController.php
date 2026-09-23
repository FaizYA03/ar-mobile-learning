<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use Illuminate\Http\Request;

class QuizAttemptController extends Controller
{
    public function index(Request $request)
    {
        $query = QuizAttempt::with(['user:id,name,email', 'quiz:id,title,passing_score']);

        if ($request->filled('quiz_id')) {
            $query->where('quiz_id', $request->quiz_id);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $statsQuery = clone $query;
        $total = (clone $statsQuery)->count();
        $passed = (clone $statsQuery)->where('passed', true)->count();
        $avgScore = $total > 0 ? round((clone $statsQuery)->avg('score')) : 0;

        $attempts = $query->orderByDesc('created_at')->paginate(20)->withQueryString();
        $quizzes = Quiz::select('id', 'title')->orderBy('title')->get();

        return view('admin.quiz.attempts', compact('attempts', 'quizzes', 'total', 'passed', 'avgScore'));
    }
}
