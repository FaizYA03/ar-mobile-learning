import 'package:flutter/services.dart';

enum ARMode { arCore, nonAR }

class ARService {
  static const MethodChannel _channel =
      MethodChannel('com.example.frontend/ar_check');

  static ARMode? _cachedMode;

  static Future<ARMode> checkARSupport() async {
    if (_cachedMode != null) return _cachedMode!;

    try {
      final result = await _channel.invokeMethod<bool>('isARCoreSupported');
      _cachedMode = (result == true) ? ARMode.arCore : ARMode.nonAR;
    } catch (_) {
      _cachedMode = ARMode.nonAR;
    }

    return _cachedMode!;
  }

  static bool get isARCoreSupported => _cachedMode == ARMode.arCore;
}
