<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ApiErrorEnvelopeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_unauthenticated_api_response_has_error_envelope(): void
    {
        $this->getJson('/api/dashboard')
            ->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthenticated.',
            ]);
    }

    public function test_forbidden_api_response_has_error_envelope(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $this->getJson('/api/admin/users')
            ->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_missing_resource_has_error_envelope(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $this->getJson('/api/quizzes/999999')
            ->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Data tidak ditemukan.',
            ]);
    }

    public function test_validation_error_has_error_envelope(): void
    {
        $this->postJson('/api/login', [])
            ->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed',
            ])
            ->assertJsonValidationErrors(['email', 'password']);
    }

    public function test_admin_login_is_rate_limited(): void
    {
        for ($attempt = 1; $attempt <= 10; $attempt++) {
            $this->post('/login', [
                'email' => 'admin@demo.com',
                'password' => 'salah',
            ])->assertStatus(302);
        }

        $this->post('/login', [
            'email' => 'admin@demo.com',
            'password' => 'salah',
        ])->assertStatus(429);
    }
}
