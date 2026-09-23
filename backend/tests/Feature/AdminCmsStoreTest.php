<?php

namespace Tests\Feature;

use App\Models\TpAtp;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Regresi: store CMS pernah 500 karena ActivityLogger::created()
 * dipanggil dengan entity id null (TypeError). Semua store harus 302.
 */
class AdminCmsStoreTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    private function asAdmin(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());
    }

    public function test_admin_can_store_app_version(): void
    {
        $this->asAdmin();
        $this->post('/admin/system/versions', [
            'platform' => 'android',
            'version' => '1.0.0',
            'build_number' => '1',
            'minimum_supported_version' => '1.0.0',
            'release_notes' => 'Rilis pertama',
            'download_url' => 'https://download.arlearning.my.id/',
        ])->assertRedirect();

        $this->assertDatabaseHas('app_versions', ['version' => '1.0.0']);
    }

    public function test_admin_can_store_user(): void
    {
        $this->asAdmin();
        $this->post('/admin/users', [
            'name' => 'Guru Baru',
            'email' => 'gurubaru@demo.com',
            'password' => 'password',
            'password_confirmation' => 'password',
            'role' => 'guru',
        ])->assertRedirect();

        $this->assertDatabaseHas('users', ['email' => 'gurubaru@demo.com']);
    }

    public function test_admin_can_store_tp_atp(): void
    {
        $this->asAdmin();
        $this->post('/admin/tp-atp', [
            'kode' => 'TP-TEST',
            'fase' => 'E',
            'elemen' => 'Test',
            'judul' => 'TP Test',
        ])->assertRedirect();

        $this->assertDatabaseHas('tp_atp', ['kode' => 'TP-TEST']);
    }

    public function test_admin_can_store_materi(): void
    {
        $this->asAdmin();
        $tpAtp = TpAtp::first();
        $this->post('/admin/materi', [
            'tp_atp_id' => $tpAtp->id,
            'judul' => 'Materi Test',
            'ringkasan' => 'Ringkasan',
            'konten' => 'Konten test',
        ])->assertRedirect();

        $this->assertDatabaseHas('materi', ['judul' => 'Materi Test']);
    }
}
