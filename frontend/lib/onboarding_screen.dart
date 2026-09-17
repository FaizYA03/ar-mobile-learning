import 'package:flutter/material.dart';

enum OnboardingSlide { slide1, slide2, slide3 }

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

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(() {
      final page = widget.pageController.page!.round();
      setState(() {
        _currentIndex = page;
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
      bottom: 24,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentIndex == index ? Color(0xFF0A8477) : Color(0xFFD0D5D8),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentIndex != 0)
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip'),
            ),
          if (_currentIndex == 2)
            ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A8477),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Mulai Belajar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                widget.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A8477),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.school,
            size: 80,
            color: Color(0xFF0A8477),
          ),
          const SizedBox(height: 16),
          Text(
            'Belajar Informatika Lebih Menarik',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
              color: Color(0xFF2D3436),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pelajari konsep Informatika melalui materi yang terstruktur dan mudah dipahami.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF636E72),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide2 extends StatelessWidget {
  const _OnboardingSlide2();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: Color(0xFF0A8477),
          ),
          const SizedBox(height: 16),
          Text(
            'Temukan Dunia 3D',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
              color: Color(0xFF2D3436),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan marker dan lihat objek pembelajaran dalam bentuk 3D secara interaktif.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF636E72),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide3 extends StatelessWidget {
  const _OnboardingSlide3();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.quiz_rounded,
            size: 80,
            color: Color(0xFF0A8477),
          ),
          const SizedBox(height: 16),
          Text(
            'Uji Pemahamanmu',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
              color: Color(0xFF2D3436),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Uji pemahaman setelah belajar dan lihat hasilnya.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF636E72),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}