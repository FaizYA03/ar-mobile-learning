<?php

namespace App\Http\Controllers;

use App\Http\Traits\ApiResponse;
use App\Models\User;
use App\Models\QuizAttempt;
use App\Services\ActivityLogger;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AdminController extends Controller
{
    use ApiResponse;

    public function users(Request $request)
    {
        $query = User::select('id', 'name', 'email', 'role', 'created_at')
            ->orderBy('created_at', 'desc');

        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->filled('role')) {
            $validated = $request->validate([
                'role' => 'in:admin,guru,siswa',
            ]);
            $query->where('role', $validated['role']);
        }

        if ($perPage = $this->requestedPerPage($request)) {
            return $this->paginatedResponse(
                $query->paginate($perPage),
                'Berhasil mengambil daftar user'
            );
        }

        $users = $query->get();

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }

    public function storeUser(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'role' => 'required|in:admin,guru,siswa',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);
        // Role hanya boleh ditentukan server (endpoint ini di balik role:admin).
        $user->forceFill(['role' => $validated['role']])->save();

        ActivityLogger::created('user', $user->id, "User '{$user->name}' ({$user->role}) created");

        return response()->json([
            'success' => true,
            'message' => 'User berhasil ditambahkan',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ], 201);
    }

    public function updateUser(Request $request, User $user)
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $user->id,
            'password' => 'nullable|string|min:6',
            'role' => 'sometimes|in:admin,guru,siswa',
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        $role = $validated['role'] ?? null;
        unset($validated['role']);

        $user->update($validated);
        if ($role !== null) {
            // Role hanya boleh ditentukan server (endpoint ini di balik role:admin).
            $user->forceFill(['role' => $role])->save();
        }

        ActivityLogger::updated('user', $user->id, "User '{$user->name}' updated");

        return response()->json([
            'success' => true,
            'message' => 'User berhasil diperbarui',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ]);
    }

    public function deleteUser(User $user)
    {
        ActivityLogger::deleted('user', $user->id, "User '{$user->name}' deleted");
        if ($user->avatar) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($user->avatar);
        }
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dihapus',
        ]);
    }

    public function quizAttempts(Request $request)
    {
        $query = QuizAttempt::with(['user:id,name,email', 'quiz:id,title,passing_score'])
            ->orderBy('created_at', 'desc');

        if ($perPage = $this->requestedPerPage($request)) {
            return $this->paginatedResponse(
                $query->paginate($perPage),
                'Berhasil mengambil hasil quiz'
            );
        }

        $attempts = $query->get();

        return response()->json([
            'success' => true,
            'data' => $attempts,
        ]);
    }
}