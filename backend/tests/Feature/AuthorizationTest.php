<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthorizationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_siswa_cannot_access_admin_users(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $response = $this->getJson('/api/admin/users');
        $response->assertStatus(403);
    }

    public function test_siswa_cannot_create_quiz(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $response = $this->postJson('/api/guru/quizzes', [
            'title' => 'Unauthorized Quiz',
        ]);
        $response->assertStatus(403);
    }

    public function test_siswa_cannot_create_tp_atp(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $response = $this->postJson('/api/guru/tp-atp', [
            'kode' => 'TP-UNAUTH',
            'fase' => 'E',
            'elemen' => 'Test',
            'judul' => 'Unauthorized TP',
        ]);
        $response->assertStatus(403);
    }

    public function test_siswa_cannot_create_materi(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $response = $this->postJson('/api/guru/materi', [
            'judul' => 'Unauthorized Materi',
            'konten' => 'Test',
        ]);
        $response->assertStatus(403);
    }

    public function test_siswa_cannot_create_ar_model(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $response = $this->postJson('/api/ar/models', [
            'model_name' => 'Unauthorized Model',
        ]);
        $response->assertStatus(403);
    }

    public function test_guru_cannot_access_admin_users(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $response = $this->getJson('/api/admin/users');
        $response->assertStatus(403);
    }

    public function test_admin_can_access_admin_users(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/users');
        $response->assertStatus(200)
            ->assertJson(['success' => true]);
    }

    public function test_unauthenticated_user_cannot_access_protected_routes(): void
    {
        $response = $this->getJson('/api/dashboard');
        $response->assertStatus(401);
    }

    public function test_guru_can_create_quiz(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $response = $this->postJson('/api/guru/quizzes', [
            'title' => 'Guru Quiz',
            'description' => 'Created by guru',
        ]);
        $response->assertStatus(201);
    }

    public function test_admin_can_create_user(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/admin/users', [
            'name' => 'New User',
            'email' => 'new@test.com',
            'password' => 'password',
            'role' => 'siswa',
        ]);
        $response->assertStatus(201);
    }
}
