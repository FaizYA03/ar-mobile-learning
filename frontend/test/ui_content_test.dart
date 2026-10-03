import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/services/app_config_service.dart';

Map<String, dynamic> sampleConfigJson() => {
      'maintenance_mode': false,
      'arcore_enabled': true,
      'content_version': 42,
      'ui_content_version': 3,
      'branding': {
        'app_name': 'Sekolah Hebat',
        'app_tagline': 'Belajar Seru',
        'logo_path': 'branding/logo.png',
        'logo_url': '/storage/branding/logo.png',
      },
      'texts': {
        'splash_title': 'Sekolah Hebat',
        'splash_subtitle': 'Belajar Seru Setiap Hari',
        'greeting_siswa': 'Ayo belajar!',
        'greeting_guru': 'Kelola kelasmu',
        'greeting_admin': 'Atur sistem',
      },
      'onboarding_slides': [
        {'title': 'Satu', 'description': 'Deskripsi satu'},
        {'title': 'Dua', 'description': 'Deskripsi dua'},
      ],
      'announcement': {'text': 'Libur Senin!', 'active': true},
      'help_content': 'Panduan.',
      'about_content': 'Tentang kami.',
      'contact': {'email': 'cs@sekolah.id', 'wa': '6281234567890'},
    };

void main() {
  group('AppConfigData Batch 1 parsing', () {
    test('parses branding, texts, slides', () {
      final config = AppConfigData.fromJson(sampleConfigJson());
      expect(config.appName, 'Sekolah Hebat');
      expect(config.splashTitle, 'Sekolah Hebat');
      expect(config.greetingSiswa, 'Ayo belajar!');
      expect(config.greetingGuru, 'Kelola kelasmu');
      expect(config.uiContentVersion, 3);
      expect(config.onboardingSlides.length, 2);
      expect(config.onboardingSlides.first.title, 'Satu');
    });

    test('falls back to defaults when blocks missing', () {
      final config = AppConfigData.fromJson({
        'maintenance_mode': false,
        'content_version': 0,
      });
      expect(config.appName, 'AR Mobile Learning');
      expect(config.splashTitle, 'AR Mobile Learning');
      expect(config.logoUrl, isNull);
      expect(config.onboardingSlides.length, 3);
    });

    test('toJson round-trips branding and slides', () {
      final config = AppConfigData.fromJson(sampleConfigJson());
      final restored = AppConfigData.fromJson(Map<String, dynamic>.from(
          config.toJson().map((k, v) => MapEntry(k, v))));
      expect(restored.appName, config.appName);
      expect(restored.onboardingSlides.length, 2);
    });

    test('parses batch 2 announcement, help, contact', () {
      final config = AppConfigData.fromJson(sampleConfigJson());
      expect(config.announcementText, 'Libur Senin!');
      expect(config.announcementActive, isTrue);
      expect(config.helpContent, 'Panduan.');
      expect(config.aboutContent, 'Tentang kami.');
      expect(config.contactEmail, 'cs@sekolah.id');
      expect(config.contactWa, '6281234567890');
    });

    test('batch 2 defaults hide banner and contacts', () {
      final config = AppConfigData.fromJson({
        'maintenance_mode': false,
        'content_version': 0,
      });
      expect(config.announcementActive, isFalse);
      expect(config.announcementText, isEmpty);
      expect(config.helpContent, isEmpty);
      expect(config.contactEmail, isEmpty);
    });
  });

  group('resolveAssetUrl', () {
    const base = 'http://10.0.2.2:8000/api';

    test('returns null for empty', () {
      expect(AppConfigService.resolveAssetUrl(base, null), isNull);
      expect(AppConfigService.resolveAssetUrl(base, ''), isNull);
    });

    test('passes through absolute url', () {
      expect(
        AppConfigService.resolveAssetUrl(
            base, 'https://cdn.example.com/logo.png'),
        'https://cdn.example.com/logo.png',
      );
    });

    test('prefixes relative storage path', () {
      expect(
        AppConfigService.resolveAssetUrl(base, '/storage/branding/logo.png'),
        'http://10.0.2.2:8000/storage/branding/logo.png',
      );
      expect(
        AppConfigService.resolveAssetUrl(base, 'branding/logo.png'),
        'http://10.0.2.2:8000/storage/branding/logo.png',
      );
    });

    test('keeps host intact when subdomain starts with "api"', () {
      expect(
        AppConfigService.resolveAssetUrl(
            'https://api.domain.com/api', '/storage/branding/logo.png'),
        'https://api.domain.com/storage/branding/logo.png',
      );
      expect(
        AppConfigService.resolveAssetUrl(
            'https://api.sekolah.sch.id/api', 'branding/logo.png'),
        'https://api.sekolah.sch.id/storage/branding/logo.png',
      );
      expect(
        AppConfigService.resolveAssetUrl(
            'https://apiclient.myapi.co.id/api', '/logo.png'),
        'https://apiclient.myapi.co.id/storage/logo.png',
      );
    });

    test('handles trailing slash and base without /api suffix', () {
      expect(
        AppConfigService.resolveAssetUrl(
            'https://api.domain.com/api/', '/logo.png'),
        'https://api.domain.com/storage/logo.png',
      );
      expect(
        AppConfigService.resolveAssetUrl('https://api.domain.com', '/logo.png'),
        'https://api.domain.com/storage/logo.png',
      );
    });
  });
}
