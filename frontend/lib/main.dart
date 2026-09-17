import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'student_dashboard.dart';
import 'guru_dashboard.dart';
import 'admin_dashboard.dart';

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
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadSharedPreferences();
  }

  Future<void> _loadSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      _userRole = prefs.getString('userRole');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Mobile Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0A8477),
          surface: Colors.white,
          onSurface: Color(0xFF1A1A2E),
          error: Color(0xFFC62828),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF1A1A2E),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => _isLoading
            ? const Scaffold(
                backgroundColor: Color(0xFF0A8477),
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : _buildInitialRoute(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/siswa': (context) => const StudentDashboard(),
        '/guru': (context) => const GuruDashboard(),
        '/admin': (context) => const AdminDashboard(),
      },
    );
  }

  Widget _buildInitialRoute() {
    if (!_hasSeenOnboarding) {
      return const SplashScreen();
    }
    if (_userRole == null) {
      return const LoginScreen();
    }
    switch (_userRole) {
      case 'siswa':
        return const StudentDashboard();
      case 'guru':
        return const GuruDashboard();
      case 'admin':
        return const AdminDashboard();
      default:
        return const LoginScreen();
    }
  }
}