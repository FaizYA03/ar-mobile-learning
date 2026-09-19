import '../models/models.dart';
import '../services/api_client.dart';

class AppConfigService {
  static AppConfigData? _config;
  static DateTime? _lastFetchTime;

  static Future<AppConfigData?> fetchConfig() async {
    try {
      final response = await ApiClient.getV1('/app/config');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _config = AppConfigData.fromJson(response.data['data']);
        _lastFetchTime = DateTime.now();
        return _config;
      }
    } catch (_) {}
    return null;
  }

  static AppConfigData? get config => _config;
  static DateTime? get lastFetchTime => _lastFetchTime;

  static bool get isMaintenanceMode => _config?.maintenanceMode ?? false;
  static String? get latestVersion => _config?.latestVersion;
  static String? get minimumSupportedVersion =>
      _config?.minimumSupportedVersion;
  static int get contentVersion => _config?.contentVersion ?? 0;

  static bool isVersionSupported(String currentVersion) {
    if (minimumSupportedVersion == null) return true;
    return _compareVersions(currentVersion, minimumSupportedVersion!) >= 0;
  }

  static bool isUpdateAvailable(String currentVersion) {
    if (latestVersion == null) return false;
    return _compareVersions(currentVersion, latestVersion!) < 0;
  }

  static int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.tryParse).toList();
    final partsB = b.split('.').map(int.tryParse).toList();

    final maxLength =
        partsA.length > partsB.length ? partsA.length : partsB.length;

    for (var i = 0; i < maxLength; i++) {
      final numA = (i < partsA.length ? partsA[i] : 0) ?? 0;
      final numB = (i < partsB.length ? partsB[i] : 0) ?? 0;
      if (numA != numB) return numA.compareTo(numB);
    }

    return 0;
  }

  static void resetForTest() {
    _config = null;
    _lastFetchTime = null;
  }
}
