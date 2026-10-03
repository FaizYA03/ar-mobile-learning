<?php

namespace Tests\Feature;

use App\Models\ArHotspot;
use App\Models\ArMarker;
use App\Models\ArModel;
use App\Models\Materi;
use App\Models\TpAtp;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UploadValidationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        Storage::fake('public');
    }

    private function guru(): User
    {
        return User::where('role', 'guru')->first();
    }

    public function test_guru_can_upload_valid_glb_model(): void
    {
        Sanctum::actingAs($this->guru());

        $file = UploadedFile::fake()->create('wireless_router.glb', 512, 'application/octet-stream');

        $response = $this->post('/api/ar/models', [
            'model_name' => 'Router Uji',
            'glb_path' => $file,
        ], ['Accept' => 'application/json']);

        $response->assertStatus(201)->assertJson(['success' => true]);
        $this->assertSame(1, ArModel::where('model_name', 'Router Uji')->count());
    }

    public function test_guru_can_upload_valid_gltf_model(): void
    {
        Sanctum::actingAs($this->guru());

        $file = UploadedFile::fake()->create('scene.gltf', 128, 'application/json');

        $this->post('/api/ar/models', [
            'model_name' => 'Scene Uji',
            'glb_path' => $file,
        ], ['Accept' => 'application/json'])->assertStatus(201);

        $this->assertSame(1, ArModel::where('model_name', 'Scene Uji')->count());
    }

    public function test_model_can_be_created_with_empty_description_and_category(): void
    {
        Sanctum::actingAs($this->guru());

        $file = UploadedFile::fake()->create('tanpa_deskripsi.glb', 256, 'application/octet-stream');

        $response = $this->post('/api/ar/models', [
            'model_name' => 'Model Tanpa Deskripsi',
            'glb_path' => $file,
            'description' => '',
            'category' => '',
        ], ['Accept' => 'application/json']);

        $this->assertSame(201, $response->status(), 'Deskripsi/kategori kosong tidak boleh menyebabkan 500.');
        $this->assertSame(1, ArModel::where('model_name', 'Model Tanpa Deskripsi')->count());
    }

    public function test_guru_cannot_upload_php_file_as_glb_model(): void
    {
        Sanctum::actingAs($this->guru());

        $file = UploadedFile::fake()->create('shell.php', 16, 'application/x-php');

        $response = $this->post('/api/ar/models', [
            'model_name' => 'Model Berbahaya',
            'glb_path' => $file,
        ], ['Accept' => 'application/json']);

        $response->assertStatus(422)->assertJsonValidationErrors(['glb_path']);
        $this->assertSame(0, ArModel::where('model_name', 'Model Berbahaya')->count());
    }

    public function test_guru_cannot_upload_double_extension_php_as_glb_model(): void
    {
        Sanctum::actingAs($this->guru());

        $file = UploadedFile::fake()->create('payload.glb.php', 16, 'application/x-php');

        $this->post('/api/ar/models', [
            'model_name' => 'Model Double Ext',
            'glb_path' => $file,
        ], ['Accept' => 'application/json'])->assertStatus(422);

        $this->assertSame(0, ArModel::where('model_name', 'Model Double Ext')->count());
    }

    public function test_glb_path_cannot_be_submitted_as_plain_string(): void
    {
        Sanctum::actingAs($this->guru());

        $response = $this->postJson('/api/ar/models', [
            'model_name' => 'Path Injection',
            'glb_path' => '../../.env',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['glb_path']);
        $this->assertSame(0, ArModel::where('model_name', 'Path Injection')->count());
    }

    public function test_guru_cannot_upload_non_image_as_materi_cover(): void
    {
        Sanctum::actingAs($this->guru());

        $tpAtp = TpAtp::first();

        $response = $this->post('/api/guru/materi', [
            'tp_atp_id' => $tpAtp->id,
            'judul' => 'Materi Cover Berbahaya',
            'konten' => 'Konten uji.',
            'gambar_cover' => UploadedFile::fake()->create('shell.php', 16, 'application/x-php'),
        ], ['Accept' => 'application/json']);

        $response->assertStatus(422)->assertJsonValidationErrors(['gambar_cover']);
        $this->assertSame(0, Materi::where('judul', 'Materi Cover Berbahaya')->count());
    }

    public function test_guru_can_upload_png_as_materi_cover(): void
    {
        Sanctum::actingAs($this->guru());

        $tpAtp = TpAtp::first();

        $response = $this->post('/api/guru/materi', [
            'tp_atp_id' => $tpAtp->id,
            'judul' => 'Materi Cover Sah',
            'konten' => 'Konten uji.',
            'gambar_cover' => UploadedFile::fake()->image('cover.png', 400, 400),
        ], ['Accept' => 'application/json']);

        $this->assertNotSame(422, $response->status(), 'Cover PNG sah harus diterima.');
        $this->assertSame(1, Materi::where('judul', 'Materi Cover Sah')->count());
    }

    public function test_marker_image_update_rejects_non_image(): void
    {
        Sanctum::actingAs($this->guru());

        $marker = ArMarker::first();

        if (! $marker) {
            $this->markTestSkipped('Seed tidak menyediakan marker.');
        }

        $response = $this->put("/api/ar/markers/{$marker->id}", [
            'image_path' => UploadedFile::fake()->create('shell.phtml', 16, 'application/x-httpd-php'),
        ], ['Accept' => 'application/json']);

        $response->assertStatus(422)->assertJsonValidationErrors(['image_path']);
    }

    public function test_hotspot_image_update_rejects_non_image(): void
    {
        Sanctum::actingAs($this->guru());

        $hotspot = ArHotspot::first();

        if (! $hotspot) {
            $this->markTestSkipped('Seed tidak menyediakan hotspot.');
        }

        $response = $this->put("/api/ar/hotspots/{$hotspot->id}", [
            'image_path' => UploadedFile::fake()->create('xss.svg', 16, 'image/svg+xml'),
        ], ['Accept' => 'application/json']);

        $response->assertStatus(422)->assertJsonValidationErrors(['image_path']);
    }
}
