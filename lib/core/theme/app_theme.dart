import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../constants/app_colors.dart' as dash_colors;

/// Application Theme Configuration
class AppTheme {
  AppTheme._();

  /// Dark theme used by the Login / Login Permission / Roles / Student
  /// Enroll & List screens (glassmorphism auth design, Plus Jakarta Sans).
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.airaTeal,
      scaffoldBackgroundColor: AppColors.surfaceBright,
      colorScheme: ColorScheme.dark(
        primary: AppColors.airaTeal,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.inkPrimary,
        onError: Colors.white,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLow,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.inkPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.inkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.airaTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        errorStyle: const TextStyle(color: AppColors.error),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.airaTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.airaTeal,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Text Theme - Using Plus Jakarta Sans (matching frontend)
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.inkPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.textMuted),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }

  /// Light theme used by the Dashboard / School Tenancy / Administration /
  /// Admissions / Attendance screens (matches web design tokens 1:1).
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: dash_colors.AppColors.brandPurple,
      scaffoldBackgroundColor: dash_colors.AppColors.bg0,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: dash_colors.AppColors.brandPurple,
        secondary: dash_colors.AppColors.brandPurple,
        surface: dash_colors.AppColors.bg1,
        error: dash_colors.AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: dash_colors.AppColors.ink1,
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: dash_colors.AppColors.bg1,
        foregroundColor: dash_colors.AppColors.ink1,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: dash_colors.AppColors.ink1,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: dash_colors.AppColors.bg1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: dash_colors.AppColors.border, width: 1),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
          letterSpacing: -0.02,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
          letterSpacing: -0.02,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
          letterSpacing: -0.02,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
          letterSpacing: -0.02,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
          letterSpacing: -0.02,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
          letterSpacing: -0.02,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: dash_colors.AppColors.ink2,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: dash_colors.AppColors.ink2,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: dash_colors.AppColors.ink3,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink2,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink2,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: dash_colors.AppColors.ink3,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dash_colors.AppColors.bg1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dash_colors.AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dash_colors.AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: dash_colors.AppColors.brandPurple,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dash_colors.AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dash_colors.AppColors.brandPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dash_colors.AppColors.brandPurple,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: dash_colors.AppColors.ink2,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dash_colors.AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
