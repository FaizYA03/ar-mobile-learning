import 'package:dio/dio.dart';
import '../config/api_config.dart';
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
      onError: (error, handler) {
        handler.next(error);
      },
    ));

    return dio;
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
