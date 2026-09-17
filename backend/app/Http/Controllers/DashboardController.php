<?php

namespace App\Http\Controllers;

use App\Models\Quiz;
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
                ],
            ],
        ]);
    }

    private function siswaDashboard($user)
    {
        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'name' => $user->name,
                    'role' => $user->role,
                ],
                'stats' => [
                    'total_quizzes' => Quiz::count(),
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