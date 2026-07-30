import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Action badge widget for audit log
/// Colored background with action label
/// 
/// Usage:
/// ```dart
/// ActionBadge(
///   action: 'CREATE',
///   color: AppColors.successGreen,
/// )
/// ```
class ActionBadge extends StatelessWidget {
  final String action;
  final Color? color;

  const ActionBadge({
    super.key,
    required this.action,
    this.color,
  });

  /// Get color based on action type
  Color _getColorForAction() {
    if (color != null) return color!;

    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'CREATED':
        return AppColors.successGreen;
      case 'UPDATE':
      case 'UPDATED':
      case 'EDIT':
      case 'EDITED':
        return AppColors.infoBlue;
      case 'DELETE':
      case 'DELETED':
      case 'REMOVE':
      case 'REMOVED':
        return AppColors.dangerRed;
      case 'LOGIN':
      case 'LOGOUT':
      case 'AUTH':
        return AppColors.primaryPurple;
      case 'VIEW':
      case 'READ':
        return AppColors.textTertiary;
      case 'EXPORT':
      case 'DOWNLOAD':
        return AppColors.skyBlue;
      case 'UPLOAD':
      case 'IMPORT':
        return AppColors.warningAmber;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _getColorForAction();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: actionColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action.toUpperCase(),
        style: AppTextStyles.chipLabel(color: actionColor).copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Severity badge for audit log
class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({
    super.key,
    required this.severity,
  });

  Color _getColorForSeverity() {
    switch (severity.toLowerCase()) {
      // Real audit events carry 'error'/'warning'/'info' (the Super Admin
      // API's own `get_severity()` vocabulary) — 'critical'/'high'/'medium'/
      // 'low' below never actually occur on a real event, so without these
      // cases every severity dot silently rendered gray regardless of
      // actual severity.
      case 'critical':
      case 'error':
        return AppColors.dangerRed;
      case 'high':
      case 'warning':
        return AppColors.warningAmber;
      case 'medium':
        return AppColors.infoBlue;
      case 'low':
        return AppColors.successGreen;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getColorForSeverity();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: severityColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          severity,
          style: AppTextStyles.chipLabel(color: severityColor),
        ),
      ],
    );
  }
}
