<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminClearCacheTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_guest_cannot_clear_cache(): void
    {
        $this->post('/admin/system/clear-cache')->assertRedirect();
    }

    public function test_siswa_forbidden_from_clear_cache(): void
    {
        $this->actingAs(User::where('role', 'siswa')->first());
        $this->post('/admin/system/clear-cache')->assertStatus(403);
    }

    public function test_admin_can_clear_cache(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());
        $this->post('/admin/system/clear-cache')
            ->assertRedirect(route('admin.system.settings'))
            ->assertSessionHas('success');
    }

    public function test_settings_page_shows_clear_cache_button(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());
        $this->get('/admin/system/settings')
            ->assertStatus(200)
            ->assertSee('Bersihkan Cache');
    }
}
