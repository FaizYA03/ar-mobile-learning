import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'services/secure_storage_service.dart';
import 'services/api_client.dart';
import 'services/content_sync_service.dart';
import 'services/app_config_service.dart';
import 'services/ar_content_resolver.dart';
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
  AppConfigData? _appConfig;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    final token = await SecureStorageService.getToken();
    if (token != null) {
      _userRole = await SecureStorageService.getUserRole();
      ApiClient.setToken(token);

      await Future.wait([
        _fetchAppConfig(),
        _syncContent(),
      ]);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAppConfig() async {
    try {
      _appConfig = await AppConfigService.fetchConfig().timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {}
  }

  Future<void> _syncContent() async {
    try {
      final syncResult = await ContentSyncService.sync().timeout(
        const Duration(seconds: 15),
      );
      await ArContentResolver.refreshContent().timeout(
        const Duration(seconds: 10),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('content_last_sync', DateTime.now().millisecondsSinceEpoch);
      if (syncResult.manifest != null) {
        final modelCount = syncResult.manifest!.items
            .where((i) => i.assetType == 'model')
            .length;
        await prefs.setInt('cached_ar_model_count', modelCount);
      }
    } catch (_) {}
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

    if (_appConfig != null && _appConfig!.maintenanceMode) {
      return _buildMaintenanceScreen();
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

  Widget _buildMaintenanceScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9A825).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  size: 40,
                  color: Color(0xFFF9A825),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Aplikasi sedang dalam pemeliharaan.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan coba lagi nanti.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF637080),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}