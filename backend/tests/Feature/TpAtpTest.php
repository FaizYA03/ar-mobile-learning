<?php

namespace Tests\Feature;

use App\Models\TpAtp;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TpAtpTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_authenticated_user_can_get_tp_atp_list(): void
    {
        $user = User::where('role', 'siswa')->first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/tp-atp');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => ['id', 'kode', 'fase', 'elemen', 'judul', 'materi_count'],
                ],
            ]);
    }

    public function test_authenticated_user_can_view_tp_atp_detail(): void
    {
        $user = User::where('role', 'siswa')->first();
        $tpAtp = TpAtp::first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/tp-atp/' . $tpAtp->id);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $tpAtp->id,
                    'kode' => $tpAtp->kode,
                ],
            ]);
    }

    public function test_guru_can_create_and_update_tp_atp(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $createResponse = $this->postJson('/api/guru/tp-atp', [
            'kode' => 'TP-TEST-99',
            'fase' => 'E',
            'elemen' => 'Testing',
            'judul' => 'Judul Test TP',
            'deskripsi' => 'Deskripsi testing',
        ]);

        $createResponse->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'TP/ATP berhasil dibuat',
            ]);

        $createdId = $createResponse->json('data.id');

        $updateResponse = $this->putJson('/api/guru/tp-atp/' . $createdId, [
            'judul' => 'Judul Test TP Updated',
        ]);

        $updateResponse->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'judul' => 'Judul Test TP Updated',
                ],
            ]);

        $deleteResponse = $this->deleteJson('/api/guru/tp-atp/' . $createdId);
        $deleteResponse->assertStatus(200);
    }

    public function test_siswa_cannot_create_tp_atp(): void
    {
        $siswa = User::where('role', 'siswa')->first();
        Sanctum::actingAs($siswa);

        $response = $this->postJson('/api/guru/tp-atp', [
            'kode' => 'TP-UNAUTHORIZED',
            'fase' => 'E',
            'elemen' => 'Testing',
            'judul' => 'Judul Unauthorized',
        ]);

        $response->assertStatus(403);
    }
}