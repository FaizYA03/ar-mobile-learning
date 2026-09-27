import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/marker_download_service.dart';

void main() {
  group('MarkerDownloadService.resolveDownloadUrl', () {
    const base = 'https://api.arlearning.my.id/api';

    test('URL absolut dipakai apa adanya', () {
      expect(
        MarkerDownloadService.resolveDownloadUrl(
            base, 'https://cdn.example.com/m.png'),
        'https://cdn.example.com/m.png',
      );
    });

    test('path absolut /storage ditempel ke host', () {
      expect(
        MarkerDownloadService.resolveDownloadUrl(
            base, '/storage/markers/m.png'),
        'https://api.arlearning.my.id/storage/markers/m.png',
      );
    });

    test('path storage/ relatif ditempel ke host', () {
      expect(
        MarkerDownloadService.resolveDownloadUrl(base, 'storage/markers/m.png'),
        'https://api.arlearning.my.id/storage/markers/m.png',
      );
    });

    test('path lain dianggap di bawah storage/', () {
      expect(
        MarkerDownloadService.resolveDownloadUrl(base, 'markers/m.png'),
        'https://api.arlearning.my.id/storage/markers/m.png',
      );
    });
  });

  group('MarkerDownloadService.buildFileName', () {
    test('marker_id dipakai sebagai nama file', () {
      expect(
        MarkerDownloadService.buildFileName(
            'MARKER-CPU-001', 'https://x/m.png'),
        'MARKER-CPU-001.png',
      );
    });

    test('karakter tidak aman disanitasi', () {
      expect(
        MarkerDownloadService.buildFileName('a/b:c 001', 'https://x/m.png'),
        'a_b_c_001.png',
      );
    });

    test('ekstensi jpg dipertahankan', () {
      expect(
        MarkerDownloadService.buildFileName('M1', 'https://x/m.JPG?token=abc'),
        'M1.jpg',
      );
    });

    test('marker_id kosong jadi marker.png', () {
      expect(
        MarkerDownloadService.buildFileName('', 'https://x/m.png'),
        'marker.png',
      );
    });
  });
}
