import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/student_profile_entity.dart';

/// Mirrors `AcademicTab` in `StudentProfileDrawer.tsx`, minus the
/// permission-gated "view only" banner (decorative on web today — no edit
/// UI exists behind it regardless of permission — so this renders plain
/// read-only, disclosed in the My Classes plan rather than silently
/// omitted).
class AcademicTab extends StatelessWidget {
  final List<ExamMarkEntity>? marks;
  const AcademicTab({super.key, required this.marks});

  @override
  Widget build(BuildContext context) {
    final rows = marks ?? const [];
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 28, color: AppColors.ink3.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              const Text('No exam records yet.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<ExamMarkEntity>>{};
    for (final m in rows) {
      final key = m.term.isNotEmpty ? m.term : (m.examName.isNotEmpty ? m.examName : 'Other');
      grouped.putIfAbsent(key, () => []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final entry in grouped.entries) ...[
          Text(
            entry.key.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
            children: [
              const TableRow(children: [
                _HeaderCell('SUBJECT'),
                _HeaderCell('OBTAINED'),
                _HeaderCell('FULL MARKS'),
                _HeaderCell('RESULT'),
              ]),
              for (final m in entry.value) _markRow(m),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  TableRow _markRow(ExamMarkEntity m) {
    final (bg, fg, label) = m.absent
        ? (const Color(0xFFF5F5FB), AppColors.ink2, 'Absent')
        : m.obtained >= m.passMarks
            ? (const Color(0xFFF0FDF4), const Color(0xFF15803D), 'Pass')
            : (const Color(0xFFFEF2F2), const Color(0xFFB91C1C), 'Fail');
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(m.subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink1)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(m.absent ? '—' : m.obtained.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink1)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(m.fullMarks.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
          ),
        ),
      ),
    ]);
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink3)),
    );
  }
}
