import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/teacher_timetable_entity.dart';
import 'period_cell.dart';

/// Exact port of web's weekly grid `<table>` — Period column + one column
/// per day, one row per unique period number across the whole week.
class WeeklyGrid extends StatelessWidget {
  final List<TimetableDayEntity> days;
  const WeeklyGrid({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final allPeriods = <int>{};
    for (final d in days) {
      for (final p in d.periods) {
        if (p.period != null) allPeriods.add(p.period!);
      }
    }
    final sortedPeriods = allPeriods.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.ink1.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 700),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
            columnWidths: {0: const FixedColumnWidth(70), for (var i = 1; i <= days.length; i++) i: const FixedColumnWidth(140)},
            children: [
              _headerRow(),
              for (final periodNum in sortedPeriods) _periodRow(periodNum),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: const BoxDecoration(color: AppColors.bg2),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text('PERIOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.ink2)),
        ),
        for (final d in days)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: d.isToday ? const Color(0xFFEEEAFF) : Colors.transparent,
              borderRadius: d.isToday ? const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  d.day,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w600,
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
      ],
    );
  }

  TableRow _periodRow(int periodNum) {
    return TableRow(
      children: [
        Container(
          color: AppColors.bg2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text('P$periodNum', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink2)),
        ),
        for (final d in days)
          Container(
            color: d.isToday ? const Color(0x4DEEEAFF) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            alignment: Alignment.topLeft,
            child: PeriodCell(slot: d.periods.where((p) => p.period == periodNum).firstOrNull),
          ),
      ],
    );
  }
}
