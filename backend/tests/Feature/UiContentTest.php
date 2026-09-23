<?php

namespace Tests\Feature;

use App\Models\AppSetting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class UiContentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_app_config_includes_branding_texts_and_slides(): void
    {
        $response = $this->getJson('/api/v1/app/config');
        $response->assertStatus(200)->assertJson(['success' => true]);

        $data = $response->json('data');
        $this->assertSame('AR Mobile Learning', $data['branding']['app_name']);
        $this->assertSame('AR Mobile Learning', $data['texts']['splash_title']);
        $this->assertSame(1, $data['ui_content_version']);
        $this->assertCount(3, $data['onboarding_slides']);
        $this->assertArrayHasKey('title', $data['onboarding_slides'][0]);
        $this->assertArrayHasKey('description', $data['onboarding_slides'][0]);
    }

    public function test_guest_cannot_access_content_cms(): void
    {
        $this->get('/admin/system/content')->assertRedirect();
    }

    public function test_siswa_forbidden_from_content_cms(): void
    {
        $this->actingAs(User::where('role', 'siswa')->first());
        $this->get('/admin/system/content')->assertStatus(403);
    }

    public function test_admin_can_view_content_cms(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());
        $this->get('/admin/system/content')
            ->assertStatus(200)
            ->assertSee('Konten Aplikasi');
    }

    public function test_admin_can_update_branding_and_splash_separately(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());

        // Section branding saja — splash tidak ikut berubah.
        $this->post('/admin/system/content/branding', [
            'app_name' => 'Sekolah Hebat',
        ])->assertRedirect();

        $this->assertSame('Sekolah Hebat', AppSetting::getValue('app_name'));
        $this->assertSame('AR Mobile Learning', AppSetting::getValue('splash_title'));
        $this->assertSame(2, (int) AppSetting::getValue('ui_content_version'));

        // Section splash saja — branding tidak ikut berubah.
        $this->post('/admin/system/content/splash', [
            'splash_title' => 'Judul Splash Baru',
            'splash_subtitle' => 'Belajar Seru',
        ])->assertRedirect();

        $this->assertSame('Sekolah Hebat', AppSetting::getValue('app_name'));
        $this->assertSame('Judul Splash Baru', AppSetting::getValue('splash_title'));
        $this->assertSame(3, (int) AppSetting::getValue('ui_content_version'));

        $this->getJson('/api/v1/app/config')
            ->assertJsonPath('data.branding.app_name', 'Sekolah Hebat')
            ->assertJsonPath('data.texts.splash_title', 'Judul Splash Baru')
            ->assertJsonPath('data.ui_content_version', 3);
    }

    public function test_branding_validation_does_not_touch_other_sections(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());

        // app_name wajib — gagal validasi, versi tidak naik.
        $this->post('/admin/system/content/branding', ['app_name' => ''])
            ->assertSessionHasErrors('app_name');

        $this->assertSame(1, (int) AppSetting::getValue('ui_content_version'));
    }

    public function test_admin_can_upload_logo(): void
    {
        Storage::fake('public');
        $this->actingAs(User::where('role', 'admin')->first());

        $this->post('/admin/system/content/branding', [
            'app_name' => 'AR Mobile Learning',
            'app_logo' => UploadedFile::fake()->image('logo.png', 200, 200),
        ])->assertRedirect();

        $logo = AppSetting::getValue('app_logo');
        $this->assertNotEmpty($logo);
        Storage::disk('public')->assertExists($logo);

        $this->getJson('/api/v1/app/config')
            ->assertJsonPath('data.branding.logo_path', $logo);
    }

    public function test_app_config_includes_batch2_blocks(): void
    {
        $this->getJson('/api/v1/app/config')
            ->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'announcement' => ['text', 'active'],
                    'help_content',
                    'about_content',
                    'contact' => ['email', 'wa'],
                ],
            ]);
    }

    public function test_admin_can_update_announcement_help_and_contact(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());

        $this->post('/admin/system/content/announcement', [
            'announcement_text' => 'Ujian tengah semester dimulai Senin!',
            'announcement_active' => '1',
        ])->assertRedirect();

        $this->post('/admin/system/content/help', [
            'help_content' => 'Panduan baru.',
            'about_content' => 'Tentang baru.',
            'contact_email' => 'cs@sekolah.id',
            'contact_wa' => '6281234567890',
        ])->assertRedirect();

        $this->assertSame('Ujian tengah semester dimulai Senin!', AppSetting::getValue('announcement_text'));
        $this->assertTrue((bool) AppSetting::getValue('announcement_active'));

        $this->getJson('/api/v1/app/config')
            ->assertJsonPath('data.announcement.text', 'Ujian tengah semester dimulai Senin!')
            ->assertJsonPath('data.announcement.active', true)
            ->assertJsonPath('data.help_content', 'Panduan baru.')
            ->assertJsonPath('data.contact.email', 'cs@sekolah.id')
            ->assertJsonPath('data.contact.wa', '6281234567890');
    }

    public function test_unchecking_announcement_hides_banner(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());

        // Checkbox unchecked tidak terkirim → harus false.
        $this->post('/admin/system/content/announcement', [])->assertRedirect();

        $this->getJson('/api/v1/app/config')
            ->assertJsonPath('data.announcement.active', false);
    }

    public function test_admin_can_update_greetings_and_onboarding(): void
    {
        $this->actingAs(User::where('role', 'admin')->first());

        $this->post('/admin/system/content/greetings', [
            'greeting_siswa' => 'Ayo belajar!',
        ])->assertRedirect();
        $this->assertSame('Ayo belajar!', AppSetting::getValue('greeting_siswa'));

        $this->post('/admin/system/content/onboarding', [
            'slides' => [
                ['title' => 'Halo', 'description' => 'Deskripsi halo'],
            ],
        ])->assertRedirect();

        $this->getJson('/api/v1/app/config')
            ->assertJsonPath('data.texts.greeting_siswa', 'Ayo belajar!')
            ->assertJsonPath('data.onboarding_slides.0.title', 'Halo');
    }
}
