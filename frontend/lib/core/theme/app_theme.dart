import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0A8477);
  static const Color primaryOpacity = Color(0xFF0A8477).withOpacity(0.1);
  static const Color secondary = Color(0xFF636E72);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF2D3436);
  static const onBackground = Color(0xFF2D3436);
  static const outline = Color(0xFFD0D5D8);
  static const surfaceVariant = Color(0xFFECEFF1);
  static const onSurfaceVariant = Color(0xFF454A4E);
  static const error = Color(0xFFC62828);
  static const info = Color(0xFF0288D1);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
}

class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    color: AppColors.onSurface,
  );

  static const displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    color: AppColors.onSurface,
  );

  static const displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    color: AppColors.onSurface,
  );

  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    color: AppColors.onSurface,
  );

  static const headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.3,
    color: AppColors.onSurface,
  );

  static const headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: AppColors.onSurface,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.25,
    color: AppColors.onSurface,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: AppColors.onSurface,
  );

  static const titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.onSecondary,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.onSurface,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.onSurface,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.onSurfaceVariant,
  );

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.onSurface,
  );

  static const labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

class AppAssets {
  static const String splashLogo = 'assets/logo.png';
  static const String markerIcon = 'assets/icons/marker.png';
  static const String arIcon = 'assets/icons/ar.png';
  static const String quizIcon = 'assets/icons/quiz.png';
  static const String profileIcon = 'assets/icons/profile.png';
}

extension ThemeExtension on ThemeData {
  ThemeData copyWith({
    Color? colorScheme,
    TextTheme? textTheme,
  }) {
    return copyWith(
      colorScheme: colorScheme ?? defaultColorScheme,
      textTheme: textTheme ?? defaultTextTheme,
    );
  }
}