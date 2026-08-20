import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/teacher_timetable_entity.dart';
import '../providers/teacher_timetable_providers.dart';
import '../widgets/my_classes/load_error_card.dart';
import '../widgets/timetable/daily_list.dart';
import '../widgets/timetable/timetable_kpi_row.dart';
import '../widgets/timetable/weekly_grid.dart';

/// Teacher Timetable — mirrors `(teacher-portal)/teacher/timetable/page.tsx`.
/// No search/filter/sort/dialogs exist on this page at all (confirmed by
/// reading the full web source) — it's a static weekly grid with a KPI
/// row above it.
class TeacherTimetablePage extends ConsumerWidget {
  const TeacherTimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(teacherTimetableProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(teacherTimetableProvider),
          child: timetableAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _errorPage(ref, error),
            data: (timetable) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pageHeader(timetable.weekOf),
                  const SizedBox(height: 20),
                  TimetableKpiRow(kpis: timetable.kpis),
                  const SizedBox(height: 20),
                  _grid(timetable.days),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageHeader(String weekOf) {
    // Now its own card — same white/bordered/shadowed style already used
    // by the KPI row and the grid/list below it — instead of floating
    // text directly on the page background, per explicit request.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.ink1.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TEACHER PORTAL · TIMETABLE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.ink2),
          ),
          const SizedBox(height: 6),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink1),
              children: [
                TextSpan(text: 'My '),
                TextSpan(text: 'Timetable', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.brandPurple)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Week of $weekOf · Mon–Sat', style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
        ],
      ),
    );
  }

  Widget _grid(List<TimetableDayEntity> days) {
    if (days.every((d) => d.periods.isEmpty)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 32, color: AppColors.ink2.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No timetable configured yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink1)),
            const SizedBox(height: 6),
            const Text(
              'Ask your administrator to set up the class timetable.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.ink2),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return WeeklyGrid(days: days);
        return DailyList(days: days);
      },
    );
  }

  Widget _errorPage(WidgetRef ref, Object error) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: LoadErrorCard(
              title: 'Could not load timetable',
              message: error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.invalidate(teacherTimetableProvider),
            ),
          ),
        ),
      ),
    );
  }
}
