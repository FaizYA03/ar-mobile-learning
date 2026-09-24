<?php

namespace Tests\Feature;

use App\Models\ArMarker;
use App\Models\ArModel;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MappingPivotSyncTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_create_mapped_mapping_attaches_pivot_and_counts(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $marker = ArMarker::first();
        $model = ArModel::first();

        $this->postJson('/api/ar/mappings', [
            'ar_marker_id' => $marker->id,
            'ar_model_id' => $model->id,
            'mapping_method' => 'marker_id',
            'mapping_status' => 'mapped',
        ])->assertStatus(201);

        $this->assertSame(1, $marker->fresh()->models()->count());
        $this->assertSame(1, $model->fresh()->markers()->count());
    }

    public function test_pending_mapping_does_not_attach_pivot(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $marker = ArMarker::first();
        $model = ArModel::first();

        $this->postJson('/api/ar/mappings', [
            'ar_marker_id' => $marker->id,
            'ar_model_id' => $model->id,
            'mapping_method' => 'marker_id',
            'mapping_status' => 'pending',
        ])->assertStatus(201);

        $this->assertSame(0, $marker->fresh()->models()->count());
    }

    public function test_updating_status_to_failed_detaches_pivot(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $marker = ArMarker::first();
        $model = ArModel::first();

        $res = $this->postJson('/api/ar/mappings', [
            'ar_marker_id' => $marker->id,
            'ar_model_id' => $model->id,
            'mapping_method' => 'marker_id',
            'mapping_status' => 'mapped',
        ])->assertStatus(201);

        $mappingId = $res->json('data.id');
        $this->assertSame(1, $marker->fresh()->models()->count());

        $this->putJson("/api/ar/mappings/{$mappingId}", [
            'mapping_status' => 'failed',
        ])->assertStatus(200);

        $this->assertSame(0, $marker->fresh()->models()->count());
    }
}
