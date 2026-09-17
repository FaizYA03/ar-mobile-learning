import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHome(),
            const _ComingSoonPage(title: 'Konten'),
            const _ComingSoonPage(title: 'AR'),
            const _ComingSoonPage(title: 'Pengaturan'),
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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Konten',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar_outlined),
            activeIcon: Icon(Icons.view_in_ar),
            label: 'AR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Panel 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kelola seluruh sistem',
            style: TextStyle(fontSize: 14, color: Color(0xFF637080)),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('User Management'),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.people_outline,
            title: 'Users',
            subtitle: 'Kelola semua pengguna',
            count: '45',
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            icon: Icons.school_outlined,
            title: 'Guru',
            subtitle: 'Kelola akun guru',
            count: '12',
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            icon: Icons.person_outline,
            title: 'Siswa',
            subtitle: 'Kelola akun siswa',
            count: '33',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Learning Content'),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.track_changes_outlined,
            title: 'TP / ATP',
            subtitle: 'Kelola tujuan pembelajaran',
            count: '24',
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            icon: Icons.menu_book_outlined,
            title: 'Materi',
            subtitle: 'Kelola materi pembelajaran',
            count: '18',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('AR Management'),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.qr_code_scanner_outlined,
            title: 'Marker',
            subtitle: 'Kelola marker AR',
            count: '8',
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            icon: Icons.view_in_ar_outlined,
            title: 'Model 3D',
            subtitle: 'Kelola model 3D',
            count: '10',
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            icon: Icons.link_outlined,
            title: 'Marker → Model',
            subtitle: 'Relasi marker dan model',
            count: '10',
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            icon: Icons.info_outline,
            title: 'Hotspot',
            subtitle: 'Kelola hotspot / penjelasan AR',
            count: '15',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Quiz'),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.quiz_outlined,
            title: 'Quiz',
            subtitle: 'Kelola quiz',
            count: '8',
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            icon: Icons.help_outline,
            title: 'Soal & Opsi',
            subtitle: 'Kelola soal dan opsi jawaban',
            count: '64',
          ),
          const SizedBox(height: 10),
          _buildAdminCard(
            icon: Icons.assessment_outlined,
            title: 'Hasil',
            subtitle: 'Lihat hasil quiz siswa',
            count: '120',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String count,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0A8477).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0A8477), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF637080),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A8477).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A8477),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  const _ComingSoonPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Segera hadir',
            style: TextStyle(fontSize: 14, color: Color(0xFF637080)),
          ),
        ],
      ),
    );
  }
}