import 'package:flutter/material.dart';
import 'package:ar_mobile_learning/core/theme/app_theme.dart';
import 'package:ar_mobile_learning/core/widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final Function()? onSkip;
  final Function()? onNext;

  const OnboardingScreen({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    this.onSkip,
    this.onNext,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum OnboardingSlide { slide1, slide2, slide3 }

class _OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingSlide _currentSlide = OnboardingSlide.slide1;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(() {
      final page = widget.pageController.page!.round();
      setState(() {
        _currentSlide = OnboardingSlide.values.pageFromIndex(page);
      });
    });
  }

  @override
  void dispose() {
    widget.pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: widget.pageController,
            onPageChanged: widget.onPageChanged,
            children: const [
              _OnboardingSlide1(),
              _OnboardingSlide2(),
              _OnboardingSlide3(),
            ],
          ),
          _buildBottomIndicator(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildBottomIndicator() {
    return Positioned(
      bottom: AppSpacing.lg,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentSlide.index == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentSlide.index == index
                  ? AppColors.primary
                  : AppColors.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: AppSpacing.xl,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentSlide != OnboardingSlide.slide1)
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip'),
            ),
          if (_currentSlide == OnboardingSlide.slide3)
            PrimaryButton(
              title: 'Mulai Belajar',
              onPressed: widget.onNext,
              expanded: true,
            )
          else
            PrimaryButton(
              title: 'Next',
              onPressed: () {
                widget.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              expanded: true,
            ),
        ],
      ),
    );
  }
}

class _OnboardingSlide1 extends StatelessWidget {
  const _OnboardingSlide1();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belajar Informatika Lebih Menarik',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pelajari konsep Informatika melalui materi yang terstruktur dan mudah dipahami.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide2 extends StatelessWidget {
  const _OnboardingSlide2();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Temukan Dunia 3D',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Scan marker dan lihat objek pembelajaran dalam bentuk 3D secara interaktif.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide3 extends StatelessWidget {
  const _OnboardingSlide3();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.quiz_rounded,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Uji Pemahamanmu',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Uji pemahaman setelah belajar dan lihat hasilnya.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}