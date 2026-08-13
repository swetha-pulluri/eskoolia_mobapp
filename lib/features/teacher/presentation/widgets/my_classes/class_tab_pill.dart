import 'package:flutter/material.dart';
import '../../../domain/entities/my_class_entity.dart';

class _TabPalette {
  final Color bg;
  final Color text;
  final Color border;
  final Color active;
  const _TabPalette({required this.bg, required this.text, required this.border, required this.active});
}

/// Exact 6-color cycling palette from web's `TAB_COLORS` (`classes/page.tsx`).
const List<_TabPalette> _tabColors = [
  _TabPalette(bg: Color(0xFFEEF2FF), text: Color(0xFF4F46E5), border: Color(0xFFC7D2FE), active: Color(0xFF6D4AFF)),
  _TabPalette(bg: Color(0xFFF0FDF4), text: Color(0xFF15803D), border: Color(0xFFBBF7D0), active: Color(0xFF16A34A)),
  _TabPalette(bg: Color(0xFFFFF7ED), text: Color(0xFFC2410C), border: Color(0xFFFED7AA), active: Color(0xFFEA580C)),
  _TabPalette(bg: Color(0xFFFDF4FF), text: Color(0xFFA21CAF), border: Color(0xFFE9D5FF), active: Color(0xFF9333EA)),
  _TabPalette(bg: Color(0xFFFFFBEB), text: Color(0xFFB45309), border: Color(0xFFFDE68A), active: Color(0xFFD97706)),
  _TabPalette(bg: Color(0xFFF0F9FF), text: Color(0xFF0369A1), border: Color(0xFFBAE6FD), active: Color(0xFF0284C7)),
];

/// One class/section tab pill in the Class Overview screen's horizontal tab
/// row — exact port of `classes/page.tsx`'s tab pills (deterministic
/// per-index color, star badge for class-teacher sections, trailing
/// student-count bubble).
class ClassTabPill extends StatelessWidget {
  final MyClassEntity cls;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  const ClassTabPill({super.key, required this.cls, required this.index, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _tabColors[index % _tabColors.length];
    final bg = isActive ? palette.active : palette.bg;
    final border = isActive ? palette.active : palette.border;
    final textColor = isActive ? Colors.white : palette.text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: isActive ? 1.5 : 1),
          boxShadow: isActive ? [BoxShadow(color: palette.active.withValues(alpha: 0.33), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cls.isClassTeacher) ...[
              Text('★', style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: isActive ? 1 : 0.7))),
              const SizedBox(width: 4),
            ],
            Text(
              '${cls.className}‑${cls.sectionName}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.25) : border,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${cls.studentCount}',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isActive ? Colors.white : palette.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
