import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'auth_token';
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyUserAvatar = 'user_avatar_url';
  static const _keyAvatarPath = 'avatar_path';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: _keyUserRole, value: role);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  static Future<void> saveUserName(String name) async {
    await _storage.write(key: _keyUserName, value: name);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  static Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  static Future<void> saveUserAvatar(String? url) async {
    if (url == null || url.isEmpty) {
      await _storage.delete(key: _keyUserAvatar);
    } else {
      await _storage.write(key: _keyUserAvatar, value: url);
    }
  }

  static Future<String?> getUserAvatar() async {
    return await _storage.read(key: _keyUserAvatar);
  }

  static Future<void> saveAvatarPath(String? path) async {
    if (path == null) {
      await _storage.delete(key: _keyAvatarPath);
    } else {
      await _storage.write(key: _keyAvatarPath, value: path);
    }
  }

  static Future<String?> getAvatarPath() async {
    return await _storage.read(key: _keyAvatarPath);
  }

  static Future<void> saveAuthData({
    required String token,
    required String role,
    required String name,
    required String email,
  }) async {
    await Future.wait([
      saveToken(token),
      saveUserRole(role),
      saveUserName(name),
      saveUserEmail(email),
    ]);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
