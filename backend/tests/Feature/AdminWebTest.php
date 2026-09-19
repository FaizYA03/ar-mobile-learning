<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminWebTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_guest_redirected_to_login(): void
    {
        $response = $this->get('/admin/dashboard');
        $response->assertRedirect();
    }

    public function test_siswa_forbidden_from_admin(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        $this->actingAs($siswa);

        $response = $this->get('/admin/dashboard');
        $response->assertStatus(403);
    }

    public function test_guru_forbidden_from_admin(): void
    {
        $guru = User::where('role', 'guru')->first();
        $this->actingAs($guru);

        $response = $this->get('/admin/dashboard');
        $response->assertStatus(403);
    }

    public function test_admin_can_access_dashboard(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/dashboard');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_users(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/users');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_tp_atp(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/tp-atp');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_materi(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/materi');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_quiz(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/quiz');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_ar_models(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/ar/models');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_ar_markers(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/ar/markers');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_activity_logs(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/activity-logs');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_system_settings(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/system/settings');
        $response->assertStatus(200);
    }

    public function test_admin_can_access_system_versions(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin);

        $response = $this->get('/admin/system/versions');
        $response->assertStatus(200);
    }

    public function test_admin_login_page_works(): void
    {
        $response = $this->get('/login');
        $response->assertStatus(200);
    }

    public function test_admin_login_with_valid_credentials(): void
    {
        $admin = User::where('role', 'admin')->first();

        $response = $this->post('/login', [
            'email' => $admin->email,
            'password' => 'password',
        ]);

        $response->assertRedirect(route('admin.dashboard'));
    }

    public function test_admin_login_with_invalid_credentials(): void
    {
        $response = $this->post('/login', [
            'email' => 'admin@demo.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertSessionHasErrors('email');
    }

    public function test_non_admin_cannot_login_to_admin(): void
    {
        $siswa = User::where('role', 'siswa')->first();

        $response = $this->post('/login', [
            'email' => $siswa->email,
            'password' => 'password',
        ]);

        $response->assertSessionHasErrors('email');
    }
}
