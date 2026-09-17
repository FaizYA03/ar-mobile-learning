import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  String _userName = 'Siswa';
  int _totalQuizzes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? 'Siswa';
    try {
      final result = await ApiService.getDashboard();
      if (result['success'] == true && mounted) {
        setState(() {
          _totalQuizzes = result['data']['stats']['total_quizzes'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout', style: TextStyle(color: Color(0xFFC62828)))),
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
            const _ComingSoonPage(title: 'Materi'),
            const _ComingSoonPage(title: 'AR 3D'),
            const _ComingSoonPage(title: 'Quiz'),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Materi'),
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar_outlined), activeIcon: Icon(Icons.view_in_ar), label: 'AR'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), activeIcon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, $_userName 👋', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('Mari lanjutkan belajar', style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
          const SizedBox(height: 24),
          _buildProgressCard(),
          const SizedBox(height: 20),
          const Text('Pilih Pembelajaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          _buildLearningCard(icon: Icons.book_outlined, title: 'Materi', subtitle: 'Pelajari materi Informatika', color: const Color(0xFF0A8477)),
          const SizedBox(height: 12),
          _buildLearningCard(icon: Icons.view_in_ar_outlined, title: 'AR 3D', subtitle: 'Lihat objek pembelajaran 3D', color: const Color(0xFF5B6ABF)),
          const SizedBox(height: 12),
          _buildLearningCard(icon: Icons.quiz_outlined, title: 'Quiz', subtitle: '$_totalQuizzes quiz tersedia', color: const Color(0xFFE67E22)),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0A8477), Color(0xFF0D9E8F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress Pembelajaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressItem('Materi', '0/5'),
              _buildProgressItem('AR', '0/3'),
              _buildProgressItem('Quiz', '0/$_totalQuizzes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
    ]);
  }

  Widget _buildLearningCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF637080))),
          ],
        )),
        const Icon(Icons.chevron_right, color: Color(0xFFD0D5D8)),
      ]),
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
            child: const Icon(Icons.person, size: 48, color: Color(0xFF0A8477)),
          ),
          const SizedBox(height: 16),
          Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('Siswa', style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
          const SizedBox(height: 32),
          _buildProfileOption(icon: Icons.person_outline, title: 'Profil Saya', onTap: () {}),
          _buildProfileOption(icon: Icons.help_outline, title: 'Bantuan', onTap: () {}),
          _buildProfileOption(icon: Icons.info_outline, title: 'Tentang', onTap: () {}),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
              label: const Text('Logout', style: TextStyle(color: Color(0xFFC62828))),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFC62828)), padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0A8477)),
        title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFD0D5D8)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  const _ComingSoonPage({required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.construction, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 8),
      const Text('Segera hadir', style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
    ]));
  }
}