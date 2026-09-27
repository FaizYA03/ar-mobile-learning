import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';

/// Download gambar marker AR agar siswa bisa menyimpan/mencetaknya.
///
/// Alur: URL marker (relatif/absolut) -> bytes via HTTP ->
/// file di direktori temporer -> dibuka via share sheet sistem
/// (pengguna pilih Simpan ke Download/Galeri/cetak).
/// Share sheet dipakai karena scoped storage Android 10+ melarang
/// tulis langsung dart:io ke folder Download publik.
class MarkerDownloadService {
  static const Duration downloadTimeout = Duration(seconds: 30);

  /// Ubah URL/path marker menjadi URL absolut yang bisa diunduh.
  /// Pure helper agar bisa di-unit-test.
  static String resolveDownloadUrl(String baseUrl, String urlOrPath) {
    final v = urlOrPath.trim();
    if (v.startsWith('http')) return v;
    final base = ApiConfig.stripApiSuffix(baseUrl);
    if (v.startsWith('/')) return '$base$v';
    if (v.startsWith('storage/')) return '$base/$v';
    return '$base/storage/$v';
  }

  /// Nama file aman dari marker_id + ekstensi URL (default .png).
  /// Pure helper agar bisa di-unit-test.
  static String buildFileName(String markerId, String downloadUrl) {
    var name = markerId.trim().isEmpty ? 'marker' : markerId.trim();
    name = name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    name = name.replaceAll(RegExp(r'_+'), '_');
    if (name.isEmpty) name = 'marker';
    var ext = '.png';
    final lower = downloadUrl.toLowerCase().split('?').first;
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      ext = '.jpg';
    } else if (lower.endsWith('.png')) {
      ext = '.png';
    }
    return '$name$ext';
  }

  /// Unduh bytes gambar marker. Throw [TimeoutException] /
  /// [HttpException] bila gagal (ditangani pemanggil jadi SnackBar).
  static Future<List<int>> downloadBytes(String downloadUrl) async {
    final response =
        await http.get(Uri.parse(downloadUrl)).timeout(downloadTimeout);
    if (response.statusCode != 200) {
      throw HttpException(
        'Server mengembalikan HTTP ${response.statusCode} saat mengunduh marker.',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw const HttpException('File marker kosong dari server.');
    }
    return response.bodyBytes;
  }

  /// Simpan bytes ke file temporer untuk di-share. Mengembalikan [File].
  static Future<File> saveTempFile(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Satu langkah: resolve URL -> unduh -> simpan temporer.
  /// Mengembalikan file siap share + URL sumbernya.
  static Future<({File file, String url})> downloadMarker({
    required String imageUrlOrPath,
    required String markerId,
    String? baseUrlOverride,
  }) async {
    final base = baseUrlOverride ?? ApiConfig.baseUrl;
    final url = resolveDownloadUrl(base, imageUrlOrPath);
    if (url.isEmpty) {
      throw const HttpException('URL gambar marker tidak tersedia.');
    }
    final bytes = await downloadBytes(url);
    final file = await saveTempFile(bytes, buildFileName(markerId, url));
    return (file: file, url: url);
  }
}
