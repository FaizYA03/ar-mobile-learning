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
        $arcoreEnabled = AppSetting::getValue('arcore_enabled', true);
        $latestVersion = AppVersion::getLatest('android');

        $logoPath = AppSetting::getValue('app_logo', '');

        return response()->json([
            'success' => true,
            'message' => 'Konfigurasi aplikasi berhasil diambil',
            'data' => [
                'maintenance_mode' => (bool) $maintenanceMode,
                'arcore_enabled' => (bool) $arcoreEnabled,
                'latest_version' => $latestVersion?->version ?? null,
                'minimum_supported_version' => $latestVersion?->minimum_supported_version ?? null,
                'build_number' => $latestVersion?->build_number ?? null,
                'release_notes' => $latestVersion?->release_notes ?? null,
                'download_url' => $latestVersion?->download_url ?? null,
                'content_version' => $this->getAggregateContentVersion(),
                'ui_content_version' => (int) AppSetting::getValue('ui_content_version', 1),
                // Penanda deploy: jam server saat response dibuat (untuk verifikasi CI/CD).
                'server_time' => now()->toIso8601String(),
                'branding' => [
                    'app_name' => AppSetting::getValue('app_name', 'AR Mobile Learning'),
                    'app_tagline' => AppSetting::getValue('app_tagline', ''),
                    'logo_path' => $logoPath ?: null,
                    'logo_url' => $logoPath ? \Illuminate\Support\Facades\Storage::disk('public')->url($logoPath) : null,
                ],
                'texts' => [
                    'splash_title' => AppSetting::getValue('splash_title', 'AR Mobile Learning'),
                    'splash_subtitle' => AppSetting::getValue('splash_subtitle', ''),
                    'greeting_siswa' => AppSetting::getValue('greeting_siswa', ''),
                    'greeting_guru' => AppSetting::getValue('greeting_guru', ''),
                    'greeting_admin' => AppSetting::getValue('greeting_admin', ''),
                ],
                'onboarding_slides' => AppSetting::getValue('onboarding_slides', []),
                'announcement' => [
                    'text' => AppSetting::getValue('announcement_text', ''),
                    'active' => (bool) AppSetting::getValue('announcement_active', false),
                ],
                'help_content' => AppSetting::getValue('help_content', ''),
                'about_content' => AppSetting::getValue('about_content', ''),
                'contact' => [
                    'email' => AppSetting::getValue('contact_email', ''),
                    'wa' => AppSetting::getValue('contact_wa', ''),
                ],
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
