<?php

namespace Tests\Feature;

use App\Models\Materi;
use App\Models\TpAtp;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MateriTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_authenticated_user_can_list_materi(): void
    {
        $user = User::where('role', 'siswa')->first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/materi');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => ['id', 'judul', 'slug', 'ringkasan', 'konten', 'tp_atp'],
                ],
            ]);
    }

    public function test_authenticated_user_can_view_materi_detail(): void
    {
        $user = User::where('role', 'siswa')->first();
        $materi = Materi::first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/materi/' . $materi->id);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $materi->id,
                    'judul' => $materi->judul,
                ],
            ]);
    }

    public function test_guru_can_create_update_and_delete_materi(): void
    {
        $guru = User::where('role', 'guru')->first();
        $tpAtp = TpAtp::first();
        Sanctum::actingAs($guru);

        $createResponse = $this->postJson('/api/guru/materi', [
            'tp_atp_id' => $tpAtp->id,
            'judul' => 'Materi Uji Coba Guru',
            'ringkasan' => 'Ringkasan uji coba',
            'konten' => 'Konten lengkap uji coba untuk materi pembelajaran.',
            'estimasi_menit' => 15,
        ]);

        $createResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Materi berhasil dibuat',
            ]);

        $createdId = $createResponse->json('data.id');

        $updateResponse = $this->putJson('/api/guru/materi/' . $createdId, [
            'judul' => 'Materi Uji Coba Guru Updated',
        ]);

        $updateResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'judul' => 'Materi Uji Coba Guru Updated',
                ],
            ]);

        $deleteResponse = $this->deleteJson('/api/guru/materi/' . $createdId);
        $deleteResponse->assertStatus(200);
    }

    public function test_siswa_cannot_create_materi(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        $tpAtp = TpAtp::first();
        Sanctum::actingAs($siswa);

        $response = $this->postJson('/api/guru/materi', [
            'tp_atp_id' => $tpAtp->id,
            'judul' => 'Siswa Creating Materi',
            'konten' => 'Should fail',
        ]);

        $response->assertStatus(403);
    }

    public function test_create_materi_fails_without_required_fields(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $response = $this->postJson('/api/guru/materi', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['tp_atp_id', 'judul', 'konten']);
    }

    public function test_create_materi_fails_with_invalid_tp_atp(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $response = $this->postJson('/api/guru/materi', [
            'tp_atp_id' => 99999,
            'judul' => 'Test',
            'konten' => 'Content',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['tp_atp_id']);
    }

    public function test_list_materi_uses_api_resource_format(): void
    {
        $user = User::where('role', 'siswa')->first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/materi');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    '*' => ['id', 'judul', 'slug', 'ringkasan', 'konten', 'estimasi_menit', 'is_published', 'tp_atp', 'ar_model'],
                ],
            ]);
    }

    public function test_materi_detail_includes_gambar_cover_url(): void
    {
        $user = User::where('role', 'siswa')->first();
        $materi = Materi::first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/materi/' . $materi->id);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id', 'judul', 'gambar_cover_url',
                ],
            ]);
    }
}