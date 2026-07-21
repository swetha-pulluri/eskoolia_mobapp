import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Action badge for the audit log — colored pill matching the web
/// `ACTION_CLS` map (super-admin/audit/page.tsx). Shows the raw dotted
/// action key verbatim (e.g. "school.provision"), not uppercased.
class ActionBadge extends StatelessWidget {
  final String action;

  const ActionBadge({super.key, required this.action});

  ({Color bg, Color fg}) _colorsFor(String action) {
    const map = <String, ({Color bg, Color fg})>{
      'auth.login': (bg: Color(0xFFD1FAE5), fg: Color(0xFF0A6638)),
      'auth.logout': (bg: Color(0xFFF3F4F6), fg: AppColors.textSecondary),
      'auth.impersonate': (bg: Color(0xFFFEF3C7), fg: Color(0xFF92400E)),
      'school.provision': (bg: Color(0xFFF6F3FF), fg: AppColors.purpleDeep),
      'school.update': (bg: Color(0xFFF6F3FF), fg: AppColors.purpleDeep),
      'school.archive': (bg: Color(0xFFFEE2E2), fg: AppColors.dangerRed),
      'plan.upgrade': (bg: Color(0xFFD1FAE5), fg: Color(0xFF0A6638)),
      'plan.downgrade': (bg: Color(0xFFFEF3C7), fg: Color(0xFF92400E)),
      'invoice.generated': (bg: AppColors.blueSoft, fg: AppColors.infoBlue),
      'invoice.sent': (bg: AppColors.blueSoft, fg: AppColors.infoBlue),
      'invoice.overdue': (bg: Color(0xFFFEE2E2), fg: AppColors.dangerRed),
      'api_key.rotate': (bg: Color(0xFFFEF3C7), fg: Color(0xFF92400E)),
      'policy.updated': (bg: Color(0xFFFEF3C7), fg: Color(0xFF92400E)),
      'migration.start': (bg: AppColors.blueSoft, fg: AppColors.infoBlue),
      'migration.complete': (bg: Color(0xFFD1FAE5), fg: Color(0xFF0A6638)),
      'migration.rollback': (bg: Color(0xFFFEE2E2), fg: AppColors.dangerRed),
      'backup.complete': (bg: Color(0xFFD1FAE5), fg: Color(0xFF0A6638)),
    };
    return map[action] ??
        (bg: AppColors.bgTertiary, fg: AppColors.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final c = _colorsFor(action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        action,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.fg),
      ),
    );
  }
}

/// Severity chip for the audit log — matches web `SevChip`
/// (info / warning / error) with a dot + soft pill background.
class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  String _normalize(String s) {
    final v = s.toLowerCase();
    if (v == 'critical' || v == 'error' || v == 'failed') return 'error';
    if (v == 'warning' || v == 'partial') return 'warning';
    return 'info';
  }

  @override
  Widget build(BuildContext context) {
    final key = _normalize(severity);
    late Color bg, fg, dot;
    late String label;
    switch (key) {
      case 'error':
        bg = AppColors.redSoft;
        fg = AppColors.dangerRed;
        dot = AppColors.dangerRed;
        label = 'Error';
        break;
      case 'warning':
        bg = AppColors.amberSoft;
        fg = const Color(0xFF92400E);
        dot = AppColors.warningAmber;
        label = 'Warning';
        break;
      default:
        bg = AppColors.blueSoft;
        fg = AppColors.infoBlue;
        dot = AppColors.skyBlue;
        label = 'Info';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
        ],
      ),
    );
  }
}
