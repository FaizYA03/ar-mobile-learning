import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/app_config_service.dart';
import 'services/secure_storage_service.dart';
import 'screens/tp_atp_screen.dart';
import 'screens/ar_hub_screen.dart';
import 'screens/quiz_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/info_screen.dart';
import 'widgets/announcement_banner.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  String _userName = 'Siswa';
  String? _avatarUrl;
  int _totalQuizzes = 0;
  int _totalMateri = 0;
  int _totalArModels = 0;
  int _quizzesPassed = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String _lastSyncText = 'Belum pernah sync';
  int _cachedModelCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      try {
        _userName = await SecureStorageService.getUserName().timeout(
              const Duration(seconds: 5),
            ) ??
            'Siswa';
      } catch (_) {
        _userName = 'Siswa';
      }

      try {
        _avatarUrl = await SecureStorageService.getUserAvatar().timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {
        _avatarUrl = null;
      }

      try {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 5),
        );
        final lastSyncMs = prefs.getInt('content_last_sync');
        if (lastSyncMs != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
          final diff = DateTime.now().difference(dt);
          if (diff.inMinutes < 1) {
            _lastSyncText = 'Baru saja';
          } else if (diff.inHours < 1) {
            _lastSyncText = '${diff.inMinutes} menit lalu';
          } else if (diff.inDays < 1) {
            _lastSyncText = '${diff.inHours} jam lalu';
          } else {
            _lastSyncText = '${diff.inDays} hari lalu';
          }
        }
        _cachedModelCount = prefs.getInt('cached_ar_model_count') ?? 0;
      } catch (_) {}

      final result = await ApiService.getDashboard().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted) return;
      // Token kedaluwarsa/dihapus dari server -> paksa login ulang,
      // jangan spinner selamanya di layar putih.
      if (result['unauthorized'] == true) {
        await ApiService.clearToken();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      if (result['success'] == true) {
        final data = result['data'];
        final stats = (data is Map ? data['stats'] : null) as Map? ?? {};
        setState(() {
          _totalQuizzes = (stats['total_quizzes'] as num?)?.toInt() ?? 0;
          _totalMateri = (stats['total_materi'] as num?)?.toInt() ?? 0;
          _totalArModels = (stats['total_ar_models'] as num?)?.toInt() ?? 0;
          _quizzesPassed = (stats['quizzes_passed'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              (result['message'] as String?) ?? 'Gagal memuat dashboard.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gagal terhubung ke server. Periksa koneksi lalu coba lagi.';
        });
      }
    }
  }

  Future<void> _openProfile() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (changed == true && mounted) {
      final name = await SecureStorageService.getUserName() ?? 'Siswa';
      final avatar = await SecureStorageService.getUserAvatar();
      setState(() {
        _userName = name;
        _avatarUrl = avatar;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout',
                  style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHome(),
            const TpAtpScreen(),
            const ArHubScreen(),
            const QuizListScreen(),
            _buildProfile(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0A8477),
        unselectedItemColor: const Color(0xFFB0B8C1),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Materi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.view_in_ar_outlined),
              activeIcon: Icon(Icons.view_in_ar),
              label: 'AR'),
          BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz),
              label: 'Quiz'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    }
    // Gagal koneksi/backend: tampilkan pesan + tombol retry,
    // jangan halaman kosong.
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: Color(0xFFB0B8C1)),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF637080)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, $_userName 👋',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text(
              AppConfigService.config?.greetingSiswa ??
                  'Mari lanjutkan belajar',
              style: const TextStyle(fontSize: 14, color: Color(0xFF637080))),
          const AnnouncementBanner(),
          const SizedBox(height: 24),
          _buildSyncStatusCard(),
          const SizedBox(height: 20),
          _buildProgressCard(),
          const SizedBox(height: 20),
          const Text('Pilih Pembelajaran',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          _buildLearningCard(
              icon: Icons.book_outlined,
              title: 'Materi',
              subtitle: 'Pelajari materi Informatika',
              color: const Color(0xFF0A8477),
              onTap: () => setState(() => _currentIndex = 1)),
          const SizedBox(height: 12),
          _buildLearningCard(
              icon: Icons.view_in_ar_outlined,
              title: 'AR 3D',
              subtitle: 'Lihat objek pembelajaran 3D',
              color: const Color(0xFF5B6ABF),
              onTap: () => setState(() => _currentIndex = 2)),
          const SizedBox(height: 12),
          _buildLearningCard(
              icon: Icons.quiz_outlined,
              title: 'Quiz',
              subtitle: '$_totalQuizzes quiz tersedia',
              color: const Color(0xFFE67E22),
              onTap: () => setState(() => _currentIndex = 3)),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0A8477), Color(0xFF0D9E8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress Pembelajaran',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressItem('Materi', '$_totalMateri'),
              _buildProgressItem('AR', '$_totalArModels'),
              _buildProgressItem('Quiz', '$_quizzesPassed/$_totalQuizzes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
    ]);
  }

  Widget _buildSyncStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.sync, color: Color(0xFF0A8477), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sinkronisasi Konten',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text('Terakhir: $_lastSyncText',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF637080))),
              ],
            ),
          ),
          if (_cachedModelCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('$_cachedModelCount model',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A8477))),
            ),
        ],
      ),
    );
  }

  Widget _buildLearningCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF637080))),
            ],
          )),
          const Icon(Icons.chevron_right, color: Color(0xFFD0D5D8)),
        ]),
      ),
    );
  }

  Widget _buildProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFF0A8477).withValues(alpha: 0.1),
            backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                ? NetworkImage(_avatarUrl!)
                : null,
            child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                ? null
                : const Icon(Icons.person, size: 48, color: Color(0xFF0A8477)),
          ),
          const SizedBox(height: 16),
          Text(_userName,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('Siswa',
              style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
          const SizedBox(height: 32),
          _buildProfileOption(
              icon: Icons.person_outline,
              title: 'Profil Saya',
              onTap: _openProfile),
          _buildProfileOption(
              icon: Icons.help_outline,
              title: 'Bantuan',
              onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InfoScreen.help()),
                  )),
          _buildProfileOption(
              icon: Icons.info_outline,
              title: 'Tentang',
              onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InfoScreen.about()),
                  )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
              label: const Text('Logout',
                  style: TextStyle(color: Color(0xFFC62828))),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC62828)),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0A8477)),
        title: Text(title,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFD0D5D8)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
      ),
    );
  }
}
