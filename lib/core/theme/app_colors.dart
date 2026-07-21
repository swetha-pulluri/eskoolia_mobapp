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

  // ═══ Dashboard KPI Card Colors (from frontend/app/(dashboard)/dashboard/page.tsx) ═══

  // Total Students
  static const Color kpiStudentsIcon = Color(0xFFB42318);
  static const Color kpiStudentsBg = Color(0xFFFEF3F2);

  // Today's Attendance
  static const Color kpiAttendanceIcon = Color(0xFFB45309);
  static const Color kpiAttendanceBg = Color(0xFFFFFBEB);

  // Fees Collected MTD
  static const Color kpiFeesIcon = Color(0xFF0E7490);
  static const Color kpiFeesBg = Color(0xFFECFEFF);

  // Open Admissions
  static const Color kpiAdmissionsIcon = Color(0xFF047857);
  static const Color kpiAdmissionsBg = Color(0xFFECFDF5);

  // Total Staff
  static const Color kpiStaffIcon = Color(0xFF7C3AED);
  static const Color kpiStaffBg = Color(0xFFF5F3FF);

  // Library Books
  static const Color kpiLibraryIcon = Color(0xFFBE185D);
  static const Color kpiLibraryBg = Color(0xFFFDF2F8);

  // Pending Homework
  static const Color kpiHomeworkIcon = Color(0xFFC2410C);
  static const Color kpiHomeworkBg = Color(0xFFFFF7ED);

  // Exams This Week
  static const Color kpiExamsIcon = Color(0xFFA21CAF);
  static const Color kpiExamsBg = Color(0xFFFDF4FF);

  // Quick Action Button Colors
  static const Color quickActionAttendance = Color(0xFFB45309);
  static const Color quickActionAttendanceBg = Color(0xFFFFFBEB);
  static const Color quickActionFees = Color(0xFF0E7490);
  static const Color quickActionFeesBg = Color(0xFFECFEFF);
  static const Color quickActionStudent = Color(0xFFB42318);
  static const Color quickActionStudentBg = Color(0xFFFEF3F2);
  static const Color quickActionExam = Color(0xFFA21CAF);
  static const Color quickActionExamBg = Color(0xFFFDF4FF);
  static const Color quickActionPayroll = Color(0xFFDC2626);
  static const Color quickActionPayrollBg = Color(0xFFFEF2F2);
  static const Color quickActionLibrary = Color(0xFFBE185D);
  static const Color quickActionLibraryBg = Color(0xFFFDF2F8);

  // Dashboard Colors
  static const Color dashboardPurple = Color(0xFF6D4AFF);
  static const Color dashboardPurpleLight = Color(0xFF8B5CF6);

  // Text Colors for KPIs
  static const Color deltaPositive = Color(0xFF15803D); // green-700
  static const Color deltaNegative = Color(0xFFDC2626); // red-600

  // Border and Surface for Cards
  static const Color cardBorder = Color(0xFFECECF2);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFFAFAFC);

  // ═══ Login Permission / Credential Manager tokens ═══
  // 1:1 with frontend login-permission CSS vars (ink-2, ink-3, bg-0)
  static const Color textSecondary = Color(0xFF475569); // --ink-2
  static const Color textTertiary = Color(0xFF64748B); // --ink-3
  static const Color dashboardBackground = Color(0xFFF8FAFC); // --bg-0

  // ═══ Roles & Permissions Colors (from frontend/components/access-control/RoleManagementPanel.tsx) ═══

  // Portal Badge Colors
  static const Color portalAdminBg = Color(0xFFEEF2FF); // blue-50
  static const Color portalAdminText = Color(0xFF4338CA); // indigo-700
  static const Color portalTeacherBg = Color(0xFFEEEAFF); // purple-50
  static const Color portalTeacherText = Color(0xFF6D4AFF); // purple
  static const Color portalParentBg = Color(0xFFFFF1F2); // rose-50
  static const Color portalParentText = Color(0xFFBE123C); // rose-700
  static const Color portalStudentBg = Color(0xFFE0F2FE); // sky-100
  static const Color portalStudentText = Color(0xFF0369A1); // sky-700
  static const Color portalCustomBg = Color(0xFFF1F5F9); // slate-100
  static const Color portalCustomText = Color(0xFF475569); // slate-600

  // Role Card Deterministic Background Colors (10 colors rotating)
  static const List<Color> roleCardBackgrounds = [
    Color(0xFFF3E8FF), // purple-100
    Color(0xFFEFF6FF), // blue-50
    Color(0xFFDCFCE7), // green-100
    Color(0xFFFEF9C3), // yellow-100
    Color(0xFFEEEAFF), // purple-50
    Color(0xFFFEF3C7), // amber-100
    Color(0xFFE0F2FE), // sky-100
    Color(0xFFFCE7F3), // pink-100
    Color(0xFFFEF2F2), // red-50
    Color(0xFFD1FAE5), // green-100
  ];

  // Inactive Badge
  static const Color inactiveBadgeBg = Color(0xFFFEE2E2); // red-100
  static const Color inactiveBadgeText = Color(0xFFDC2626); // red-600

  // Role Card Border & Hover States
  static const Color roleCardBorder = cardBorder;
  static const Color roleCardSelected = Color(0xFFFAFAFF); // very light purple
  static const Color roleCardSelectedBorder = dashboardPurple; // purple
  static const Color roleCardHoverBorder = Color(0xFFC4B5FD); // purple-300

  // System/Custom Labels
  static const Color labelTextMuted = Color(0xFF9197AE); // ink-3
  static const Color labelTextSecondary = Color(0xFF5A607A); // ink-2

  // Role Card Hover Action Icons (RoleManagementPanel.tsx .role-hover-actions)
  static const Color roleActionAssignBg = Color(0xFFEEEAFF); // --pu-soft
  static const Color roleActionEditBg = Color(0xFFF0F0F0); // --bg-2
  static const Color roleActionActivateBg = Color(0xFFDCFCE7); // green-100
  static const Color roleActionActivateText = Color(0xFF166534); // green-800
  static const Color roleActionDeactivateBg = Color(0xFFFEF3C7); // amber-100
  static const Color roleActionDeactivateText = Color(0xFF92400E); // amber-800
  static const Color roleActionDeleteBg = Color(0xFFFEF2F2); // red-50

  // Add New Role Card
  static const Color dashedBorder = cardBorder;
  static const Color dashedBorderHover = dashboardPurple;
}
