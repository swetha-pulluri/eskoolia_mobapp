import 'package:flutter/material.dart';

/// Application Color Palette
/// EXACT 1:1 match with frontend/app/globals.css auth design tokens
/// Source: .gateway-shell, .auth-flow-shell CSS variables
class AppColors {
  AppColors._();

  // ═══ Auth Screen Design Tokens (from frontend CSS) ═══

  // Core Gateway Colors
  static const Color surfaceBright = Color(0xFFF5FAF8); // --surface-bright
  static const Color atriumIndigo = Color(0xFF312E81); // --atrium-indigo
  static const Color onBackground = Color(0xFF171D1C); // --on-background
  static const Color onSurfaceVariant = Color(
    0xFF3D4947,
  ); // --on-surface-variant
  static const Color outline = Color(0xFF6D7A77); // --outline
  static const Color outlineVariant = Color(0xFFBCC9C6); // --outline-variant
  static const Color surfaceVariant = Color(0xFFDEE4E1); // --surface-variant
  static const Color surfaceContainerLow = Color(
    0xFFF0F5F2,
  ); // --surface-container-low
  static const Color surfaceContainer = Color(
    0xFFEAEFED,
  ); // --surface-container

  // Brand Colors
  static const Color airaTeal = Color(0xFF0D9488); // --aira-teal (primary teal)
  static const Color saffron = Color(0xFFFF9933); // --saffron (orange)
  static const Color deepSaffron = Color(0xFFE67E22); // --deep-saffron
  static const Color marigold = Color(0xFFFFB81C); // --marigold (yellow)
  static const Color secondary = Color(
    0xFF4E45D5,
  ); // --secondary (indigo/purple)

  // Glassmorphism
  static const Color glassStroke = Color(0x66FFFFFF); // rgba(255,255,255,0.4)
  static const Color glassCardBackground = Color(
    0xE6FFFFFF,
  ); // rgba(255,255,255,0.9)
  static const Color glassPanelBackground = Color(
    0xB3FFFFFF,
  ); // rgba(255,255,255,0.7)
  static const Color glassFeatureCard = Color(
    0x99FFFFFF,
  ); // rgba(255,255,255,0.6)

  // Background Gradient Blobs
  static const Color auraTealBlob = Color(0x400D9488); // rgba(13,148,136,0.25)
  static const Color auraSaffronBlob = Color(
    0x4DFF9933,
  ); // rgba(255,153,51,0.3)

  // Text Colors (Auth Specific)
  static const Color textPrimary = onBackground; // #171d1c
  static const Color textMuted = onSurfaceVariant; // #3d4947
  static const Color textHeading = atriumIndigo; // #312e81

  // Status Colors
  static const Color success = Color(0xFF10B981); // green-500
  static const Color error = Color(0xFFDC2626); // red-600
  static const Color statusActive = Color(0xFF10B981); // for status dot

  // Feature Card Accent Colors (for hover states)
  static const Color tealAccent = Color(0x1A0D9488); // rgba(13,148,136,0.1)
  static const Color saffronAccent = Color(0x1AFF9933); // rgba(255,153,51,0.1)
  static const Color marigoldAccent = Color(0x1AFFB81C); // rgba(255,184,28,0.1)
  static const Color indigoAccent = Color(0x1A312E81); // rgba(49,46,129,0.1)

  // Input Focus Colors
  static const Color tealFocus = Color(0x140D9488); // rgba(13,148,136,0.08)
  static const Color saffronFocus = Color(0x1FFF9933); // rgba(255,153,51,0.12)

  // White (for various uses)
  static const Color white = Color(0xFFFFFFFF);

  // Border Colors
  static const Color borderDefault = surfaceVariant; // #dee4e1
  static const Color borderHover = airaTeal;

  // Legacy Colors (kept for backward compatibility with other screens)
  static const Color background = Color(0xFF0F172A); // slate-900
  static const Color surface = Color(0xFF1E293B); // slate-800

  // ═══ Gradients ═══

  static const LinearGradient identityPanelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x0F0D9488), // rgba(13,148,136,0.06)
      Color(0x0A312E81), // rgba(49,46,129,0.04)
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D9488), // --aira-teal
      Color(0xFF312E81), // --atrium-indigo
    ],
  );

  static const LinearGradient heroTextGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0D9488), // teal
      Color(0xFF312E81), // indigo
      Color(0xFFE67E22), // deep saffron
    ],
  );
}
