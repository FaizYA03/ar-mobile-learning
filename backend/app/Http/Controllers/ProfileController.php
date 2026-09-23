<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdatePasswordRequest;
use App\Http\Requests\UpdateProfileRequest;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class ProfileController extends Controller
{
    private function profilePayload($user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'avatar' => $user->avatar,
            'avatar_url' => $user->avatar ? Storage::disk('public')->url($user->avatar) : null,
        ];
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->name = $request->validated()['name'];
        $user->save();

        ActivityLogger::updated('user', $user->id, "Profil '{$user->name}' diperbarui");

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui',
            'data' => $this->profilePayload($user),
        ]);
    }

    public function updatePassword(UpdatePasswordRequest $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validated();

        if (!Hash::check($validated['current_password'], $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Password saat ini salah.'],
            ]);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        ActivityLogger::updated('user', $user->id, "Password '{$user->name}' diubah");

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah',
        ]);
    }

    public function uploadAvatar(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'avatar' => 'required|image|mimes:jpg,jpeg,png,webp|max:2048',
        ], [
            'avatar.required' => 'File avatar wajib diisi',
            'avatar.image' => 'File harus berupa gambar',
            'avatar.mimes' => 'Format gambar harus jpg, jpeg, png, atau webp',
            'avatar.max' => 'Ukuran gambar maksimal 2MB',
        ]);

        $user = $request->user();

        if ($user->avatar) {
            Storage::disk('public')->delete($user->avatar);
        }

        /** @var \Illuminate\Http\UploadedFile $file */
        $file = $validated['avatar'];
        $user->avatar = $file->store('avatars', 'public');
        $user->save();

        ActivityLogger::updated('user', $user->id, "Avatar '{$user->name}' diperbarui");

        return response()->json([
            'success' => true,
            'message' => 'Avatar berhasil diperbarui',
            'data' => $this->profilePayload($user),
        ]);
    }
}
