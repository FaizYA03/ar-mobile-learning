import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

/// Layar profil dipakai semua role (siswa/guru/admin).
/// - Lihat + ubah nama
/// - Upload avatar
/// - Ganti password
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  /// Bangun URL absolut avatar dari payload API.
  /// Pure helper agar bisa di-unit-test.
  static String? resolveAvatarUrl(String baseUrl, Map<String, dynamic> data) {
    final direct = data['avatar_url'] as String?;
    if (direct != null && direct.isNotEmpty) {
      if (direct.startsWith('http')) return direct;
    }
    var path = (data['avatar'] as String?) ?? '';
    if (path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    var normalized = path.startsWith('storage/') ? path.substring(8) : path;
    normalized =
        normalized.startsWith('/') ? normalized.substring(1) : normalized;
    final base = baseUrl.replaceFirst('/api', '');
    return '$base/storage/$normalized';
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSavingName = false;
  bool _isSavingPassword = false;
  bool _isUploadingAvatar = false;
  bool _changed = false;
  String? _errorMessage;

  String _name = '';
  String _email = '';
  String _role = '';
  String? _avatarUrl;

  final _nameCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true && mounted) {
        final data = Map<String, dynamic>.from(res['data'] ?? {});
        setState(() {
          _name = '${data['name'] ?? ''}';
          _email = '${data['email'] ?? ''}';
          _role = '${data['role'] ?? ''}';
          _avatarUrl = ProfileScreen.resolveAvatarUrl(ApiConfig.baseUrl, data);
          _nameCtrl.text = _name;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = '${res['message'] ?? 'Gagal memuat profil'}';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal terhubung ke server.';
          _isLoading = false;
        });
      }
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? const Color(0xFFC62828) : const Color(0xFF0A8477),
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Nama wajib diisi', error: true);
      return;
    }
    setState(() => _isSavingName = true);
    try {
      final res = await ApiService.updateProfile(name: name);
      if (res['success'] == true && mounted) {
        await SecureStorageService.saveUserName(name);
        setState(() {
          _name = name;
          _changed = true;
          _isSavingName = false;
        });
        _snack('Profil berhasil diperbarui');
      } else {
        if (mounted) setState(() => _isSavingName = false);
        _snack('${res['message'] ?? 'Gagal menyimpan profil'}', error: true);
      }
    } catch (_) {
      if (mounted) setState(() => _isSavingName = false);
      _snack('Gagal terhubung ke server.', error: true);
    }
  }

  Future<void> _changePassword() async {
    if (_newPwCtrl.text.length < 6) {
      _snack('Password baru minimal 6 karakter', error: true);
      return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _snack('Konfirmasi password tidak cocok', error: true);
      return;
    }
    setState(() => _isSavingPassword = true);
    try {
      final res = await ApiService.updatePassword(
        currentPassword: _currentPwCtrl.text,
        password: _newPwCtrl.text,
        passwordConfirmation: _confirmPwCtrl.text,
      );
      if (res['success'] == true && mounted) {
        _currentPwCtrl.clear();
        _newPwCtrl.clear();
        _confirmPwCtrl.clear();
        setState(() => _isSavingPassword = false);
        _snack('Password berhasil diubah');
      } else {
        if (mounted) setState(() => _isSavingPassword = false);
        final errors = res['errors'];
        final detail = errors is Map && errors.isNotEmpty
            ? '${(errors.values.first as List).first}'
            : '${res['message'] ?? 'Gagal mengubah password'}';
        _snack(detail, error: true);
      }
    } catch (_) {
      if (mounted) setState(() => _isSavingPassword = false);
      _snack('Gagal terhubung ke server.', error: true);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final res = await ApiService.uploadAvatar(filePath: picked.path);
      if (res['success'] == true && mounted) {
        final data = Map<String, dynamic>.from(res['data'] ?? {});
        setState(() {
          _avatarUrl = ProfileScreen.resolveAvatarUrl(ApiConfig.baseUrl, data);
          _isUploadingAvatar = false;
        });
        _snack('Avatar berhasil diperbarui');
      } else {
        if (mounted) setState(() => _isUploadingAvatar = false);
        _snack('${res['message'] ?? 'Gagal mengunggah avatar'}', error: true);
      }
    } catch (_) {
      if (mounted) setState(() => _isUploadingAvatar = false);
      _snack('Gagal terhubung ke server.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Profil Saya'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A2E),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0A8477)))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!,
                            style: const TextStyle(color: Color(0xFF637080))),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchProfile,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFF0A8477)
                                  .withValues(alpha: 0.1),
                              backgroundImage: _avatarUrl != null
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                              child: _avatarUrl != null
                                  ? null
                                  : const Icon(Icons.person,
                                      size: 48, color: Color(0xFF0A8477)),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _isUploadingAvatar
                                    ? null
                                    : _pickAndUploadAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0A8477),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isUploadingAvatar
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt,
                                          size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                        Text(_email,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF637080))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0A8477).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_role.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0A8477))),
                        ),
                        const SizedBox(height: 24),
                        _sectionCard(
                          title: 'Ubah Nama',
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama lengkap',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSavingName ? null : _saveName,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A8477),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(14),
                                ),
                                child: _isSavingName
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Simpan Nama'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: 'Ganti Password',
                          children: [
                            TextField(
                              controller: _currentPwCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password saat ini',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPwCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password baru (min. 6)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPwCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Konfirmasi password baru',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed:
                                    _isSavingPassword ? null : _changePassword,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(14),
                                ),
                                child: _isSavingPassword
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Ubah Password'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
