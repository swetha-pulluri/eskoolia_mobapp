import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared visual pieces for Student Promote — ports of frontend
/// app/(dashboard)/students/promote/components/{PromoteCircularProgress,
/// PromoteKPICards}.tsx plus small pure helpers (`formatClassLabel`,
/// `classRank`, the student-name avatar hash, `initials`) duplicated
/// identically across PromotePageContainer.tsx and PromoteStudentTable.tsx
/// in the reference — consolidated here once instead of copy-pasted twice
/// like the source does.

String promoteFormatClassLabel(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return 'Unassigned';
  if (RegExp(r'^\d+$').hasMatch(s)) return 'Grade $s';
  return s;
}

int promoteClassRank(String label) {
  final l = label.toLowerCase().trim();
  if (l == 'nursery' || l == 'pre-nursery' || l == 'pre nursery') return -3;
  if (l == 'lkg') return -2;
  if (l == 'ukg') return -1;
  final m = RegExp(r'^grade\s+(\d+)$', caseSensitive: false).firstMatch(l) ?? RegExp(r'^(\d+)$').firstMatch(l);
  if (m != null) return int.parse(m.group(1)!);
  return 9999;
}

/// Mirrors PromoteStudentTable.tsx's `AVATAR_PALETTE` + hash function
/// exactly (per-char `hash = (hash*31 + code) >>> 0`), so the same student
/// name is tinted the same color as the reference would render.
const List<Color> kPromoteAvatarPalette = [
  Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFFD97706),
  Color(0xFFDC2626), Color(0xFF0891B2), Color(0xFF0E7490), Color(0xFF2563EB), Color(0xFF1D4ED8),
  Color(0xFF16A34A), Color(0xFF15803D), Color(0xFFDB2777), Color(0xFFBE185D), Color(0xFF4F46E5),
];

Color promoteAvatarColor(String name) {
  var hash = 0;
  for (final code in name.codeUnits) {
    hash = (hash * 31 + code) & 0xFFFFFFFF;
  }
  return kPromoteAvatarPalette[hash % kPromoteAvatarPalette.length];
}

String promoteInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, parts.first.length < 2 ? parts.first.length : 2).toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Static, no-API mandatory-subject list per class level — ports
/// NotPromotedDialog.tsx's `MANDATORY_SUBJECTS` + `getSubjectsForClass`
/// verbatim (Fix 4 in the reference: purely local, used only to populate the
/// "Subjects of Concern" picker, never sent to any subject-catalog API).
const Map<String, List<String>> kPromotionMandatorySubjects = {
  'nursery': ['English (Oral)', 'Hindi (Oral)', 'Mathematics (Basic)', 'Environmental Awareness', 'Art & Craft', 'Music & Rhymes', 'Physical Development'],
  'lkg': ['English', 'Hindi', 'Mathematics', 'Environmental Studies', 'Art & Craft', 'Music & Rhymes', 'Physical Education'],
  'ukg': ['English', 'Hindi', 'Mathematics', 'Environmental Studies', 'General Knowledge', 'Art & Craft', 'Physical Education'],
  'grade 1': ['English', 'Hindi', 'Mathematics', 'EVS', 'General Knowledge', 'Art & Craft', 'Physical Education', 'Computer Basics'],
  'grade 2': ['English', 'Hindi', 'Mathematics', 'EVS', 'General Knowledge', 'Art & Craft', 'Physical Education', 'Computer Basics'],
  'grade 3': ['English', 'Hindi', 'Mathematics', 'Science', 'Social Studies', 'Computer Science', 'Physical Education', 'General Knowledge'],
  'grade 4': ['English', 'Hindi', 'Mathematics', 'Science', 'Social Studies', 'Computer Science', 'Physical Education', 'General Knowledge'],
  'grade 5': ['English', 'Hindi', 'Mathematics', 'Science', 'Social Studies', 'Computer Science', 'Physical Education', 'General Knowledge'],
  'grade 6': ['English', 'Hindi / Sanskrit', 'Mathematics', 'Science', 'Social Studies', 'Computer Science', 'Physical Education', 'Art & Craft'],
  'grade 7': ['English', 'Hindi / Sanskrit', 'Mathematics', 'Science', 'Social Studies', 'Computer Science', 'Physical Education', 'Art & Craft'],
  'grade 8': ['English', 'Hindi / Sanskrit', 'Mathematics', 'Science', 'Social Studies', 'Computer Science', 'Physical Education', 'Art & Craft'],
  'grade 9': ['English', 'Hindi', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Social Studies / History', 'Computer Science'],
  'grade 10': ['English', 'Hindi', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Social Studies / History', 'Computer Science'],
};

List<String> promotionSubjectsForClass(String classDisplay) {
  final normalized = classDisplay.toLowerCase().trim();
  if (kPromotionMandatorySubjects.containsKey(normalized)) return kPromotionMandatorySubjects[normalized]!;
  if (RegExp(r'^\d+$').hasMatch(normalized)) {
    return kPromotionMandatorySubjects['grade $normalized'] ?? kPromotionMandatorySubjects['grade 9']!;
  }
  final numMatch = RegExp(r'(\d+)').firstMatch(normalized);
  if (numMatch != null) {
    final key = 'grade ${numMatch.group(1)}';
    if (kPromotionMandatorySubjects.containsKey(key)) return kPromotionMandatorySubjects[key]!;
  }
  for (final key in kPromotionMandatorySubjects.keys) {
    if (normalized.contains(key) || key.contains(normalized)) return kPromotionMandatorySubjects[key]!;
  }
  return kPromotionMandatorySubjects['grade 9']!;
}

/// Port of PromoteCircularProgress.tsx — an SVG ring showing promoted/total.
class PromoteCircularProgress extends StatelessWidget {
  final int promoted;
  final int total;
  final double size;
  const PromoteCircularProgress({super.key, required this.promoted, required this.total, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? ((promoted / total) * 100).round() : 0;
    final color = pct >= 80 ? const Color(0xFF16A34A) : (pct >= 50 ? const Color(0xFFD97706) : const Color(0xFFDC2626));
    return Tooltip(
      message: '$promoted/$total promoted',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size(size, size), painter: _PromoteRingPainter(pct: pct, color: color)),
            Text('$pct%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PromoteRingPainter extends CustomPainter {
  final int pct;
  final Color color;
  const _PromoteRingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 3;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFE5E7EB)..style = PaintingStyle.stroke..strokeWidth = 3);
    final sweep = 2 * math.pi * (pct / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PromoteRingPainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}

/// Port of PromoteKPICards.tsx's `KPICard`.
class PromoteKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;
  const PromoteKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1, color: Color(0xFF111827))),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Text(sub!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }
}

/// Tri-tone (success/error/info) bottom-right toast — mirrors
/// PromotePageContainer.tsx's inline `toast` block exactly (colors/border
/// per tone). Positioned must stay a direct Stack child; IgnorePointer
/// wraps its content, not the other way around.
class PromoteToast extends StatelessWidget {
  final ({String tone, String message})? toast;
  const PromoteToast({super.key, required this.toast});

  @override
  Widget build(BuildContext context) {
    final visible = toast != null;
    final tone = toast?.tone ?? 'info';
    final Color bg, fg, border;
    switch (tone) {
      case 'success':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF065F46);
        border = const Color(0xFFA7F3D0);
        break;
      case 'error':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFF991B1B);
        border = const Color(0xFFFECACA);
        break;
      default:
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF3730A3);
        border = const Color(0xFFC7D2FE);
    }
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      bottom: visible ? 24 : -80,
      right: 24,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1 : 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Text(toast?.message ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ),
        ),
      ),
    );
  }
}
