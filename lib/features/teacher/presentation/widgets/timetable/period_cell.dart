import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/teacher_timetable_entity.dart';
import 'subject_color.dart';

/// Exact port of web's `PeriodCell`/`EmptyCell` — subject-color-coded card,
/// break placeholder, or an empty dashed slot when nothing is scheduled.
class PeriodCell extends StatelessWidget {
  final TimetableSlotEntity? slot;
  const PeriodCell({super.key, this.slot});

  @override
  Widget build(BuildContext context) {
    final s = slot;
    if (s == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.all(6),
      );
    }
    if (s.isBreak) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text('Break', style: TextStyle(fontSize: 10, color: AppColors.ink2)),
      );
    }

    final col = subjectColor(s.subject);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: col.bg,
            border: Border.all(color: col.border, width: s.isNow ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.subject, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: col.text), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                [
                  '${s.className}-${s.sectionName}',
                  if (s.room.isNotEmpty) s.room,
                ].join(' · '),
                style: TextStyle(fontSize: 10, color: col.text.withValues(alpha: 0.8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (s.from.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('${s.from}–${s.to}', style: TextStyle(fontSize: 9, color: col.text.withValues(alpha: 0.65))),
              ],
            ],
          ),
        ),
        if (s.isNow)
          Positioned(
            top: -5,
            right: 4,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.3), blurRadius: 0, spreadRadius: 2)],
              ),
            ),
          ),
      ],
    );
  }
}
