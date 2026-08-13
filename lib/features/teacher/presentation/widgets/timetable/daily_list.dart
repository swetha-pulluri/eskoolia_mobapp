import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/teacher_timetable_entity.dart';
import 'period_cell.dart';

/// Narrow-screen adaptation of the weekly grid — no mobile-specific layout
/// exists on web to mirror here (confirmed, same as My Classes/Home), so
/// this is a disclosed Flutter-only design call: one section per day,
/// periods listed top-to-bottom, using the exact same `PeriodCell` as the
/// wide grid so the data/visuals stay identical.
class DailyList extends StatelessWidget {
  final List<TimetableDayEntity> days;
  const DailyList({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in days) _daySection(d),
      ],
    );
  }

  Widget _daySection(TimetableDayEntity d) {
    final periods = [...d.periods]..sort((a, b) => (a.period ?? 0).compareTo(b.period ?? 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: d.isToday ? const Color(0xFFEEEAFF) : AppColors.bg2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  d.day,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: d.isToday ? AppColors.brandPurple : AppColors.ink1,
                  ),
                ),
                if (d.isToday) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.brandPurple, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Today', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
          if (periods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              child: Text('No periods scheduled.', style: TextStyle(fontSize: 12, color: AppColors.ink2)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final p in periods)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              p.period != null ? 'P${p.period}' : '',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink3),
                            ),
                          ),
                          Expanded(child: PeriodCell(slot: p)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
