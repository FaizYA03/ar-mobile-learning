<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\AppVersion;
use App\Models\ArHotspot;
use App\Models\ArMarker;
use App\Models\ArMarker3dMapping;
use App\Models\ArModel;
use Illuminate\Http\JsonResponse;

class AppConfigController extends Controller
{
    public function config(): JsonResponse
    {
        $maintenanceMode = AppSetting::getValue('maintenance_mode', false);
        $latestVersion = AppVersion::getLatest('android');

        return response()->json([
            'success' => true,
            'message' => 'Konfigurasi aplikasi berhasil diambil',
            'data' => [
                'maintenance_mode' => (bool) $maintenanceMode,
                'latest_version' => $latestVersion?->version ?? null,
                'minimum_supported_version' => $latestVersion?->minimum_supported_version ?? null,
                'build_number' => $latestVersion?->build_number ?? null,
                'release_notes' => $latestVersion?->release_notes ?? null,
                'download_url' => $latestVersion?->download_url ?? null,
                'content_version' => $this->getAggregateContentVersion(),
            ],
        ]);
    }

    public function contentVersion(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Versi konten berhasil diambil',
            'data' => [
                'content_version' => $this->getAggregateContentVersion(),
                'updated_at' => now()->toIso8601String(),
            ],
        ]);
    }

    private function getAggregateContentVersion(): int
    {
        $modelVersionSum = (int) ArModel::where('is_active', true)->sum('version');
        $markerCount = ArMarker::where('status', 'active')->count();
        $modelCount = ArModel::where('is_active', true)->count();
        $hotspotCount = ArHotspot::where('is_active', true)->count();
        $mappingCount = ArMarker3dMapping::where('mapping_status', 'mapped')->count();

        return $modelVersionSum * 10000
            + $markerCount * 100
            + $hotspotCount * 10
            + $mappingCount * 5
            + $modelCount;
    }
}
