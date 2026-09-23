<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_guest_cannot_update_profile(): void
    {
        $this->putJson('/api/user/profile', ['name' => 'Baru'])->assertStatus(401);
        $this->putJson('/api/user/password', [
            'current_password' => 'password',
            'password' => 'baru123',
            'password_confirmation' => 'baru123',
        ])->assertStatus(401);
    }

    public function test_user_can_update_own_name(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $response = $this->putJson('/api/user/profile', ['name' => 'Andi Updated']);
        $response->assertStatus(200)->assertJson([
            'success' => true,
            'data' => ['name' => 'Andi Updated', 'email' => $siswa->email],
        ]);

        $this->assertDatabaseHas('users', ['id' => $siswa->id, 'name' => 'Andi Updated']);
    }

    public function test_update_profile_fails_without_name(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $this->putJson('/api/user/profile', ['name' => ''])->assertStatus(422);
    }

    public function test_update_profile_ignores_role_escalation(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        // Client mencoba menaikkan role via endpoint profil — harus diabaikan.
        $this->putJson('/api/user/profile', ['name' => 'Andi', 'role' => 'admin'])
            ->assertStatus(200);

        $this->assertSame('siswa', $siswa->fresh()->role);
    }

    public function test_user_can_change_password_with_correct_current(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $this->putJson('/api/user/password', [
            'current_password' => 'password',
            'password' => 'baru1234',
            'password_confirmation' => 'baru1234',
        ])->assertStatus(200)->assertJson(['success' => true]);

        $this->assertTrue(Hash::check('baru1234', $siswa->fresh()->password));
    }

    public function test_change_password_fails_with_wrong_current(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $this->putJson('/api/user/password', [
            'current_password' => 'salah',
            'password' => 'baru1234',
            'password_confirmation' => 'baru1234',
        ])->assertStatus(422);

        $this->assertTrue(Hash::check('password', $siswa->fresh()->password));
    }

    public function test_user_can_upload_avatar(): void
    {
        Storage::fake('public');
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $file = UploadedFile::fake()->image('avatar.jpg', 200, 200);

        $response = $this->post('/api/user/avatar', ['avatar' => $file]);
        $response->assertStatus(200)->assertJson(['success' => true]);

        $avatar = $siswa->fresh()->avatar;
        $this->assertNotNull($avatar);
        Storage::disk('public')->assertExists($avatar);
        $this->assertNotNull($response->json('data.avatar_url'));
    }

    public function test_upload_avatar_rejects_non_image(): void
    {
        Storage::fake('public');
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $file = UploadedFile::fake()->create('dokumen.pdf', 100, 'application/pdf');

        $this->post('/api/user/avatar', ['avatar' => $file], ['Accept' => 'application/json'])
            ->assertStatus(422);
        $this->assertNull($siswa->fresh()->avatar);
    }
}
