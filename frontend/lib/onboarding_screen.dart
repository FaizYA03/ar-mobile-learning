import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'services/app_config_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<IconData> _slideIcons = [
    Icons.menu_book_rounded,
    Icons.view_in_ar_rounded,
    Icons.quiz_rounded,
    Icons.school_rounded,
    Icons.lightbulb_rounded,
  ];

  List<OnboardingSlideData> get _slides =>
      AppConfigService.config?.onboardingSlides ?? AppConfigData.defaultSlides;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _onSkip() {
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    // Ikon berputar mengikuti jumlah slide (maks 5 dari CMS).
    final icons = List<IconData>.generate(
      slides.length,
      (i) => _slideIcons[i % _slideIcons.length],
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: [
                  for (var i = 0; i < slides.length; i++)
                    _OnboardingSlide(
                      icon: icons[i],
                      title: slides[i].title,
                      description: slides[i].description,
                    ),
                ],
              ),
            ),
            _buildIndicator(slides.length),
            const SizedBox(height: 12),
            _buildButtons(slides.length),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? const Color(0xFF0A8477)
                : const Color(0xFFD0D5D8),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildButtons(int slideCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _currentIndex == slideCount - 1
          ? SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mulai Belajar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : Row(
              children: [
                if (_currentIndex > 0)
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF637080),
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 80),
                const Spacer(),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A8477),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 80),
              ],
            ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF0A8477).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, size: 72, color: const Color(0xFF0A8477)),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF637080),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
