<?php

namespace Tests\Feature;

use App\Models\Materi;
use App\Models\Quiz;
use App\Models\TpAtp;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ContentOwnershipTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    private function guru(): User
    {
        return User::where('role', 'guru')->first();
    }

    private function otherGuru(): User
    {
        return User::forceCreate([
            'name' => 'Guru Kedua',
            'email' => 'guru2@test.com',
            'password' => bcrypt('password'),
            'role' => 'guru',
        ]);
    }

    private function createMateri(User $guru): Materi
    {
        Sanctum::actingAs($guru);

        $response = $this->postJson('/api/guru/materi', [
            'tp_atp_id' => TpAtp::first()->id,
            'judul' => 'Materi Milik '.$guru->name,
            'konten' => 'Konten materi untuk pengujian kepemilikan.',
        ]);

        $response->assertStatus(201);

        return Materi::findOrFail($response->json('data.id'));
    }

    public function test_creator_is_recorded_when_guru_creates_materi(): void
    {
        $guru = $this->guru();
        $materi = $this->createMateri($guru);

        $this->assertSame($guru->id, $materi->created_by);
    }

    public function test_other_guru_cannot_update_or_delete_materi(): void
    {
        $materi = $this->createMateri($this->guru());
        Sanctum::actingAs($this->otherGuru());

        $this->putJson("/api/guru/materi/{$materi->id}", [
            'judul' => 'Diubah Guru Lain',
        ])->assertStatus(403);

        $this->deleteJson("/api/guru/materi/{$materi->id}")
            ->assertStatus(403);
    }

    public function test_creator_and_admin_can_update_materi(): void
    {
        $guru = $this->guru();
        $materi = $this->createMateri($guru);

        $this->putJson("/api/guru/materi/{$materi->id}", [
            'judul' => 'Diubah Pemilik',
        ])->assertStatus(200);

        Sanctum::actingAs(User::where('role', 'admin')->first());

        $this->putJson("/api/guru/materi/{$materi->id}", [
            'judul' => 'Diubah Admin',
        ])->assertStatus(200);
    }

    public function test_other_guru_cannot_add_questions_to_owned_quiz(): void
    {
        $guru = $this->guru();
        Sanctum::actingAs($guru);

        $quiz = Quiz::findOrFail($this->postJson('/api/guru/quizzes', [
            'title' => 'Quiz Milik Guru',
        ])->assertStatus(201)->json('data.id'));

        Sanctum::actingAs($this->otherGuru());

        $this->postJson("/api/guru/quizzes/{$quiz->id}/questions", [
            'text' => 'Soal dari guru lain',
            'options' => [
                ['text' => 'Benar', 'is_correct' => true],
                ['text' => 'Salah', 'is_correct' => false],
            ],
        ])->assertStatus(403);
    }

    public function test_siswa_cannot_view_unpublished_materi(): void
    {
        $guru = $this->guru();
        Sanctum::actingAs($guru);

        $materiId = $this->postJson('/api/guru/materi', [
            'tp_atp_id' => TpAtp::first()->id,
            'judul' => 'Materi Draf',
            'konten' => 'Belum boleh dibaca siswa.',
            'is_published' => false,
        ])->assertStatus(201)->json('data.id');

        Sanctum::actingAs(User::where('role', 'siswa')->first());

        $this->getJson("/api/materi/{$materiId}")->assertStatus(403);
    }
}
