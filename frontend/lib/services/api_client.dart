import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'secure_storage_service.dart';

class ApiClient {
  static Dio? _dio;
  static String? _token;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token == null) {
          _token = await SecureStorageService.getToken();
        }
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));

    return dio;
  }

  static String _getBaseUrl() {
    const webUrl = 'http://127.0.0.1:8000/api';
    const physicalDeviceUrl = 'http://10.42.37.181:8000/api';
    try {
      if (kIsWeb) return webUrl;
      if (Platform.isAndroid) return physicalDeviceUrl;
      if (Platform.isIOS) return physicalDeviceUrl;
    } catch (_) {}
    return webUrl;
  }

  static String get v1BaseUrl => '${_getBaseUrl()}/v1';

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
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
