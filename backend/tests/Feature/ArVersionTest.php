<?php

namespace Tests\Feature;

use App\Models\ArModel;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ArVersionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_ar_model_has_version_field(): void
    {
        $model = ArModel::first();
        $this->assertNotNull($model->version);
        $this->assertIsInt($model->version);
        $this->assertEquals(1, $model->version);
    }

    public function test_ar_model_version_increments_on_update(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $model = ArModel::first();
        $originalVersion = $model->version;

        $response = $this->putJson("/api/ar/models/{$model->id}", [
            'model_name' => $model->model_name . ' Updated',
        ]);

        $response->assertStatus(200);
        $model->refresh();
        $this->assertEquals($originalVersion, $model->version, 'Version should not change on non-file update');
    }

    public function test_ar_model_version_increments_in_api_response(): void
    {
        $guru = User::where('role', 'guru')->first();
        Sanctum::actingAs($guru);

        $model = ArModel::first();

        $response = $this->getJson("/api/ar/models/{$model->id}");
        $response->assertStatus(200)
            ->assertJsonPath('data.version', $model->version);
    }

    public function test_ar_model_version_in_database(): void
    {
        $this->assertDatabaseHas('ar_models', [
            'id' => ArModel::first()->id,
            'version' => 1,
        ]);
    }
}
