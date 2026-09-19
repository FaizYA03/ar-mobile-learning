<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\AppVersion;
use Illuminate\Http\Request;

class SystemController extends Controller
{
    public function settings()
    {
        $settings = AppSetting::orderBy('key')->get();
        return view('admin.system.settings', compact('settings'));
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'settings' => 'required|array',
            'settings.*.key' => 'required|string',
            'settings.*.value' => 'nullable|string',
            'settings.*.description' => 'nullable|string',
        ]);

        foreach ($validated['settings'] as $item) {
            if (!empty($item['key'])) {
                AppSetting::updateOrCreate(
                    ['key' => $item['key']],
                    [
                        'value' => $item['value'],
                        'description' => $item['description'] ?? null,
                    ]
                );
            }
        }

        \App\Services\ActivityLogger::log('app_settings.updated', 'app_setting', null, 'App settings updated via admin');

        return redirect()->route('admin.system.settings')->with('success', 'Settings berhasil disimpan.');
    }

    public function versions()
    {
        $versions = AppVersion::orderByDesc('created_at')->get();
        return view('admin.system.versions', compact('versions'));
    }

    public function storeVersion(Request $request)
    {
        $validated = $request->validate([
            'platform' => 'required|string|in:android,ios',
            'version' => 'required|string|max:50',
            'build_number' => 'nullable|string|max:50',
            'minimum_supported_version' => 'nullable|string|max:50',
            'release_notes' => 'nullable|string',
            'download_url' => 'nullable|url|max:500',
            'is_active' => 'nullable|boolean',
        ]);

        $validated['is_active'] = $validated['is_active'] ?? true;

        AppVersion::create($validated);

        \App\Services\ActivityLogger::created('app_version', null, "App version {$validated['version']} ({$validated['platform']}) created via admin");

        return redirect()->route('admin.system.versions')->with('success', 'App version berhasil ditambahkan.');
    }

    public function updateVersion(Request $request, AppVersion $appVersion)
    {
        $validated = $request->validate([
            'platform' => 'sometimes|required|string|in:android,ios',
            'version' => 'sometimes|required|string|max:50',
            'build_number' => 'nullable|string|max:50',
            'minimum_supported_version' => 'nullable|string|max:50',
            'release_notes' => 'nullable|string',
            'download_url' => 'nullable|url|max:500',
            'is_active' => 'nullable|boolean',
        ]);

        $appVersion->update($validated);

        \App\Services\ActivityLogger::updated('app_version', $appVersion->id, "App version {$appVersion->version} updated via admin");

        return redirect()->route('admin.system.versions')->with('success', 'App version berhasil diperbarui.');
    }

    public function destroyVersion(AppVersion $appVersion)
    {
        \App\Services\ActivityLogger::deleted('app_version', $appVersion->id, "App version {$appVersion->version} deleted via admin");
        $appVersion->delete();

        return redirect()->route('admin.system.versions')->with('success', 'App version berhasil dihapus.');
    }
}
