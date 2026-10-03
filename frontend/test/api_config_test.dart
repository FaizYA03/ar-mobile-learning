import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/api_config.dart';

void main() {
  group('ApiConfig.stripApiSuffix', () {
    test('memotong sufiks /api di host biasa', () {
      expect(
        ApiConfig.stripApiSuffix('http://10.0.2.2:8000/api'),
        'http://10.0.2.2:8000',
      );
      expect(
        ApiConfig.stripApiSuffix('http://127.0.0.1:8000/api'),
        'http://127.0.0.1:8000',
      );
    });

    test('TIDAK merusak host yang subdomainnya diawali "api"', () {
      expect(
        ApiConfig.stripApiSuffix('https://api.domain.com/api'),
        'https://api.domain.com',
      );
      expect(
        ApiConfig.stripApiSuffix('https://api.sekolah.sch.id/api'),
        'https://api.sekolah.sch.id',
      );
      expect(
        ApiConfig.stripApiSuffix('https://apiclient.myapi.co.id/api'),
        'https://apiclient.myapi.co.id',
      );
      expect(
        ApiConfig.stripApiSuffix('https://api.arlearning.my.id/api'),
        'https://api.arlearning.my.id',
      );
    });

    test('menangani trailing slash berulang', () {
      expect(
        ApiConfig.stripApiSuffix('https://api.domain.com/api///'),
        'https://api.domain.com',
      );
      expect(
        ApiConfig.stripApiSuffix('  https://api.domain.com/api/  '),
        'https://api.domain.com',
      );
    });

    test('host tanpa sufiks /api tidak berubah', () {
      expect(
        ApiConfig.stripApiSuffix('https://api.domain.com'),
        'https://api.domain.com',
      );
      expect(
        ApiConfig.stripApiSuffix('https://api.domain.com/v1'),
        'https://api.domain.com/v1',
      );
    });

    test('hanya cocokkan /api di akhir string', () {
      expect(
        ApiConfig.stripApiSuffix('https://api.domain.com/apixyz'),
        'https://api.domain.com/apixyz',
      );
      expect(
        ApiConfig.stripApiSuffix('https://domain.com/api/v2'),
        'https://domain.com/api/v2',
      );
    });

    test('case-insensitive pada sufiks', () {
      expect(
        ApiConfig.stripApiSuffix('https://api.domain.com/API'),
        'https://api.domain.com',
      );
    });

    test('host akhir tidak mengandung /api setelah stripping', () {
      expect(
        ApiConfig.stripApiSuffix('https://api.domain.com/api'),
        isNot(contains('api.domain.com/api')),
      );
    });
  });
}
