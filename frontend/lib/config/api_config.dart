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

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    try {
      if (kIsWeb) return _webFallback;
      if (Platform.isAndroid) return _androidEmulatorFallback;
      if (Platform.isIOS) return _androidEmulatorFallback;
    } catch (_) {}
    return _webFallback;
  }

  static String get v1BaseUrl => '$baseUrl$v1Prefix';

  /// True jika base URL berasal dari --dart-define (build production).
  static bool get isOverridden => _envBaseUrl.isNotEmpty;

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
