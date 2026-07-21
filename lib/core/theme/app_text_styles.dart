import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// eSkoolia Web Frontend Typography
/// Exact text styles from web CSS
/// 
/// Uses Instrument Serif for large numbers (matching web)
/// Inter for body text (default Material font)
class AppTextStyles {
  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE TITLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main page title: "Super Admin", "School"
  /// Font: 34px, 600 weight, -1px letter spacing
  static TextStyle get pageTitle => const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
        height: 1.05,
      );

  /// Italic accent title: "Dashboard", "Management"
  /// Font: Instrument Serif, 38px, 400 weight, italic, -0.5px letter spacing
  static TextStyle get pageTitleAccent => GoogleFonts.instrumentSerif(
        fontSize: 38,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        letterSpacing: -0.5,
        color: AppColors.purpleAccent,
        height: 1.05,
      );

  /// Page subtitle/description
  /// Font: 13px, normal, 1.6 line height
  static TextStyle get pageSubtitle => const TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // KPI CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// KPI card large number: "48", "12.5K", "₹5.89L"
  /// Font: Instrument Serif, 50px, 400 weight, -1.5px letter spacing
  static TextStyle get kpiValue => GoogleFonts.instrumentSerif(
        fontSize: 50,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.5,
        color: AppColors.textPrimary,
        height: 0.95,
      );

  /// KPI card label: "TOTAL SCHOOLS", "STUDENTS SERVED"
  /// Font: 10.5px, 600 weight, 0.1em tracking, uppercase
  static TextStyle get kpiLabel => const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.05, // 0.1em = fontSize * 0.1
        color: AppColors.textTertiary,
        height: 1.0,
      );

  /// KPI card trend: "+8.3%", "●  42 active"
  /// Font: 11.5px, 600 weight
  static TextStyle kpiTrend({Color? color}) => TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.successGreen,
      );

  /// KPI card footnote: "Pan-India", "GST collected this month"
  /// Font: 11px
  static TextStyle get kpiFootnote => const TextStyle(
        fontSize: 11,
        color: AppColors.textTertiary,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION TITLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Section title: "Schools by board", "Geographic distribution"
  /// Font: 15px, 600 weight, -0.1px letter spacing
  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.textPrimary,
      );

  /// Section subtitle
  /// Font: 12px
  static TextStyle get sectionSubtitle => const TextStyle(
        fontSize: 12,
        color: AppColors.textTertiary,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // BOARD / STATE / PLAN LABELS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Board/State name: "CBSE", "Telangana"
  /// Font: 13px, 550 weight
  static TextStyle get boardLabel => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500, // Closest to 550
        color: AppColors.textPrimary,
      );

  /// Board/State count: "24", "18 schools"
  /// Font: Instrument Serif, 16px
  static TextStyle get boardCount => GoogleFonts.instrumentSerif(
        fontSize: 16,
        color: AppColors.textPrimary,
      );

  /// Board/State percentage: "· 50%"
  /// Font: 11.5px
  static TextStyle get boardPercentage => const TextStyle(
        fontSize: 11.5,
        color: AppColors.textTertiary,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // CHIPS & BADGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Chip label: Board chips, plan chips, status chips
  /// Font: 11.5px, 550 weight
  static TextStyle chipLabel({Color? color}) => TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  /// Small chip label: Mono badges, counts
  /// Font: Mono, 10.5px, 600 weight
  static TextStyle get chipLabelMono => const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
      );

  /// Numbered badge: [01], [02], [03]
  /// Font: Mono, 11px, 500 weight, 0.04em tracking
  static TextStyle get numberedBadge => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
        letterSpacing: 0.44, // 11 * 0.04
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCORDION / SCHOOL CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Accordion title: School name
  /// Font: 14.5px, 600 weight, -0.2px letter spacing
  static TextStyle get accordionTitle => const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  /// Accordion subtitle: Tenant ID
  /// Font: 12px
  static TextStyle get accordionSubtitle => const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVITY / EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Activity action label
  /// Font: 12.5px, 600 weight
  static TextStyle get activityAction => const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// Activity detail
  /// Font: 11.5px
  static TextStyle get activityDetail => const TextStyle(
        fontSize: 11.5,
        color: Color(0xFF9197AE),
        height: 1.4,
      );

  /// Relative time: "4m ago", "18m ago"
  /// Font: 11px
  static TextStyle get relativeTime => const TextStyle(
        fontSize: 11,
        color: AppColors.textTertiary,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary button text
  /// Font: 13px, 600 weight
  static TextStyle get buttonPrimary => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  /// Secondary button text
  /// Font: 13px, 500 weight
  static TextStyle get buttonSecondary => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Small button text (filter pills)
  /// Font: 12px, 550 weight
  static TextStyle get buttonSmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // POLICIES / SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Policy key: "password.min_length"
  /// Font: Mono, 12px, 600 weight
  static TextStyle get policyKey => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
        color: AppColors.textPrimary,
      );

  /// Policy description
  /// Font: 12px, 1.4 line height
  static TextStyle get policyDescription => const TextStyle(
        fontSize: 12,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply uppercase transformation
  static TextStyle uppercase(TextStyle style) {
    return style;
  }
}
