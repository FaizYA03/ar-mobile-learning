<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\ArMarker;
use App\Models\ArModel;
use App\Models\Materi;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\TpAtp;
use App\Models\User;

class DashboardController extends Controller
{
    public function index()
    {
        $stats = [
            'total_users' => User::count(),
            'total_siswa' => User::where('role', 'siswa')->count(),
            'total_guru' => User::where('role', 'guru')->count(),
            'total_admin' => User::where('role', 'admin')->count(),
            'total_tp_atp' => TpAtp::count(),
            'total_materi' => Materi::count(),
            'total_quiz' => Quiz::count(),
            'total_quiz_attempts' => QuizAttempt::count(),
            'total_ar_models' => ArModel::count(),
            'total_ar_markers' => ArMarker::count(),
        ];

        $recentActivity = ActivityLog::with('user:id,name,email')
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        $storageExists = is_dir(storage_path('app/public'));

        $dbOk = true;
        try {
            \Illuminate\Support\Facades\DB::connection()->getPdo();
        } catch (\Exception $e) {
            $dbOk = false;
        }

        return view('admin.dashboard', compact('stats', 'recentActivity', 'storageExists', 'dbOk'));
    }
}
