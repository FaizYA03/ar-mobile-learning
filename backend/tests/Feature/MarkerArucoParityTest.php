<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\ArMarkerGenerator;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Paritas identitas ArUco di semua jalur tulis: API, CMS upload/edit.
 * Aturan tunggal ada di ArMarkerGenerator::pairError().
 */
class MarkerArucoParityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_pair_error_rules(): void
    {
        $this->assertNull(ArMarkerGenerator::pairError(null, null));
        $this->assertNotNull(ArMarkerGenerator::pairError('DICT_4X4_50', null));
        $this->assertNotNull(ArMarkerGenerator::pairError(null, 5));
        $this->assertNotNull(ArMarkerGenerator::pairError('DICT_NOPE', 5));
        $this->assertNotNull(ArMarkerGenerator::pairError('DICT_4X4_50', 50));
        $this->assertNull(ArMarkerGenerator::pairError('DICT_4X4_50', 49));
    }

    public function test_api_create_marker_with_aruco_pair(): void
    {
        Storage::fake('public');
        Sanctum::actingAs(User::where('role', 'guru')->first());

        $this->postJson('/api/ar/markers', [
            'marker_id' => 'MARKER-API-ARUCO',
            'marker_type' => 'pattern',
            'image_path' => UploadedFile::fake()->image('m.png', 200, 200),
            'aruco_dictionary' => 'DICT_4X4_50',
            'ar_uco_id' => 40,
        ])->assertStatus(201);

        $this->assertDatabaseHas('ar_markers', [
            'marker_id' => 'MARKER-API-ARUCO',
            'aruco_dictionary' => 'DICT_4X4_50',
            'ar_uco_id' => 40,
        ]);
    }

    public function test_api_rejects_same_id_in_same_dictionary(): void
    {
        Storage::fake('public');
        Sanctum::actingAs(User::where('role', 'guru')->first());

        // Seeder: DICT_4X4_50 id 0 sudah dipakai.
        $this->postJson('/api/ar/markers', [
            'marker_id' => 'MARKER-DUP',
            'marker_type' => 'pattern',
            'image_path' => UploadedFile::fake()->image('m.png', 200, 200),
            'aruco_dictionary' => 'DICT_4X4_50',
            'ar_uco_id' => 0,
        ])->assertStatus(422);
    }

    public function test_same_id_allowed_in_different_dictionary(): void
    {
        Storage::fake('public');
        Sanctum::actingAs(User::where('role', 'guru')->first());

        $this->postJson('/api/ar/markers', [
            'marker_id' => 'MARKER-DIFF-DICT',
            'marker_type' => 'pattern',
            'image_path' => UploadedFile::fake()->image('m.png', 200, 200),
            'aruco_dictionary' => 'DICT_5X5_100',
            'ar_uco_id' => 0,
        ])->assertStatus(201);
    }

    public function test_cms_upload_with_aruco_pair(): void
    {
        Storage::fake('public');
        $this->actingAs(User::where('role', 'admin')->first());

        $this->post('/admin/ar/markers', [
            'marker_id' => 'MARKER-CMS-ARUCO',
            'marker_type' => 'pattern',
            'image_path' => UploadedFile::fake()->image('m.png', 200, 200),
            'aruco_dictionary' => 'DICT_4X4_50',
            'ar_uco_id' => 41,
        ])->assertRedirect(route('admin.ar.markers.index'));

        $this->assertDatabaseHas('ar_markers', [
            'marker_id' => 'MARKER-CMS-ARUCO',
            'aruco_dictionary' => 'DICT_4X4_50',
            'ar_uco_id' => 41,
        ]);
    }

    public function test_cms_upload_rejects_half_pair(): void
    {
        Storage::fake('public');
        $this->actingAs(User::where('role', 'admin')->first());

        $this->post('/admin/ar/markers', [
            'marker_id' => 'MARKER-HALF',
            'marker_type' => 'pattern',
            'image_path' => UploadedFile::fake()->image('m.png', 200, 200),
            'aruco_dictionary' => 'DICT_4X4_50',
        ])->assertSessionHasErrors('ar_uco_id');
    }
}
