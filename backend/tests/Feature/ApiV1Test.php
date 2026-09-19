<?php

namespace Tests\Feature;

use App\Models\ArModel;
use App\Models\ArMarker;
use App\Models\ArHotspot;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ApiV1Test extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    // ========== APP CONFIG ==========

    public function test_app_config_returns_success(): void
    {
        $response = $this->getJson('/api/v1/app/config');
        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'maintenance_mode',
                    'latest_version',
                    'minimum_supported_version',
                    'content_version',
                ],
            ]);
    }

    public function test_app_config_maintenance_mode_default_false(): void
    {
        $response = $this->getJson('/api/v1/app/config');
        $response->assertJsonPath('data.maintenance_mode', false);
    }

    public function test_app_config_has_content_version(): void
    {
        $response = $this->getJson('/api/v1/app/config');
        $response->assertJsonStructure(['data' => ['content_version']]);
        $this->assertIsInt($response->json('data.content_version'));
    }

    // ========== CONTENT VERSION ==========

    public function test_content_version_returns_success(): void
    {
        $response = $this->getJson('/api/v1/content/version');
        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'content_version',
                    'updated_at',
                ],
            ]);
    }

    public function test_content_version_changes_when_model_added(): void
    {
        $response1 = $this->getJson('/api/v1/content/version');
        $v1 = $response1->json('data.content_version');

        ArModel::create([
            'model_name' => 'Test Model',
            'glb_path' => 'models/test.glb',
            'thumbnail_path' => 'thumbnails/test.png',
            'description' => 'Test',
            'category' => 'Test',
            'is_active' => true,
            'version' => 1,
        ]);

        $response2 = $this->getJson('/api/v1/content/version');
        $v2 = $response2->json('data.content_version');

        $this->assertNotEquals($v1, $v2, 'Content version should change when new model is added');
    }

    // ========== AR CONTENT ==========

    public function test_ar_content_is_publicly_accessible(): void
    {
        $response = $this->getJson('/api/v1/ar/content');
        $response->assertStatus(200);
    }

    public function test_ar_content_returns_success_for_authenticated_user(): void
    {
        $user = User::where('role', 'siswa')->first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/ar/content');
        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    '*' => [
                        'id',
                        'model_name',
                        'description',
                        'category',
                        'version',
                        'is_active',
                        'glb_path',
                        'markers' => [
                            '*' => [
                                'id',
                                'marker_id',
                                'marker_type',
                                'image_path',
                                'status',
                                'updated_at',
                            ],
                        ],
                        'hotspots' => [
                            '*' => [
                                'id',
                                'title',
                                'description',
                                'latitude',
                                'longitude',
                                'image_path',
                            ],
                        ],
                    ],
                ],
            ]);
    }

    public function test_ar_content_only_returns_active_models(): void
    {
        $user = User::where('role', 'siswa')->first();
        Sanctum::actingAs($user);

        $inactiveModel = ArModel::where('is_active', false)->first();
        $activeModel = ArModel::where('is_active', true)->first();

        $response = $this->getJson('/api/v1/ar/content');
        $data = $response->json('data');

        $ids = array_column($data, 'id');

        if ($inactiveModel) {
            $this->assertNotContains($inactiveModel->id, $ids, 'Inactive model should not appear in content');
        }
        if ($activeModel) {
            $this->assertContains($activeModel->id, $ids, 'Active model should appear in content');
        }
    }

    public function test_ar_content_includes_version_field(): void
    {
        $user = User::where('role', 'siswa')->first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/ar/content');
        $data = $response->json('data');

        foreach ($data as $item) {
            $this->assertArrayHasKey('version', $item);
            $this->assertIsInt($item['version']);
        }
    }

    public function test_ar_content_includes_markers_and_hotspots(): void
    {
        $user = User::where('role', 'siswa')->first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/ar/content');
        $data = $response->json('data');

        foreach ($data as $item) {
            $this->assertArrayHasKey('markers', $item);
            $this->assertArrayHasKey('hotspots', $item);
            $this->assertIsArray($item['markers']);
            $this->assertIsArray($item['hotspots']);
        }
    }

    public function test_ar_content_markers_include_updated_at(): void
    {
        $user = User::where('role', 'siswa')->first();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/ar/content');
        $data = $response->json('data');

        $markerSeen = false;
        foreach ($data as $item) {
            foreach ($item['markers'] as $marker) {
                $markerSeen = true;
                $this->assertArrayHasKey('updated_at', $marker);
            }
        }

        $this->assertTrue($markerSeen, 'Expected at least one seeded marker in /ar/content');
    }

    // ========== OLD ENDPOINTS STILL WORK ==========

    public function test_old_login_endpoint_still_works(): void
    {
        $response = $this->postJson('/api/login', [
            'email' => 'admin@demo.com',
            'password' => 'password',
        ]);
        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_old_public_ar_endpoint_still_works(): void
    {
        $response = $this->getJson('/api/ar/public/models');
        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }
}
