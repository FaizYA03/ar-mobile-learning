<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\ArMarkerGenerator;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ArMarkerGenerateTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_max_id_matches_dictionary_size(): void
    {
        $this->assertSame(49, ArMarkerGenerator::maxId('DICT_4X4_50'));
        $this->assertSame(999, ArMarkerGenerator::maxId('DICT_7X7_1000'));
    }

    public function test_unknown_dictionary_throws(): void
    {
        $this->expectException(\RuntimeException::class);
        ArMarkerGenerator::maxId('DICT_NOPE');
    }

    public function test_out_of_range_id_throws_without_touching_python(): void
    {
        $this->expectException(\RuntimeException::class);
        ArMarkerGenerator::generate('DICT_4X4_50', 50);
    }

    public function test_admin_can_view_generate_form(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());
        $this->get('/admin/ar/markers/generate')
            ->assertStatus(200)
            ->assertSee('Generate Marker ArUco')
            ->assertSee('DICT_4X4_50');
    }

    public function test_generate_rejects_unknown_dictionary(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());
        $this->post('/admin/ar/markers/generate', [
            'marker_id' => 'MARKER-X',
            'aruco_dictionary' => 'DICT_NOPE',
            'ar_uco_id' => 1,
        ])->assertSessionHasErrors('aruco_dictionary');
    }

    public function test_generate_rejects_duplicate_aruco_combo(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());

        // Seeder sudah punya DICT_4X4_50 id 0 (lihat DatabaseSeeder).
        $this->post('/admin/ar/markers/generate', [
            'marker_id' => 'MARKER-DUPLIKAT',
            'aruco_dictionary' => 'DICT_4X4_50',
            'ar_uco_id' => 0,
        ])->assertSessionHasErrors('ar_uco_id');
    }

    public function test_generate_creates_marker_when_opencv_available(): void
    {
        if (!ArMarkerGenerator::isAvailable()) {
            $this->markTestSkipped('OpenCV (cv2.aruco) tidak tersedia di environment ini.');
        }

        Storage::fake('public');
        $this->actingAs(User::where('role', 'admin')->first());

        $this->post('/admin/ar/markers/generate', [
            'marker_id' => 'MARKER-GEN-TEST',
            'aruco_dictionary' => 'DICT_4X4_50',
            'ar_uco_id' => 49,
        ])->assertRedirect(route('admin.ar.markers.index'));

        $this->assertDatabaseHas('ar_markers', [
            'marker_id' => 'MARKER-GEN-TEST',
            'aruco_dictionary' => 'DICT_4X4_50',
            'ar_uco_id' => 49,
        ]);
    }
}
