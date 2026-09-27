import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'secure_storage_service.dart';

class ApiClient {
  static Dio? _dio;
  static String? _token;

  /// Navigator global untuk auto-logout (dipakai interceptor Dio).
  /// Dipasang di MaterialApp via `navigatorKey: ApiClient.navigatorKey`.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Throttle agar 401 beruntun (multi request paralel) hanya logout sekali.
  static DateTime? _lastForceLogout;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        _token ??= await SecureStorageService.getToken();
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      // Auto-logout global: token basi/dicabut dari server (401/419)
      // langsung buang sesi + lempar ke /login, dari request mana pun.
      // Tanpa ini user stuck di spinner (bug: harus logout manual
      // lalu login lagi agar normal).
      onError: (error, handler) async {
        final code = error.response?.statusCode;
        if (code == 401 || code == 419) {
          await forceLogout(path: error.requestOptions.path);
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  /// Murni & testable: kapan 401 boleh memicu auto-logout.
  /// Login/register yang 401 (salah password) TIDAK boleh logout.
  static bool shouldAutoLogout(
      {required String path, required int? statusCode}) {
    if (statusCode != 401 && statusCode != 419) return false;
    final p = path.toLowerCase();
    if (p == '/login' ||
        p == '/register' ||
        p.endsWith('/login') ||
        p.endsWith('/register')) {
      return false;
    }
    return true;
  }

  /// Buang sesi + navigasi ke /login. Aman dipanggil berulang
  /// (throttle 3 detik) dan aman saat navigator belum siap.
  static Future<void> forceLogout({String? path}) async {
    if (path != null) {
      // Path auth tidak relevan di sini, tapi dijaga konsistensinya.
      final p = path.toLowerCase();
      if (p == '/login' ||
          p == '/register' ||
          p.endsWith('/login') ||
          p.endsWith('/register')) {
        return;
      }
    }
    final now = DateTime.now();
    if (_lastForceLogout != null &&
        now.difference(_lastForceLogout!) < const Duration(seconds: 3)) {
      return;
    }
    _lastForceLogout = now;
    _token = null;
    // Semua akses BuildContext SEBELUM async gap pertama.
    final nav = navigatorKey.currentState;
    String? current;
    try {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        current = ModalRoute.of(ctx)?.settings.name;
      }
    } catch (_) {
      current = null;
    }
    try {
      await SecureStorageService.clearAll();
    } catch (_) {}
    if (nav == null) return;
    if (current == '/login') return;
    nav.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  static void resetLogoutThrottleForTest() {
    _lastForceLogout = null;
  }

  static String get v1BaseUrl => ApiConfig.v1BaseUrl;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  /// Buang instance Dio agar baseUrl terbaru (mis. setelah ganti
  /// --dart-define atau dalam test) dipakai ulang.
  static void reset() {
    _dio?.close(force: true);
    _dio = null;
    _token = null;
  }

  static Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return instance.get(path, queryParameters: queryParameters);
  }

  static Future<Response> post(String path, {dynamic data}) async {
    return instance.post(path, data: data);
  }

  static Future<Response> put(String path, {dynamic data}) async {
    return instance.put(path, data: data);
  }

  static Future<Response> delete(String path) async {
    return instance.delete(path);
  }

  static Future<Response> getV1(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return instance.get('/v1$path', queryParameters: queryParameters);
  }

  static Future<Response> postV1(String path, {dynamic data}) async {
    return instance.post('/v1$path', data: data);
  }
}
