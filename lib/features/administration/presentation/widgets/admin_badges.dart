import 'package:flutter/material.dart';

/// Complaint Type / Source badge colors — exact hex values ported from
/// the web `.complaint-type-badge` / `.source-badge` CSS.
class AdminBadgeColors {
  static const Map<String, List<Color>> complaintType = {
    'Academic Performance': [Color(0xFFE8F5E9), Color(0xFF2E7D32), Color(0xFFA5D6A7)],
    'Discipline Issue': [Color(0xFFFFF3E0), Color(0xFFE65100), Color(0xFFFFCC80)],
    'Fee Related': [Color(0xFFE3F2FD), Color(0xFF1565C0), Color(0xFF90CAF9)],
    'Food/Canteen': [Color(0xFFFFF8E1), Color(0xFFF9A825), Color(0xFFFFE082)],
    'Infrastructure': [Color(0xFFF3E5F5), Color(0xFF7B1FA2), Color(0xFFCE93D8)],
    'Safety Concern': [Color(0xFFFFEBEE), Color(0xFFC62828), Color(0xFFEF9A9A)],
    'Staff Behaviour': [Color(0xFFE0F7FA), Color(0xFF00838F), Color(0xFF80DEEA)],
    'Transport': [Color(0xFFECEFF1), Color(0xFF37474F), Color(0xFFB0BEC5)],
  };
  static const List<Color> complaintTypeDefault = [Color(0xFFEEF2FF), Color(0xFF1F2937), Color(0xFFC7D2FE)];

  static const Map<String, List<Color>> source = {
    'Walk-in': [Color(0xFFE8EAF6), Color(0xFF283593)],
    'Phone Call': [Color(0xFFFCE4EC), Color(0xFFAD1457)],
    'Online': [Color(0xFFE0F2F1), Color(0xFF00695C)],
    'In Person': [Color(0xFFFFF3E0), Color(0xFFE65100)],
    'Written': [Color(0xFFF3E5F5), Color(0xFF6A1B9A)],
    'Newspaper Ad': [Color(0xFFFFFDE7), Color(0xFFF57F17)],
    'Referral': [Color(0xFFE1F5FE), Color(0xFF0277BD)],
    'School Event': [Color(0xFFE8F5E9), Color(0xFF2E7D32)],
    'Social Media': [Color(0xFFFBE9E7), Color(0xFFBF360C)],
    'Website': [Color(0xFFECEFF1), Color(0xFF37474F)],
  };
  static const List<Color> sourceDefault = [Color(0xFFEDF2F7), Color(0xFF334155)];
}

/// Pill badge matching the web's complaint-type / source badge styling.
class AdminBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final Color? borderColor;

  const AdminBadge({super.key, required this.label, required this.background, required this.textColor, this.borderColor});

  factory AdminBadge.complaintType(String? label) {
    final colors = AdminBadgeColors.complaintType[label] ?? AdminBadgeColors.complaintTypeDefault;
    return AdminBadge(label: label?.isNotEmpty == true ? label! : 'N/A', background: colors[0], textColor: colors[1], borderColor: colors.length > 2 ? colors[2] : null);
  }

  factory AdminBadge.source(String? label) {
    final colors = AdminBadgeColors.source[label] ?? AdminBadgeColors.sourceDefault;
    return AdminBadge(label: label?.isNotEmpty == true ? label! : 'N/A', background: colors[0], textColor: colors[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}
