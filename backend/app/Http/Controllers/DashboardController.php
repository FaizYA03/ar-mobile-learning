<?php

namespace App\Http\Controllers;

use App\Models\ArModel;
use App\Models\Materi;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\User;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        return match ($user->role) {
            'admin' => $this->adminDashboard(),
            'guru' => $this->guruDashboard($user),
            'siswa' => $this->siswaDashboard($user),
            default => response()->json([
                'success' => false,
                'message' => 'Role tidak dikenali',
            ], 400),
        };
    }

    private function adminDashboard()
    {
        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'total_users' => User::count(),
                    'total_guru' => User::where('role', 'guru')->count(),
                    'total_siswa' => User::where('role', 'siswa')->count(),
                    'total_quizzes' => Quiz::count(),
                ],
            ],
        ]);
    }

    private function guruDashboard($user)
    {
        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'total_quizzes' => Quiz::count(),
                    'total_materi' => Materi::count(),
                    'total_ar_models' => ArModel::count(),
                ],
            ],
        ]);
    }

    private function siswaDashboard($user)
    {
        $totalMateri = Materi::where('is_published', true)->count();
        $totalArModels = ArModel::where('is_active', true)->count();
        $totalQuizzes = Quiz::count();

        $quizAttempts = QuizAttempt::where('user_id', $user->id)->count();
        $quizzesPassed = QuizAttempt::where('user_id', $user->id)
            ->where('passed', true)
            ->distinct('quiz_id')
            ->count('quiz_id');

        $totalArModelsAvailable = ArModel::where('is_active', true)
            ->whereHas('markers', function ($q) {
                $q->where('status', 'active');
            })->count();

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'name' => $user->name,
                    'role' => $user->role,
                ],
                'stats' => [
                    'total_materi' => $totalMateri,
                    'total_ar_models' => $totalArModelsAvailable,
                    'total_quizzes' => $totalQuizzes,
                    'quiz_attempts' => $quizAttempts,
                    'quizzes_passed' => $quizzesPassed,
                ],
            ],
        ]);
    }

    public function adminUsers()
    {
        $users = User::select('id', 'name', 'email', 'role', 'created_at')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }
}