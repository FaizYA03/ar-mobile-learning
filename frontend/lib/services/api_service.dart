import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, FileSystemException;

import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static String get v1BaseUrl => ApiConfig.v1BaseUrl;

  static String? _token;

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    _token = await SecureStorageService.getToken();
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await SecureStorageService.saveToken(token);
  }

  static Future<void> clearToken() async {
    _token = null;
    ApiClient.clearToken();
    await SecureStorageService.clearAll();
  }

  static Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Map<String, dynamic> _decodeResponse(
    int statusCode,
    String body,
    String path,
  ) {
    // Backend mati/proxy HTML (502/404/maintenance) -> jangan lempar
    // FormatException mentah; kembalikan map agar UI bisa tampil + retry.
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      json = null;
    }
    final unauthorized = statusCode == 401 || statusCode == 419;
    if (unauthorized &&
        ApiClient.shouldAutoLogout(path: path, statusCode: statusCode)) {
      // Auto-logout global (sama seperti interceptor Dio): token basi
      // langsung dibuang + ke /login tanpa perlu logout manual.
      // Fire-and-forget agar decode tetap sinkron; pemanggil yang
      // sadar-auth (dashboard) juga menavigasi sendiri (di-throttle).
      unawaited(ApiClient.forceLogout(path: path));
    }
    if (json != null) {
      if (unauthorized) {
        json['unauthorized'] = true;
      }
      return json;
    }
    if (unauthorized) {
      return {
        'success': false,
        'message': 'Sesi berakhir, silakan login kembali.',
        'unauthorized': true,
      };
    }
    return {
      'success': false,
      'message': 'Server mengembalikan respons tidak valid (HTTP $statusCode).',
    };
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl$path'),
          headers: _headers(),
        )
        .timeout(ApiConfig.connectionTimeout);
    return _decodeResponse(response.statusCode, response.body, path);
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.connectionTimeout);
    return _decodeResponse(response.statusCode, response.body, path);
  }

  static Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.connectionTimeout);
    return _decodeResponse(response.statusCode, response.body, path);
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl$path'),
          headers: _headers(),
        )
        .timeout(ApiConfig.connectionTimeout);
    return _decodeResponse(response.statusCode, response.body, path);
  }

  // Auth
  static Future<Map<String, dynamic>> login(
          {required String email, required String password}) =>
      _post('/login', {'email': email, 'password': password});

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      _post('/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

  static Future<void> logout() async {
    try {
      await _post('/logout', {});
    } catch (_) {}
    await clearToken();
  }

  // Dashboard
  static Future<Map<String, dynamic>> getDashboard() => _get('/dashboard');

  // Profile (semua role)
  static Future<Map<String, dynamic>> getProfile() => _get('/user');
  static Future<Map<String, dynamic>> updateProfile({required String name}) =>
      _put('/user/profile', {'name': name});
  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      _put('/user/password', {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
  static Future<Map<String, dynamic>> uploadAvatar(
          {required String filePath}) =>
      _postMultipart('/user/avatar', {},
          filePath: filePath, fileField: 'avatar');

  // Quizzes (public)
  static Future<Map<String, dynamic>> getQuizzes() => _get('/quizzes');
  static Future<Map<String, dynamic>> getQuiz(int id) => _get('/quizzes/$id');
  static Future<Map<String, dynamic>> submitQuiz(
          int id, List<Map<String, dynamic>> answers) =>
      _post('/quizzes/$id/submit', {'answers': answers});
  static Future<Map<String, dynamic>> getQuizAttempts(int quizId) =>
      _get('/quizzes/$quizId/attempts');

  // Admin
  static Future<Map<String, dynamic>> adminGetUsers(
      {String? search, String? role}) {
    final params = <String>[];
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeQueryComponent(search)}');
    }
    if (role != null && role.isNotEmpty) {
      params.add('role=${Uri.encodeQueryComponent(role)}');
    }
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return _get('/admin/users$query');
  }

  static Future<Map<String, dynamic>> adminCreateUser(
          Map<String, dynamic> data) =>
      _post('/admin/users', data);
  static Future<Map<String, dynamic>> adminUpdateUser(
          int id, Map<String, dynamic> data) =>
      _put('/admin/users/$id', data);
  static Future<Map<String, dynamic>> adminDeleteUser(int id) =>
      _delete('/admin/users/$id');
  static Future<Map<String, dynamic>> adminGetQuizAttempts() =>
      _get('/admin/quiz-attempts');

  // Guru Quizzes
  static Future<Map<String, dynamic>> guruGetQuizzes() => _get('/guru/quizzes');
  static Future<Map<String, dynamic>> guruCreateQuiz(
          Map<String, dynamic> data) =>
      _post('/guru/quizzes', data);
  static Future<Map<String, dynamic>> guruUpdateQuiz(
          int id, Map<String, dynamic> data) =>
      _put('/guru/quizzes/$id', data);
  static Future<Map<String, dynamic>> guruDeleteQuiz(int id) =>
      _delete('/guru/quizzes/$id');
  static Future<Map<String, dynamic>> guruAddQuestion(
          int quizId, Map<String, dynamic> data) =>
      _post('/guru/quizzes/$quizId/questions', data);
  static Future<Map<String, dynamic>> guruDeleteQuestion(int questionId) =>
      _delete('/guru/questions/$questionId');
  static Future<Map<String, dynamic>> guruGetQuizAttempts({int? quizId}) {
    final query = quizId != null ? '?quiz_id=$quizId' : '';
    return _get('/guru/quiz-attempts$query');
  }

  // TP/ATP (Siswa / Guru / Admin)
  static Future<Map<String, dynamic>> getTpAtpList() => _get('/tp-atp');
  static Future<Map<String, dynamic>> getTpAtpDetail(int id) =>
      _get('/tp-atp/$id');
  static Future<Map<String, dynamic>> guruCreateTpAtp(
          Map<String, dynamic> data) =>
      _post('/guru/tp-atp', data);
  static Future<Map<String, dynamic>> guruUpdateTpAtp(
          int id, Map<String, dynamic> data) =>
      _put('/guru/tp-atp/$id', data);
  static Future<Map<String, dynamic>> guruDeleteTpAtp(int id) =>
      _delete('/guru/tp-atp/$id');

  // Materi (Siswa / Guru / Admin)
  static Future<Map<String, dynamic>> getMateriList({int? tpAtpId}) {
    final query = tpAtpId != null ? '?tp_atp_id=$tpAtpId' : '';
    return _get('/materi$query');
  }

  static Future<Map<String, dynamic>> getMateriDetail(int id) =>
      _get('/materi/$id');

  // Guru Materi (with multipart file upload support)
  static Future<Map<String, dynamic>> guruCreateMateri(
          Map<String, dynamic> data,
          {String? filePath}) =>
      _postMultipart('/guru/materi', data,
          filePath: filePath, fileField: 'gambar_cover');

  static Future<Map<String, dynamic>> guruUpdateMateri(
          int id, Map<String, dynamic> data, {String? filePath}) =>
      _postMultipart('/guru/materi/$id', data,
          filePath: filePath, fileField: 'gambar_cover');

  static Future<Map<String, dynamic>> guruDeleteMateri(int id) =>
      _delete('/guru/materi/$id');

  // AR Models (Guru + Admin) - with multipart upload
  static Future<Map<String, dynamic>> arGetModels() => _get('/ar/models');
  static Future<Map<String, dynamic>> arGetModel(int id) =>
      _get('/ar/models/$id');
  static Future<Map<String, dynamic>> arCreateModel(Map<String, dynamic> data,
          {String? filePath}) =>
      _postMultipart('/ar/models', data,
          filePath: filePath, fileField: 'glb_path');
  static Future<Map<String, dynamic>> arUpdateModel(
          int id, Map<String, dynamic> data, {String? filePath}) =>
      _postMultipart('/ar/models/$id', data,
          filePath: filePath, fileField: 'glb_path');
  static Future<Map<String, dynamic>> arDeleteModel(int id) =>
      _delete('/ar/models/$id');

  // AR Markers (Guru + Admin) - with multipart upload
  static Future<Map<String, dynamic>> arGetMarkers() => _get('/ar/markers');
  static Future<Map<String, dynamic>> arGetMarker(int id) =>
      _get('/ar/markers/$id');
  static Future<Map<String, dynamic>> arCreateMarker(Map<String, dynamic> data,
          {String? filePath}) =>
      _postMultipart('/ar/markers', data,
          filePath: filePath, fileField: 'image');
  static Future<Map<String, dynamic>> arUpdateMarker(
          int id, Map<String, dynamic> data, {String? filePath}) =>
      _postMultipart('/ar/markers/$id', data,
          filePath: filePath, fileField: 'image');
  static Future<Map<String, dynamic>> arDeleteMarker(int id) =>
      _delete('/ar/markers/$id');

  // AR Hotspots (Guru + Admin) - with multipart upload
  static Future<Map<String, dynamic>> arGetHotspots() => _get('/ar/hotspots');
  static Future<Map<String, dynamic>> arGetHotspot(int id) =>
      _get('/ar/hotspots/$id');
  static Future<Map<String, dynamic>> arCreateHotspot(Map<String, dynamic> data,
          {String? filePath}) =>
      _postMultipart('/ar/hotspots', data,
          filePath: filePath, fileField: 'image');
  static Future<Map<String, dynamic>> arUpdateHotspot(
          int id, Map<String, dynamic> data, {String? filePath}) =>
      _postMultipart('/ar/hotspots/$id', data,
          filePath: filePath, fileField: 'image');
  static Future<Map<String, dynamic>> arDeleteHotspot(int id) =>
      _delete('/ar/hotspots/$id');

  // AR Mapping (Guru + Admin)
  static Future<Map<String, dynamic>> arGetMappings() => _get('/ar/mappings');
  static Future<Map<String, dynamic>> arGetMarkerModels(int markerId) =>
      _get('/ar/markers/$markerId/models');
  static Future<Map<String, dynamic>> arAttachModel(
          int markerId, int modelId) =>
      _post('/ar/markers/$markerId/attach', {'ar_model_id': modelId});
  static Future<Map<String, dynamic>> arDetachModel(
          int markerId, int modelId) =>
      _delete('/ar/markers/$markerId/detach/$modelId');

  // Public AR (siswa, tanpa auth)
  static Future<Map<String, dynamic>> arGetPublicModels() =>
      _get('/ar/public/models');
  static Future<Map<String, dynamic>> arGetPublicModel(int id) =>
      _get('/ar/public/models/$id');
  static Future<Map<String, dynamic>> arGetModelMarkers(int modelId) =>
      _get('/ar/public/models/$modelId/markers');

  // Multipart upload helper
  static Future<Map<String, dynamic>> _postMultipart(
    String path,
    Map<String, dynamic> fields, {
    String? filePath,
    String fileField = 'file',
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    // Add text fields
    fields.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    // Add file if provided
    if (filePath != null) {
      // File dari image_picker/file_picker ada di cache app. Kalau sudah hilang
      // (cache dibersihkan OS, atau picker mengembalikan path yang tidak bisa
      // dibuka), MultipartFile.fromPath melempar FileSystemException yang
      // sebelumnya tertangkap sebagai "Gagal terhubung ke server" — pesan yang
      // menyesatkan karena jaringan sebenarnya baik-baik saja.
      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException(
          'File tidak ditemukan di perangkat',
          filePath,
        );
      }
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    // Upload perlu budget waktu lebih besar daripada GET/JSON biasa: yang
    // di-timeout adalah seluruh proses kirim body + tunggu header respons.
    // 15 detik (connectionTimeout) terlalu sempit untuk upload di jaringan
    // seluler dan memicu TimeoutException palsu.
    final streamedResponse =
        await request.send().timeout(ApiConfig.uploadTimeout);
    final responseBody = await streamedResponse.stream.bytesToString();
    return _decodeResponse(streamedResponse.statusCode, responseBody, path);
  }

  // ========== V1 API METHODS ==========

  static Future<Map<String, dynamic>> v1GetAppConfig() => _getV1('/app/config');

  static Future<Map<String, dynamic>> v1GetContentVersion() =>
      _getV1('/content/version');

  static Future<Map<String, dynamic>> v1GetArContent() => _getV1('/ar/content');

  static Future<Map<String, dynamic>> v1GetMarkers() => _getV1('/ar/markers');

  static Future<Map<String, dynamic>> _v1Get(String path) async {
    final response = await http
        .get(
          Uri.parse('$v1BaseUrl$path'),
          headers: _headers(),
        )
        .timeout(ApiConfig.connectionTimeout);
    return _decodeResponse(response.statusCode, response.body, path);
  }

  static Future<Map<String, dynamic>> _getV1(String path) => _v1Get(path);
}
