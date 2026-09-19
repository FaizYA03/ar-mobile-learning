<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Question;
use App\Models\QuestionOption;
use App\Models\Quiz;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    public function index(Request $request)
    {
        $query = Quiz::withCount('questions');

        if ($request->filled('search')) {
            $query->where('title', 'like', "%{$request->search}%");
        }

        $quizzes = $query->orderByDesc('created_at')->paginate(15)->withQueryString();
        return view('admin.quiz.index', compact('quizzes'));
    }

    public function create()
    {
        return view('admin.quiz.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'time_limit' => 'nullable|integer|min:1',
            'passing_score' => 'nullable|integer|min:0|max:100',
        ]);

        $quiz = Quiz::create($validated);

        \App\Services\ActivityLogger::created('quiz', $quiz->id, "Quiz '{$quiz->title}' created via admin");

        return redirect()->route('admin.quiz.index')->with('success', 'Quiz berhasil ditambahkan.');
    }

    public function edit(Quiz $quiz)
    {
        $quiz->load('questions.options');
        return view('admin.quiz.edit', compact('quiz'));
    }

    public function update(Request $request, Quiz $quiz)
    {
        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'time_limit' => 'nullable|integer|min:1',
            'passing_score' => 'nullable|integer|min:0|max:100',
        ]);

        $quiz->update($validated);

        \App\Services\ActivityLogger::updated('quiz', $quiz->id, "Quiz '{$quiz->title}' updated via admin");

        return redirect()->route('admin.quiz.index')->with('success', 'Quiz berhasil diperbarui.');
    }

    public function destroy(Quiz $quiz)
    {
        \App\Services\ActivityLogger::deleted('quiz', $quiz->id, "Quiz '{$quiz->title}' deleted via admin");
        $quiz->delete();

        return redirect()->route('admin.quiz.index')->with('success', 'Quiz berhasil dihapus.');
    }

    public function questions(Quiz $quiz)
    {
        $quiz->load('questions.options');
        return view('admin.quiz.questions', compact('quiz'));
    }

    public function storeQuestion(Request $request, Quiz $quiz)
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

        \App\Services\ActivityLogger::created('quiz_question', $question->id, "Question added to quiz '{$quiz->title}'");

        return redirect()->route('admin.quiz.questions', $quiz)->with('success', 'Soal berhasil ditambahkan.');
    }

    public function deleteQuestion(Question $question)
    {
        $quiz = $question->quiz;
        $question->delete();

        \App\Services\ActivityLogger::deleted('quiz_question', $question->id, "Question deleted from quiz '{$quiz->title}'");

        return redirect()->route('admin.quiz.questions', $quiz)->with('success', 'Soal berhasil dihapus.');
    }
}
