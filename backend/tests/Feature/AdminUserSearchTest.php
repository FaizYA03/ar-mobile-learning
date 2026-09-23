<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminUserSearchTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_admin_can_search_users_by_name(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/users?search=Andi');
        $response->assertStatus(200)->assertJson(['success' => true]);

        $names = collect($response->json('data'))->pluck('name')->all();
        $this->assertNotEmpty($names);
        foreach ($names as $name) {
            $this->assertStringContainsStringIgnoringCase('Andi', $name);
        }
    }

    public function test_admin_can_search_users_by_email(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/users?search=guru@demo.com');
        $response->assertStatus(200);

        $emails = collect($response->json('data'))->pluck('email')->all();
        $this->assertContains('guru@demo.com', $emails);
    }

    public function test_admin_can_filter_users_by_role(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/users?role=guru');
        $response->assertStatus(200);

        $roles = collect($response->json('data'))->pluck('role')->unique()->all();
        $this->assertSame(['guru'], $roles);
    }

    public function test_admin_users_rejects_invalid_role(): void
    {
        $admin = User::where('role', 'admin')->first();
        Sanctum::actingAs($admin);

        $this->getJson('/api/admin/users?role=superadmin')->assertStatus(422);
    }

    public function test_siswa_cannot_search_users(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $this->getJson('/api/admin/users?search=Andi')->assertStatus(403);
    }
}
