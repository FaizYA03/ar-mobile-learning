import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import '../services/api_client.dart';

class AppConfigService {
  static const String cacheKey = 'app_config_cache';
  static AppConfigData? _config;
  static DateTime? _lastFetchTime;

  static Future<AppConfigData?> fetchConfig() async {
    try {
      final response = await ApiClient.getV1('/app/config');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _config = AppConfigData.fromJson(
            Map<String, dynamic>.from(response.data['data']));
        _lastFetchTime = DateTime.now();
        await _saveCache(_config!);
        return _config;
      }
    } catch (_) {}
    return null;
  }

  /// Muat cache terakhir agar splash/onboarding tetap tampil
  /// dinamis meski offline atau sebelum login.
  static Future<AppConfigData?> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey);
      if (raw == null || raw.isEmpty) return null;
      _config =
          AppConfigData.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
      return _config;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCache(AppConfigData config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(config.toJson()));
    } catch (_) {}
  }

  /// Ubah logo_url/path relatif (/storage/...) menjadi URL absolut.
  /// Pure helper agar bisa di-unit-test.
  static String? resolveAssetUrl(String baseUrl, String? urlOrPath) {
    if (urlOrPath == null || urlOrPath.isEmpty) return null;
    if (urlOrPath.startsWith('http')) return urlOrPath;
    var path = urlOrPath.startsWith('/') ? urlOrPath.substring(1) : urlOrPath;
    if (!path.startsWith('storage/')) path = 'storage/$path';
    return '${ApiConfig.stripApiSuffix(baseUrl)}/$path';
  }

  static String? resolveLogoUrl(AppConfigData config) =>
      resolveAssetUrl(ApiConfig.baseUrl, config.logoUrl ?? config.logoPath);

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
