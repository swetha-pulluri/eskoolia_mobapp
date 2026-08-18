import 'package:flutter/material.dart';

/// Application Color Palette
/// EXACT 1:1 match with frontend/app/globals.css auth design tokens
/// Source: .gateway-shell, .auth-flow-shell CSS variables
class AppColors {
  AppColors._();

  // NOTE: inkPrimary/inkSecondary/inkTertiary below are the auth & login-permission
  // "ink" tokens. The dashboard/administration/school-tenancy/admissions/attendance
  // modules use their own textPrimary/textSecondary/textTertiary web tokens further down.

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
  static const Color inkPrimary = onBackground; // #171d1c
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

  // ═══ Account Recovery Design Tokens (frontend/app/globals.css — the
  // .flow-form-card/.editorial-form/.primary-flow-button rules shared by the
  // Forgot Password and Reset Password pages). This flow is keyed to
  // --surface-tint, a distinct, darker teal from --aira-teal used elsewhere
  // in the auth flow — not a typo, matches web exactly. ═══
  static const Color surfaceTint = Color(0xFF006A61); // --surface-tint / --tertiary

  static const LinearGradient recoveryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [surfaceTint, atriumIndigo], // linear-gradient(90deg, --surface-tint, --atrium-indigo)
  );

  static const LinearGradient recoveryHeadingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceTint, atriumIndigo], // linear-gradient(135deg, --surface-tint, --atrium-indigo)
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
  static const Color inkSecondary = Color(0xFF475569); // --ink-2
  static const Color inkTertiary = Color(0xFF64748B); // --ink-3
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

  // ═══ Student List Colors (from frontend/components/students/StudentListPanel.tsx) ═══

  static const Color studentListBrand = Color(0xFF4F39F6); // --brand
  static const Color studentListBrandHover = Color(0xFF4A3FB8); // btn-primary hover
  static const Color studentListCta = Color(0xFF5B4FCF); // .btn-primary / .enroll-btn
  static const Color studentListInk = Color(0xFF0B0B14); // --ink
  static const Color studentListMuted = Color(0xFF66677B); // --muted
  static const Color studentListLine = Color(0xFFDFDFEA); // --line
  static const Color studentListSoft = Color(0xFFF4F5FA); // --soft
  static const Color studentListPageBg = Color(0xFFF8F8FC); // .page

  static const Color studentStatAttentionBorder = Color(0xFFF2D6A6);
  static const Color studentStatAttentionBg = Color(0xFFFFFDF8);

  static const Color studentFlashSuccessBg = Color(0xFFEFF6FF);
  static const Color studentFlashSuccessText = Color(0xFF1D4ED8);
  static const Color studentFlashSuccessBorder = Color(0xFFBFDBFE);
  static const Color studentFlashErrorBg = Color(0xFFFEF2F2);
  static const Color studentFlashErrorText = Color(0xFFB91C1C);
  static const Color studentFlashErrorBorder = Color(0xFFFECACA);

  // Panel header ("01"/"02" numbered circle + active-filter tag pills)
  static const Color studentPanelNumBg = Color(0xFFEEEDFE);
  static const Color studentPanelNumText = Color(0xFF3C3489);
  static const Color studentPanelTitle = Color(0xFF1A1D33);
  static const Color studentPanelDesc = Color(0xFF8B8EA8);

  static const Color studentTagPurpleBg = Color(0xFFF0EEFF);
  static const Color studentTagPurpleBorder = Color(0xFFC8C1F8);
  static const Color studentTagPurpleText = Color(0xFF3D33B2);
  static const Color studentTagBlueBg = Color(0xFFEFF6FF);
  static const Color studentTagBlueBorder = Color(0xFFBFDBFE);
  static const Color studentTagBlueText = Color(0xFF1D4ED8);
  static const Color studentTagAmberBg = Color(0xFFFFFBEB);
  static const Color studentTagAmberBorder = Color(0xFFFDE68A);
  static const Color studentTagAmberText = Color(0xFF92400E);
  static const Color studentTagGrayBg = Color(0xFFF3F4F6);
  static const Color studentTagGrayBorder = Color(0xFFD1D5DB);
  static const Color studentTagGrayText = Color(0xFF374151);

  // Filters
  static const Color studentSearchBorder = Color(0xFFDFE0EB);
  static const Color studentSearchText = Color(0xFF1A1D33);
  static const Color studentSelectText = Color(0xFF42455D);
  static const Color studentPillBg = Color(0xFFF7F7FB);
  static const Color studentPillBorder = Color(0xFFE8E8F0);
  static const Color studentPillText = Color(0xFF4B4D64);
  static const Color studentPillCountBg = Color(0xFFECECF6);
  static const Color studentPillOnAmberBg = Color(0xFFFAEEDA);
  static const Color studentPillOnAmberBorder = Color(0xFFEF9F27);
  static const Color studentPillOnAmberText = Color(0xFF633806);
  static const Color studentFilterDividerColor = Color(0xFFECECF4);
  static const Color studentFilterFootBg = Color(0xFFFAFBFF);

  // Class accordion card (Browse & edit by class) — .sl-cls-*, .sl-badge.*
  static const Color studentClsBorder = Color(0xFFE6E8EE);
  static const Color studentClsHeaderBg = Color(0xFFFBFCFE);
  static const Color studentClsHeaderOpenBgTop = Color(0xFFF1FAF5);
  static const Color studentClsHeaderOpenBgBottom = Color(0xFFFBFEFC);
  static const Color studentClsOpenBorder = Color(0xFFD6E8DD);
  static const Color studentClsOpenAccent = Color(0xFF16A37B);
  static const Color studentClsChevron = Color(0xFFB0B3CC);
  static const Color studentClsProgressText = Color(0xFF747896);
  static const Color studentBadgeGreenBg = Color(0xFFF0FDF4);
  static const Color studentBadgeGreenBorder = Color(0xFFBBF7D0);
  static const Color studentBadgeGreenText = Color(0xFF166534);
  static const Color studentBadgeRedBg = Color(0xFFFEF2F2);
  static const Color studentBadgeRedBorder = Color(0xFFFECACA);
  static const Color studentBadgeRedText = Color(0xFF991B1B);

  // Table
  static const Color studentTableHeadBg = Color(0xFFFBFBFF);
  static const Color studentTableHeadText = Color(0xFF6D7086);
  static const Color studentTableBorder = Color(0xFFEBEBF3);
  static const Color studentTableRowHover = Color(0xFFFAF9FF);
  static const Color studentAvatarBg = Color(0xFFECE8FF);
  static const Color studentAvatarText = Color(0xFF4738CA);
  static const Color studentPrimaryText = Color(0xFF121529);
  static const Color studentSecondaryText = Color(0xFF7A7D94);

  static const Color studentStatusActiveBg = Color(0xFFECFDF3);
  static const Color studentStatusActiveText = Color(0xFF047857);
  static const Color studentStatusInactiveBg = Color(0xFFF3F4F6);
  static const Color studentStatusInactiveText = Color(0xFF4B5563);
  static const Color studentStatusPendingBg = Color(0xFFFFF7E8);
  static const Color studentStatusPendingText = Color(0xFFA16207);
  static const Color studentStatusArchivedBg = Color(0xFFFEE2E2);
  static const Color studentStatusArchivedText = Color(0xFFB91C1C);

  static const Color studentIconActionBorder = Color(0xFFE5E7F0);
  static const Color studentIconActionText = Color(0xFF5B5F7A);
  static const Color studentIconActionHoverBorder = Color(0xFFC8CBF2);
  static const Color studentIconActionHoverBg = Color(0xFFF4F3FF);
  static const Color studentIconArchiveHoverBorder = Color(0xFFFCA5A5);
  static const Color studentIconArchiveHoverBg = Color(0xFFFFF1F1);
  static const Color studentIconArchiveHoverText = Color(0xFFDC2626);
  static const Color studentIconViewHoverBorder = Color(0xFFA5D8E8);
  static const Color studentIconViewHoverBg = Color(0xFFF0F9FF);
  static const Color studentIconViewHoverText = Color(0xFF0891B2);
  static const Color studentIconMessageHoverBorder = Color(0xFF6EE7B7);
  static const Color studentIconMessageHoverBg = Color(0xFFF0FDF4);
  static const Color studentIconMessageHoverText = Color(0xFF059669);

  static const Color studentPagerBorder = Color(0xFFE6E6EC);
  static const Color studentPagerText = Color(0xFF3A3A4A);
  static const Color studentPagerFootText = Color(0xFF9A9DB4);

  // ═══ Student Enroll Colors (from frontend/components/students/StudentAddPanel.tsx) ═══

  static const Color studentEnrollBrand = Color(0xFF6C3CE1); // --brand
  static const Color studentEnrollInk = Color(0xFF111827); // --ink
  static const Color studentEnrollMuted = Color(0xFF6B7280); // --muted
  static const Color studentEnrollLine = Color(0xFFE5E7EB); // --line
  static const Color studentEnrollBg = Color(0xFFFAFAFB); // --bg

  static const Color studentScanBannerBg = Color(0xFF1A1A2E);
  static const Color studentScanIconBg = Color(0xCC6C3CE1); // rgba(108,60,225,.8)
  static const Color studentBadgeNewBg = Color(0xFF10B981);

  static const Color studentNavBulletBg = Color(0xFFF3F4F6);
  static const Color studentNavBulletText = Color(0xFF9CA3AF);
  static const Color studentNavLabel = Color(0xFF1F2937);
  static const Color studentNavCopy = Color(0xFF6B7280);
  static const Color studentNavActiveBg = Color(0xFFF5F3FF);
  static const Color studentNavLockedBg = Color(0xFFF9FAFB);
  static const Color studentHeadsUpBg = Color(0xFFEDE9FE);

  static const Color studentFieldBorder = Color(0xFFD1D5DB);
  static const Color studentFieldErrorBorder = Color(0xFFDC2626);
  static const Color studentFieldErrorBg = Color(0xFFFEF2F2);
  static const Color studentFieldLabel = Color(0xFF374151);
  static const Color studentHelpText = Color(0xFF6B7280);
  static const Color studentRequiredMark = Color(0xFFDC2626);

  static const Color studentRecommendedBg = Color(0xFFECFDF5);
  static const Color studentRecommendedText = Color(0xFF065F46);
  static const Color studentOptionalBg = Color(0xFFF3F4F6);
  static const Color studentOptionalText = Color(0xFF6B7280);

  static const Color studentNavPrevBorder = Color(0xFFD1D5DB);
  static const Color studentNavPrevText = Color(0xFF374151);

  // ═══ eSkoolia Web Frontend Color Palette ═══
  // Exact colors from web CSS variables, used by dashboard/administration/
  // school_tenancy/admissions/attendance modules.
  // Usage: AppColors.primaryPurple, AppColors.textPrimary, etc.

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
