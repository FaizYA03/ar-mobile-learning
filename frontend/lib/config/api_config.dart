import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  /// Override via build/run flag (TANPA edit kode):
  ///   flutter run --dart-define=API_BASE_URL=https://api.domain.com/api
  ///   flutter build apk --release --dart-define=API_BASE_URL=https://api.domain.com/api
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _webFallback = 'http://127.0.0.1:8000/api';

  /// Android emulator: 10.0.2.2 = loopback mesin host.
  /// HP fisik: JANGAN edit file ini — pakai `--dart-define=API_BASE_URL=http://<LAN_IP>:8000/api`
  static const String _androidEmulatorFallback = 'http://10.0.2.2:8000/api';

  static const String v1Prefix = '/v1';

  /// Override runtime (disimpan di SharedPreferences via ServerConfigService).
  /// Prioritas: runtime > --dart-define > fallback platform.
  /// Memungkinkan ganti IP LAN tanpa rebuild (HP fisik DHCP sering berubah).
  static String? _runtimeOverride;

  static void setRuntimeOverride(String? url) {
    final normalized = normalizeBaseUrl(url);
    _runtimeOverride = normalized;
  }

  static void clearRuntimeOverride() {
    _runtimeOverride = null;
  }

  static String? get runtimeOverride => _runtimeOverride;

  /// Normalisasi input user menjadi `http(s)://host:port/api`.
  /// Return null jika kosong/tidak valid.
  static String? normalizeBaseUrl(String? input) {
    if (input == null) return null;
    var url = input.trim();
    if (url.isEmpty) return null;
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return null;
    }
    if (url.endsWith('/api')) return url;
    // Terima input tanpa /api (mis. http://192.168.1.10:8000) -> tambah /api.
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.path.isEmpty || uri.path == '/') return '$url/api';
    return url;
  }

  static String get baseUrl {
    if (_runtimeOverride != null && _runtimeOverride!.isNotEmpty) {
      return _runtimeOverride!;
    }
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    try {
      if (kIsWeb) return _webFallback;
      if (Platform.isAndroid) return _androidEmulatorFallback;
      if (Platform.isIOS) return _androidEmulatorFallback;
    } catch (_) {}
    return _webFallback;
  }

  static String get v1BaseUrl => '$baseUrl$v1Prefix';

  /// Host dasar tanpa sufiks `/api` (untuk URL aset/storage).
  /// Pure dan hanya memotong SUFIKS, tidak `replaceFirst('/api')`
  /// yang merusak host seperti `https://api.domain.com/api`.
  static String stripApiSuffix(String url) {
    var base = url.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.toLowerCase().endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }
    return base;
  }

  static String get baseHost => stripApiSuffix(baseUrl);

  /// True jika base URL berasal dari --dart-define (build production).
  static bool get isOverridden => _envBaseUrl.isNotEmpty;

  /// Sumber base URL aktif: custom (pengaturan) / dart-define / emulator / web.
  static String get source {
    if (_runtimeOverride != null && _runtimeOverride!.isNotEmpty) {
      return 'custom';
    }
    if (_envBaseUrl.isNotEmpty) return 'dart-define';
    try {
      if (kIsWeb) return 'web';
      if (Platform.isAndroid || Platform.isIOS) return 'emulator';
    } catch (_) {}
    return 'web';
  }

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
