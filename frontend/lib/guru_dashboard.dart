import 'package:flutter/material.dart';

class GuruDashboard extends StatefulWidget {
  const GuruDashboard({super.key});

  @override
  State<GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<GuruDashboard> {
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
            const _ComingSoonPage(title: 'Quiz'),
            const _ComingSoonPage(title: 'Profil'),
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
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Konten',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
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
            'Halo, Guru 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kelola pembelajaran Anda',
            style: TextStyle(fontSize: 14, color: Color(0xFF637080)),
          ),
          const SizedBox(height: 24),
          _buildSummaryRow(),
          const SizedBox(height: 20),
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          _buildQuickAction(
            icon: Icons.add_circle_outline,
            title: 'Tambah Materi',
            color: const Color(0xFF0A8477),
          ),
          const SizedBox(height: 10),
          _buildQuickAction(
            icon: Icons.view_in_ar_outlined,
            title: 'Buat AR',
            color: const Color(0xFF5B6ABF),
          ),
          const SizedBox(height: 10),
          _buildQuickAction(
            icon: Icons.quiz_outlined,
            title: 'Buat Quiz',
            color: const Color(0xFFE67E22),
          ),
          const SizedBox(height: 24),
          const Text(
            'Manajemen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          _buildManagementCard(
            icon: Icons.track_changes_outlined,
            title: 'TP / ATP',
            subtitle: 'Kelola tujuan pembelajaran',
          ),
          const SizedBox(height: 10),
          _buildManagementCard(
            icon: Icons.menu_book_outlined,
            title: 'Materi',
            subtitle: 'Buat, edit, dan hapus materi',
          ),
          const SizedBox(height: 10),
          _buildManagementCard(
            icon: Icons.view_in_ar_outlined,
            title: 'AR Content',
            subtitle: 'Marker, model 3D, hotspot',
          ),
          const SizedBox(height: 10),
          _buildManagementCard(
            icon: Icons.quiz_outlined,
            title: 'Quiz',
            subtitle: 'Buat dan kelola quiz',
          ),
          const SizedBox(height: 10),
          _buildManagementCard(
            icon: Icons.assessment_outlined,
            title: 'Hasil Quiz',
            subtitle: 'Lihat hasil siswa',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('12', 'Materi', const Color(0xFF0A8477)),
          _buildSummaryItem('5', 'AR', const Color(0xFF5B6ABF)),
          _buildSummaryItem('8', 'Quiz', const Color(0xFFE67E22)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF637080)),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0A8477), size: 22),
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
          const Icon(Icons.chevron_right, color: Color(0xFFD0D5D8)),
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