import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../domain/entities/teacher_me_entity.dart';
import '../providers/teacher_providers.dart';

/// "Today's Schedule" card — the `teacher-day-plan` widget, real DB-backed
/// data from `teacherMeProvider`'s `todaysPeriods` (built server-side from
/// `ClassRoutineSlot`, not mock — see `TeacherMeEntity`'s doc comment).
class TodayScheduleCard extends ConsumerWidget {
  const TodayScheduleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(teacherMeProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TODAY'S SCHEDULE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: AppColors.ink1)),
          const SizedBox(height: 2),
          Text(app_date_utils.DateUtils.getFormattedDate(), style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
          const SizedBox(height: 12),
          meAsync.when(
            data: (me) => me.todaysPeriods.isEmpty
                ? const Text('No periods scheduled today', style: TextStyle(fontSize: 13, color: AppColors.ink3))
                : Column(
                    children: [
                      for (final period in me.todaysPeriods) _periodRow(period),
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Could not load schedule: $e', style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _periodRow(TeacherPeriodEntity period) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: period.isNow ? AppColors.purpleSoft : AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text('${period.from}–${period.to}', style: const TextStyle(fontSize: 11.5, color: AppColors.ink3)),
          ),
          Expanded(
            child: Text(
              '${period.subject} · ${period.className} ${period.sectionName}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if ((period.room ?? '').isNotEmpty)
            Text(period.room!, style: const TextStyle(fontSize: 11.5, color: AppColors.ink3)),
        ],
      ),
    );
  }
}
