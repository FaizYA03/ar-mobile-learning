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

    public function content()
    {
        $content = [
            'app_name' => AppSetting::getValue('app_name', 'AR Mobile Learning'),
            'app_tagline' => AppSetting::getValue('app_tagline', ''),
            'app_logo' => AppSetting::getValue('app_logo', ''),
            'splash_title' => AppSetting::getValue('splash_title', ''),
            'splash_subtitle' => AppSetting::getValue('splash_subtitle', ''),
            'greeting_siswa' => AppSetting::getValue('greeting_siswa', ''),
            'greeting_guru' => AppSetting::getValue('greeting_guru', ''),
            'greeting_admin' => AppSetting::getValue('greeting_admin', ''),
            'onboarding_slides' => AppSetting::getValue('onboarding_slides', []),
            'ui_content_version' => AppSetting::getValue('ui_content_version', 1),
            'announcement_text' => AppSetting::getValue('announcement_text', ''),
            'announcement_active' => (bool) AppSetting::getValue('announcement_active', false),
            'help_content' => AppSetting::getValue('help_content', ''),
            'about_content' => AppSetting::getValue('about_content', ''),
            'contact_email' => AppSetting::getValue('contact_email', ''),
            'contact_wa' => AppSetting::getValue('contact_wa', ''),
        ];

        return view('admin.system.content', compact('content'));
    }

    /**
     * Naikkan versi konten UI + catat log. Dipanggil tiap section disimpan.
     */
    private function bumpContentVersion(string $section): void
    {
        $version = (int) AppSetting::getValue('ui_content_version', 1) + 1;
        AppSetting::setValue('ui_content_version', (string) $version, 'integer');

        \App\Services\ActivityLogger::log('app_content.updated', 'app_setting', null, "Konten aplikasi ({$section}) diperbarui via admin");
    }

    private function redirectContent(string $section, string $message)
    {
        return redirect()->route('admin.system.content')->withFragment($section)->with('success', $message);
    }

    public function updateBranding(Request $request)
    {
        $validated = $request->validate([
            'app_name' => 'required|string|max:100',
            'app_tagline' => 'nullable|string|max:255',
            'app_logo' => 'nullable|image|mimes:png,jpg,jpeg,webp|max:2048',
            'remove_logo' => 'nullable|boolean',
        ]);

        AppSetting::setValue('app_name', $validated['app_name'], 'string');
        AppSetting::setValue('app_tagline', $validated['app_tagline'] ?? '', 'string');

        // Logo: upload baru / hapus / biarkan.
        $currentLogo = AppSetting::getValue('app_logo', '');
        if ($request->hasFile('app_logo')) {
            if ($currentLogo) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($currentLogo);
            }
            $path = $request->file('app_logo')->store('branding', 'public');
            AppSetting::setValue('app_logo', $path, 'string', 'Path logo aplikasi di storage');
        } elseif ($request->boolean('remove_logo') && $currentLogo) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($currentLogo);
            AppSetting::setValue('app_logo', '', 'string');
        }

        $this->bumpContentVersion('branding');

        return $this->redirectContent('branding', 'Branding berhasil disimpan.');
    }

    public function updateSplash(Request $request)
    {
        $validated = $request->validate([
            'splash_title' => 'required|string|max:100',
            'splash_subtitle' => 'nullable|string|max:255',
        ]);

        AppSetting::setValue('splash_title', $validated['splash_title'], 'string');
        AppSetting::setValue('splash_subtitle', $validated['splash_subtitle'] ?? '', 'string');

        $this->bumpContentVersion('splash');

        return $this->redirectContent('splash', 'Splash screen berhasil disimpan.');
    }

    public function updateGreetings(Request $request)
    {
        $validated = $request->validate([
            'greeting_siswa' => 'nullable|string|max:255',
            'greeting_guru' => 'nullable|string|max:255',
            'greeting_admin' => 'nullable|string|max:255',
        ]);

        foreach (['greeting_siswa', 'greeting_guru', 'greeting_admin'] as $key) {
            AppSetting::setValue($key, $validated[$key] ?? '', 'string');
        }

        $this->bumpContentVersion('sapaan');

        return $this->redirectContent('greetings', 'Sapaan dashboard berhasil disimpan.');
    }

    public function updateAnnouncement(Request $request)
    {
        $validated = $request->validate([
            'announcement_text' => 'nullable|string|max:1000',
            'announcement_active' => 'nullable|boolean',
        ]);

        AppSetting::setValue('announcement_text', $validated['announcement_text'] ?? '', 'string');
        // Checkbox unchecked tidak terkirim → paksa false.
        AppSetting::setValue('announcement_active', $request->boolean('announcement_active') ? 'true' : 'false', 'boolean', 'Tampilkan banner pengumuman');

        $this->bumpContentVersion('pengumuman');

        return $this->redirectContent('announcement', 'Pengumuman berhasil disimpan.');
    }

    public function updateHelp(Request $request)
    {
        $validated = $request->validate([
            'help_content' => 'nullable|string|max:10000',
            'about_content' => 'nullable|string|max:10000',
            'contact_email' => 'nullable|email|max:255',
            'contact_wa' => 'nullable|string|max:20',
        ]);

        foreach (['help_content', 'about_content', 'contact_email', 'contact_wa'] as $key) {
            AppSetting::setValue($key, $validated[$key] ?? '', 'string');
        }

        $this->bumpContentVersion('bantuan');

        return $this->redirectContent('help', 'Bantuan & Tentang berhasil disimpan.');
    }

    public function updateOnboarding(Request $request)
    {
        $validated = $request->validate([
            'slides' => 'nullable|array|max:5',
            'slides.*.title' => 'required|string|max:255',
            'slides.*.description' => 'required|string|max:1000',
        ]);

        if (isset($validated['slides'])) {
            $slides = array_values(array_filter($validated['slides'], fn ($s) => !empty($s['title'])));
            AppSetting::setValue('onboarding_slides', array_values($slides), 'json', 'Slide onboarding (judul + deskripsi per slide)');
        }

        $this->bumpContentVersion('onboarding');

        return $this->redirectContent('onboarding', 'Slide onboarding berhasil disimpan.');
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

        $appVersion = AppVersion::create($validated);

        \App\Services\ActivityLogger::created('app_version', $appVersion->id, "App version {$validated['version']} ({$validated['platform']}) created via admin");

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
