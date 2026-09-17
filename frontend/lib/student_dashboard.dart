import 'package:flutter/material.dart';
import 'package:ar_mobile_learning/core/theme/app_theme.dart';
import 'package:ar_mobile_learning/core/widgets/common_widgets.dart';

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
        foregroundColor: AppColors.onSurface,
        title: AppBarTitle(
          title: 'Dashboard',
          showBackButton: false,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.xl),
            _buildProgressSection(),
            const SizedBox(height: AppSpacing.xl),
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
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Mari lanjutkan belajar',
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Pembelajaran',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
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
          onTap: () {
            // TODO: Navigate to materi
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _buildOptionCard(
          context,
          icon: Icons.qr_code,
          title: 'AR 3D',
          subtitle: 'Belajar menggunakan AR',
          onTap: () {
            // TODO: Navigate to AR
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _buildOptionCard(
          context,
          icon: Icons.quiz,
          title: 'Quiz',
          subtitle: 'Uji pemahamanmu',
          onTap: () {
            // TODO: Navigate to quiz
          },
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
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}