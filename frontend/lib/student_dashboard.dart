import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  final String studentName;
  final String role;

  const StudentDashboard({
    super.key,
    required this.studentName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2D3436),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildProgressSection(),
            const SizedBox(height: 24),
            _buildLearningOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $studentName 👋',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w300,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mari lanjutkan belajar',
          style: TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Pembelajaran',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressItem(
              icon: Icons.menu_book,
              title: 'Materi',
              value: '3/5 materi dilihat',
            ),
            _buildProgressItem(
              icon: Icons.qr_code,
              title: 'AR 3D',
              value: '2/3 marker discan',
            ),
            _buildProgressItem(
              icon: Icons.quiz,
              title: 'Quiz',
              value: '1/2 quiz dikerjakan',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
color: Color(0xFF0A8477),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF0A8477), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF637080),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOptionCard(
          context,
          icon: Icons.book,
          title: 'Materi',
          subtitle: 'Pelajari materi Informatika',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          context,
          icon: Icons.qr_code,
          title: 'AR 3D',
          subtitle: 'Belajar menggunakan AR',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          context,
          icon: Icons.quiz,
          title: 'Quiz',
          subtitle: 'Uji pemahamanmu',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
color: Color(0x1A0A8477),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Color(0xFF0A8477), size: 28),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
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
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Color(0xFFD0D5D8)),
            ],
          ),
        ),
      ),
    );
  }
}