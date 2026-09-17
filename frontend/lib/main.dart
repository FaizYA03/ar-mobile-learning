import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'student_dashboard.dart';

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
    _loadSharedPreferences();
  }

  Future<void> _loadSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      _userRole = prefs.getString('userRole');
      _userName = prefs.getString('userName');
    });
  }

  Future<void> _saveSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', _hasSeenOnboarding);
    if (_userRole != null) {
      await prefs.setString('userRole', _userRole!);
    }
    if (_userName != null) {
      await prefs.setString('userName', _userName!);
    }
  }

  Route<dynamic>? _route(RouteSettings? settings) {
    if (!_hasSeenOnboarding) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
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
          onSurface: Color(0xFF2D3436),
          error: Color(0xFFC62828),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF2D3436),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0A8477),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF0A8477),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF637080),
          ),
          labelStyle: const TextStyle(
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0D5D8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0D5D8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(Color(0xFF0A8477), width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: _route,
    );
  }
}