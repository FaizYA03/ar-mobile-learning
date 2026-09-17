import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    const webUrl = 'http://127.0.0.1:8000/api';
    const androidUrl = 'http://10.0.2.2:8000/api';
    try {
      if (Platform.isAndroid) return androidUrl;
    } catch (_) {}
    return webUrl;
  }

  static String? _token;

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userRole');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
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

  static Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    return jsonDecode(response.body);
  }

  // Auth
  static Future<Map<String, dynamic>> login({required String email, required String password}) =>
      _post('/login', {'email': email, 'password': password});

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) => _post('/register', {
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

  // Quizzes (public)
  static Future<Map<String, dynamic>> getQuizzes() => _get('/quizzes');
  static Future<Map<String, dynamic>> getQuiz(int id) => _get('/quizzes/$id');
  static Future<Map<String, dynamic>> submitQuiz(int id, List<Map<String, dynamic>> answers) =>
      _post('/quizzes/$id/submit', {'answers': answers});

  // Admin
  static Future<Map<String, dynamic>> adminGetUsers() => _get('/admin/users');
  static Future<Map<String, dynamic>> adminCreateUser(Map<String, dynamic> data) =>
      _post('/admin/users', data);
  static Future<Map<String, dynamic>> adminUpdateUser(int id, Map<String, dynamic> data) =>
      _put('/admin/users/$id', data);
  static Future<Map<String, dynamic>> adminDeleteUser(int id) => _delete('/admin/users/$id');

  // Guru Quizzes
  static Future<Map<String, dynamic>> guruGetQuizzes() => _get('/guru/quizzes');
  static Future<Map<String, dynamic>> guruCreateQuiz(Map<String, dynamic> data) =>
      _post('/guru/quizzes', data);
  static Future<Map<String, dynamic>> guruUpdateQuiz(int id, Map<String, dynamic> data) =>
      _put('/guru/quizzes/$id', data);
  static Future<Map<String, dynamic>> guruDeleteQuiz(int id) => _delete('/guru/quizzes/$id');
  static Future<Map<String, dynamic>> guruAddQuestion(int quizId, Map<String, dynamic> data) =>
      _post('/guru/quizzes/$quizId/questions', data);
  static Future<Map<String, dynamic>> guruDeleteQuestion(int questionId) =>
      _delete('/guru/questions/$questionId');

  // TP/ATP (Siswa / Guru / Admin)
  static Future<Map<String, dynamic>> getTpAtpList() => _get('/tp-atp');
  static Future<Map<String, dynamic>> getTpAtpDetail(int id) => _get('/tp-atp/$id');
  static Future<Map<String, dynamic>> guruCreateTpAtp(Map<String, dynamic> data) =>
      _post('/guru/tp-atp', data);
  static Future<Map<String, dynamic>> guruUpdateTpAtp(int id, Map<String, dynamic> data) =>
      _put('/guru/tp-atp/$id', data);
  static Future<Map<String, dynamic>> guruDeleteTpAtp(int id) =>
      _delete('/guru/tp-atp/$id');

  // Materi (Siswa / Guru / Admin)
  static Future<Map<String, dynamic>> getMateriList({int? tpAtpId}) {
    final query = tpAtpId != null ? '?tp_atp_id=$tpAtpId' : '';
    return _get('/materi$query');
  }
  static Future<Map<String, dynamic>> getMateriDetail(int id) => _get('/materi/$id');

  // Guru Materi (with multipart file upload support)
  static Future<Map<String, dynamic>> guruCreateMateri(Map<String, dynamic> data, {String? filePath}) =>
      _postMultipart('/guru/materi', data, filePath: filePath, fileField: 'gambar_cover');

  static Future<Map<String, dynamic>> guruUpdateMateri(int id, Map<String, dynamic> data, {String? filePath}) =>
      _postMultipart('/guru/materi/$id', data, filePath: filePath, fileField: 'gambar_cover');

  static Future<Map<String, dynamic>> guruDeleteMateri(int id) =>
      _delete('/guru/materi/$id');

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
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    return jsonDecode(responseBody);
  }
}