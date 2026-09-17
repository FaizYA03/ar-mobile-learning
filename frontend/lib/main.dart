import 'package:flutter/material.dart';
import 'package:ar_mobile_learning/core/theme/app_theme.dart';
import 'package:ar_mobile_learning/screens/splash_screen.dart';
import 'package:ar_mobile_learning/screens/onboarding_screen.dart';
import 'package:ar_mobile_learning/screens/login_screen.dart';
import 'package:ar_mobile_learning/screens/student_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ARMobileLearningApp());
}

class ARMobileLearningApp extends StatefulWidget {
  const ARMobileLearningApp({super.key});

  @override
  State<ARMobileLearningApp> createState() => _ARMobileLearningAppState();
}

class _ARMobileLearningAppState extends State<ARMobileLearningApp> {
  bool _hasSeenOnboarding = false;
  String? _userRole;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // TODO: Replace with actual shared preferences / local storage
    // For now, simulate first launch
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _hasSeenOnboarding = true;
      _userRole = 'siswa'; // Default role for demo
      _userName = 'Andi Saputra';
    });
  }

  Route<dynamic> _routeForRole() {
    if (!_hasSeenOnboarding) {
      return _routeSplash();
    }
    return _routeAfterOnboarding();
  }

  Route<dynamic> _routeSplash() {
    return MaterialPageRoute(builder: (_) => const SplashScreen());
  }

  Route<dynamic> _routeAfterOnboarding() {
    if (_userRole == null) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
    return MaterialPageRoute(
      builder: (_) => StudentDashboard(
        studentName: _userName!,
        role: _userRole!,
      ),
    );
  }

  void _markOnboardingSeen() {
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Mobile Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      onGenerateRoute: _routeForRole,
    );
  }
}