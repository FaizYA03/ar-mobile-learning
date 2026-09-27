import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

/// Penyimpanan override URL server (IP LAN laptop untuk HP fisik).
///
/// Alur: user buka ikon server di Login/Register -> isi
/// `http://<LAN_IP>:8000/api` -> disimpan di SharedPreferences ->
/// diterapkan ke [ApiConfig] + reset Dio agar request berikutnya
/// memakai base URL baru tanpa perlu rebuild aplikasi.
class ServerConfigService {
  static const String prefsKey = 'custom_api_base_url';

  /// Muat override tersimpan (jika ada) dan terapkan ke ApiConfig.
  /// Panggil sekali saat startup sebelum request jaringan pertama.
  static Future<String?> loadAndApply() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsKey);
      final normalized = ApiConfig.normalizeBaseUrl(saved);
      if (normalized != null) {
        ApiConfig.setRuntimeOverride(normalized);
        ApiClient.reset();
        return normalized;
      }
      ApiConfig.clearRuntimeOverride();
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveOverride(String input) async {
    final normalized = ApiConfig.normalizeBaseUrl(input);
    if (normalized == null) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, normalized);
    ApiConfig.setRuntimeOverride(normalized);
    ApiClient.reset();
    return true;
  }

  static Future<void> clearOverride() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKey);
    } catch (_) {}
    ApiConfig.clearRuntimeOverride();
    ApiClient.reset();
  }
}
