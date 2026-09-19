import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/debug/ar_debug_log.dart';

enum ArCoreAvailability {
  supportedInstalled,
  supportedNotInstalled,
  unsupported,
  unknown,
}

class ArCoreDeviceInfo {
  const ArCoreDeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.sdkInt,
  });

  factory ArCoreDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return ArCoreDeviceInfo(
      manufacturer: map['manufacturer'] as String? ?? 'Unknown',
      model: map['model'] as String? ?? 'Unknown',
      androidVersion: map['androidVersion'] as String? ?? 'Unknown',
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
    );
  }

  final String manufacturer;
  final String model;
  final String androidVersion;
  final int sdkInt;
}

class ARService {
  static const MethodChannel _channel =
      MethodChannel('com.example.frontend/ar_check');

  static ArCoreAvailability? _cachedAvailability;

  static Future<ArCoreAvailability> checkAvailability() async {
    if (_cachedAvailability != null) return _cachedAvailability!;

    ArCoreAvailability availability;
    try {
      final result =
          await _channel.invokeMethod<String>('getArCoreAvailability');
      availability = _parseAvailability(result);
    } catch (e) {
      ArDebugLog.error('ARCore availability check failed: $e');
      availability = ArCoreAvailability.unknown;
    }

    _cachedAvailability = availability;
    ArDebugLog.log('ARCore state: $availability');
    return availability;
  }

  static Future<bool> requestInstall() async {
    try {
      final requested =
          await _channel.invokeMethod<bool>('requestArCoreInstall') ?? false;
      if (requested) {
        _cachedAvailability = null;
      }
      return requested;
    } catch (_) {
      return false;
    }
  }

  static Future<ArCoreDeviceInfo?> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceInfo',
      );
      if (result == null) return null;
      return ArCoreDeviceInfo.fromMap(result);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<PermissionStatus> requestCameraPermission() async {
    return Permission.camera.request();
  }

  static bool get isArCoreReady =>
      _cachedAvailability == ArCoreAvailability.supportedInstalled;

  static void resetCache() {
    _cachedAvailability = null;
  }

  static ArCoreAvailability _parseAvailability(String? raw) {
    switch (raw) {
      case 'supported':
        return ArCoreAvailability.supportedInstalled;
      case 'not_installed':
        return ArCoreAvailability.supportedNotInstalled;
      case 'unsupported':
        return ArCoreAvailability.unsupported;
      default:
        return ArCoreAvailability.unknown;
    }
  }
}
