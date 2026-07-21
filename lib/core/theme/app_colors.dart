import 'package:flutter/material.dart';

/// eSkoolia Web Frontend Color Palette
/// Exact colors from web CSS variables
/// 
/// Usage: AppColors.primaryPurple, AppColors.textPrimary, etc.
class AppColors {
  // Primary Purple
  static const Color primaryPurple = Color(0xFF6D28D9);      // --pu
  static const Color purpleDeep = Color(0xFF5B21B6);         // --pu-deep
  static const Color purpleSoft = Color(0xFFEDE9FE);         // --pu-soft
  static const Color purpleTint = Color(0xFFF6F3FF);         // --pu-tint
  static const Color purpleAccent = Color(0xFF6D4AFF);       // Dashboard accent

  // Success Green
  static const Color successGreen = Color(0xFF059669);       // --ok
  static const Color greenSoft = Color(0xFFD1FAE5);          // --ok-soft
  static const Color greenDark = Color(0xFF0A6638);          // Deep green
  static const Color greenBorder = Color(0xFFBBF7D0);        // Green border

  // Warning Amber
  static const Color warningAmber = Color(0xFFD97706);       // --warn
  static const Color amberSoft = Color(0xFFFEF3C7);          // --warn-soft
  static const Color amberDark = Color(0xFF92400E);          // Deep amber
  static const Color amberBorder = Color(0xFFFDE68A);        // Amber border

  // Danger Red
  static const Color dangerRed = Color(0xFFDC2626);          // --danger
  static const Color redSoft = Color(0xFFFEE2E2);            // --danger-soft
  static const Color redBorder = Color(0xFFFCA5A5);          // Red border

  // Info Blue
  static const Color infoBlue = Color(0xFF0369A1);           // --info
  static const Color blueSoft = Color(0xFFDCEFFE);           // --info-soft
  static const Color blueBorder = Color(0xFFBAE6FD);         // Blue border
  static const Color skyBlue = Color(0xFF0EA5E9);            // Sky blue

  // Ink (Text)
  static const Color textPrimary = Color(0xFF111827);        // --ink-1
  static const Color textSecondary = Color(0xFF6B7280);      // --ink-2
  static const Color textTertiary = Color(0xFF9CA3AF);       // --ink-3
  static const Color textQuaternary = Color(0xFFD1D5DB);     // --ink-4

  // Background
  static const Color bgPrimary = Color(0xFFFFFFFF);          // --bg-1
  static const Color bgSecondary = Color(0xFFF9FAFB);        // --bg-2
  static const Color bgTertiary = Color(0xFFF3F4F6);         // --bg-3

  // Borders
  static const Color borderPrimary = Color(0xFFE5E7EB);      // --bd
  static const Color borderSecondary = Color(0xFFD1D5DB);    // --bd-2

  // Board-specific colors (from web)
  static const Color boardCBSE = Color(0xFF5836E0);
  static const Color boardICSE = Color(0xFF0369A1);
  static const Color boardSSC_AP = Color(0xFFA65D08);
  static const Color boardSSC_TG = Color(0xFFB42318);
  static const Color boardOther = Color(0xFF6B7280);

  // State colors (from web)
  static const Color stateTelangana = Color(0xFF5836E0);
  static const Color stateAndhraPradesh = Color(0xFFA65D08);
  static const Color stateKarnataka = Color(0xFF0369A1);
  static const Color stateTamilNadu = Color(0xFF059669);
  static const Color stateMaharashtra = Color(0xFF6D28D9);
  static const Color stateDelhi = Color(0xFFDC2626);

  // Plan colors (from web)
  static const Color planEnterprise = Color(0xFF5836E0);
  static const Color planPremium = Color(0xFF4F46E5);
  static const Color planStandard = Color(0xFF6D28D9);
  static const Color planStarter = Color(0xFF8B5CF6);
  static const Color planTrial = Color(0xFF9CA3AF);

  // Gradient colors for avatars (8 gradients from web)
  static const List<List<Color>> avatarGradients = [
    [Color(0xFF7C5BFF), Color(0xFF5836E0)], // Purple
    [Color(0xFFA65D08), Color(0xFF7d4006)], // Orange
    [Color(0xFF1A4ACF), Color(0xFF0f3196)], // Dark blue
    [Color(0xFF0E9F6E), Color(0xFF0d7a55)], // Green
    [Color(0xFF992558), Color(0xFF6c1a3d)], // Magenta
    [Color(0xFF0369A1), Color(0xFF055478)], // Cyan
    [Color(0xFF06794F), Color(0xFF045236)], // Teal
    [Color(0xFFE0463A), Color(0xFFa8281f)], // Red
  ];

  // Utility methods
  static Color getBoardColor(String? board) {
    switch (board) {
      case 'CBSE':
        return boardCBSE;
      case 'ICSE':
        return boardICSE;
      case 'SSC_AP':
      case 'SSC AP':
        return boardSSC_AP;
      case 'SSC_TG':
      case 'SSC TG':
        return boardSSC_TG;
      default:
        return boardOther;
    }
  }

  static Color getPlanColor(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'enterprise':
        return planEnterprise;
      case 'premium':
        return planPremium;
      case 'standard':
        return planStandard;
      case 'starter':
        return planStarter;
      case 'trial':
        return planTrial;
      default:
        return boardOther; // web PLAN_COLOR fallback: #6B7280
    }
  }

  static List<Color> getAvatarGradient(String tenantId) {
    final code = tenantId.isNotEmpty 
        ? tenantId.codeUnitAt(tenantId.length - 1) % avatarGradients.length
        : 0;
    return avatarGradients[code];
  }
}
