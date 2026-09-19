import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  static const String _webUrl = 'http://127.0.0.1:8000/api';
  static const String _physicalDeviceUrl = 'http://10.42.37.181:8000/api';

  static const String v1Prefix = '/v1';

  static String get baseUrl {
    try {
      if (kIsWeb) return _webUrl;
      if (Platform.isAndroid) return _physicalDeviceUrl;
      if (Platform.isIOS) return _physicalDeviceUrl;
    } catch (_) {}
    return _webUrl;
  }

  static String get v1BaseUrl => '$baseUrl$v1Prefix';

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
