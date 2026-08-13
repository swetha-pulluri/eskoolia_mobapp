import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/teacher_timetable_entity.dart';

/// Exact port of web's `KpiCard`/KPI row on the Timetable page.
class TimetableKpiRow extends StatelessWidget {
  final TimetableKpisEntity kpis;
  const TimetableKpiRow({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 500;
        final cards = [
          _kpiCard('PERIODS THIS WEEK', kpis.totalPeriods, 'Teaching slots', Icons.access_time),
          _kpiCard('TEACHING DAYS', kpis.teachingDays, 'Days with classes', Icons.calendar_today_outlined),
          _kpiCard('FREE PERIODS', kpis.freePeriods, 'For grading & prep', Icons.access_time),
          _kpiCard('COVER ASSIGNMENTS', kpis.coverAssignments, 'This week', Icons.calendar_today_outlined),
        ];
        return GridView.count(
          crossAxisCount: narrow ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: narrow ? 1.5 : 1.1,
          children: cards,
        );
      },
    );
  }

  Widget _kpiCard(String label, int value, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.ink1.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.ink2),
                ),
              ),
              Icon(icon, size: 15, color: AppColors.ink2.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink1, height: 1)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
        ],
      ),
    );
  }
}
