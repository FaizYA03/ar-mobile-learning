<?php

namespace Tests\Feature;

use App\Models\Materi;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrphanMediaTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_deleting_user_removes_avatar_file(): void
    {
        Storage::fake('public');
        $admin = User::where('role', 'admin')->first();
        $siswa = User::where('role', 'siswa')->first();

        Sanctum::actingAs($siswa);
        $this->post('/api/user/avatar', [
            'avatar' => UploadedFile::fake()->image('ava.jpg', 100, 100),
        ], ['Accept' => 'application/json'])->assertStatus(200);

        $avatar = $siswa->fresh()->avatar;
        Storage::disk('public')->assertExists($avatar);

        Sanctum::actingAs($admin);
        $this->deleteJson("/api/admin/users/{$siswa->id}")->assertStatus(200);
        Storage::disk('public')->assertMissing($avatar);
    }

    public function test_clean_orphans_dry_run_lists_only_unreferenced(): void
    {
        Storage::fake('public');

        // File terreferensi: cover materi pertama.
        $materi = Materi::first();
        $referenced = 'covers/keep.jpg';
        Storage::disk('public')->put($referenced, 'data');
        $materi->forceFill(['gambar_cover' => $referenced])->save();

        // File yatim.
        Storage::disk('public')->put('covers/orphan.jpg', 'data');
        Storage::disk('public')->put('models/orphan.glb', 'data');

        $this->artisan('media:clean-orphans')
            ->expectsOutputToContain('covers/orphan.jpg')
            ->expectsOutputToContain('models/orphan.glb')
            ->assertSuccessful();

        // Dry-run: tidak ada yang terhapus.
        Storage::disk('public')->assertExists('covers/orphan.jpg');
        Storage::disk('public')->assertExists('models/orphan.glb');
    }

    public function test_clean_orphans_force_deletes_and_keeps_referenced(): void
    {
        Storage::fake('public');

        $materi = Materi::first();
        $referenced = 'covers/keep.jpg';
        Storage::disk('public')->put($referenced, 'data');
        $materi->forceFill(['gambar_cover' => $referenced])->save();

        Storage::disk('public')->put('covers/orphan.jpg', 'data');

        $this->artisan('media:clean-orphans', ['--force' => true])->assertSuccessful();

        Storage::disk('public')->assertMissing('covers/orphan.jpg');
        Storage::disk('public')->assertExists($referenced);
    }
}
