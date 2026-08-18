import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/attendance_calendar_entity.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../providers/parent_providers.dart';
import '../widgets/sibling_tabs.dart';

const Color _brandPurple = Color(0xFF6D4AFF);
const Color _ok = Color(0xFF0E9F6E);
const Color _warn = Color(0xFFD97706);
const Color _danger = Color(0xFFDC2626);
const Color _info = Color(0xFF0284C7);

class _TypeConfig {
  final String label;
  final Color color;
  final Color bg;
  const _TypeConfig(this.label, this.color, this.bg);
}

const _typeConfig = {
  'P': _TypeConfig('Present', _ok, Color(0x1F22C55E)),
  'A': _TypeConfig('Absent', _danger, Color(0xFFFEF2F2)),
  'L': _TypeConfig('Late', _warn, Color(0xFFFFFBEB)),
  'F': _TypeConfig('Half Day', _brandPurple, Color(0xFFEEEAFF)),
  'H': _TypeConfig('Holiday', _info, Color(0xFFF0F9FF)),
};

/// Attendance Calendar — mobile port of web's
/// `(parent-portal)/parent/attendance/page.tsx`: a month calendar grid
/// colored by daily attendance type, a month summary, a legend, and the
/// month's school holidays. Mobile simplification: web's 2-column
/// (calendar + 280px sidebar) grid becomes a single stacked column.
class AttendancePage extends ConsumerWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(parentMeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentMeProvider);
          ref.invalidate(attendanceCalendarProvider);
        },
        child: meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(error: error, onRetry: () => ref.invalidate(parentMeProvider)),
          data: (me) => _AttendanceContent(me: me),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _LoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 32, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text('Could not load attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                  const SizedBox(height: 6),
                  Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceContent extends ConsumerWidget {
  final ParentMeEntity me;
  const _AttendanceContent({required this.me});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedChildProvider);
    final month = ref.watch(selectedMonthProvider);
    final calendarAsync = ref.watch(attendanceCalendarProvider);
    final data = calendarAsync.valueOrNull;
    final loading = calendarAsync.isLoading;
    final hasError = calendarAsync.hasError;
    final noData = !loading && !hasError && data != null && data.days.isEmpty && data.holidays.isEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.ink1, fontWeight: FontWeight.w600),
              children: const [
                TextSpan(text: 'Attendance '),
                TextSpan(text: 'Calendar', style: TextStyle(color: _brandPurple, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Monthly attendance record for your child.', style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.4)),
          if (me.children.length > 1) ...[
            const SizedBox(height: 14),
            SiblingTabs(children: me.children, selectedId: selected?.id),
          ],
          const SizedBox(height: 14),
          _MonthNav(year: month.year, month: month.month),
          const SizedBox(height: 10),
          PremiumCard(
            radius: 14,
            color: Colors.white,
            borderColor: AppColors.border,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: loading
                  ? _CalendarSkeleton()
                  : hasError
                      ? const SizedBox(
                          height: 60,
                          child: Center(child: Text('Could not load attendance. Please try again.', style: TextStyle(fontSize: 12.5, color: _danger), textAlign: TextAlign.center)),
                        )
                      : noData
                          ? const SizedBox(
                              height: 60,
                              child: Center(child: Text('No attendance records for this month.', style: TextStyle(fontSize: 12.5, color: AppColors.ink3))),
                            )
                          : _CalendarGrid(year: month.year, month: month.month, days: data?.days ?? const [], holidays: data?.holidays ?? const []),
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(monthLabel: DateFormat('MMMM').format(DateTime(month.year, month.month)), summary: data?.summary, loading: loading),
          const SizedBox(height: 12),
          const _LegendCard(),
          if ((data?.holidays.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            _HolidaysCard(holidays: data!.holidays),
          ],
        ],
      ),
    );
  }
}

class _MonthNav extends ConsumerWidget {
  final int year;
  final int month;
  const _MonthNav({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left, () => ref.read(selectedMonthProvider.notifier).previous()),
          Text(DateFormat('MMMM yyyy').format(DateTime(year, month)), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink1)),
          _navButton(Icons.chevron_right, () => ref.read(selectedMonthProvider.notifier).next()),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.ink2),
      ),
    );
  }
}

const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class _CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final List<AttendanceDayEntity> days;
  final List<HolidayEntity> holidays;

  const _CalendarGrid({required this.year, required this.month, required this.days, required this.holidays});

  @override
  Widget build(BuildContext context) {
    final dayMap = {for (final d in days) d.date: d.type};
    final holidayMap = {for (final h in holidays) h.date: h.title};

    final firstDay = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final cells = <int?>[
      for (var i = 0; i < firstDay; i++) null,
      for (var d = 1; d <= daysInMonth; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(w, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.4)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          childAspectRatio: 1,
          children: [
            for (final day in cells)
              if (day == null)
                const SizedBox.shrink()
              else
                _dayCell(day, dayMap, holidayMap, todayStr),
          ],
        ),
      ],
    );
  }

  Widget _dayCell(int day, Map<String, String> dayMap, Map<String, String> holidayMap, String todayStr) {
    final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final type = dayMap[dateStr];
    final isHoliday = holidayMap.containsKey(dateStr);
    final cfg = type != null ? _typeConfig[type] : (isHoliday ? _typeConfig['H'] : null);
    final isToday = dateStr == todayStr;

    return Container(
      decoration: BoxDecoration(
        color: cfg?.bg ?? AppColors.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isToday ? _brandPurple : Colors.transparent, width: 2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$day', style: TextStyle(fontSize: 11.5, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: cfg?.color ?? AppColors.ink3)),
          if (type != null)
            Text(type == 'F' ? '½' : type, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: cfg?.color, height: 1.2))
          else if (isHoliday)
            const Text('H', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: _info, height: 1.2)),
        ],
      ),
    );
  }
}

class _CalendarSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      childAspectRatio: 1,
      children: [
        for (var i = 0; i < 35; i++) Container(decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(8))),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String monthLabel;
  final AttendanceCalendarSummaryEntity? summary;
  final bool loading;
  const _SummaryCard({required this.monthLabel, required this.summary, required this.loading});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: const Color(0xFFEEEAFF), borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.calendar_month_outlined, size: 13, color: _brandPurple),
                ),
                const SizedBox(width: 8),
                Text('$monthLabel Summary', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: loading
                ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : summary == null
                    ? const SizedBox(height: 40, child: Center(child: Text('No data', style: TextStyle(fontSize: 12, color: AppColors.ink3))))
                    : _summaryBody(summary!),
          ),
        ],
      ),
    );
  }

  Widget _summaryBody(AttendanceCalendarSummaryEntity att) {
    final pct = att.pct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pct != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Attendance Rate', style: TextStyle(fontSize: 12, color: AppColors.ink2)),
              Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pct >= 85 ? _ok : (pct >= 70 ? _warn : _danger))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(pct >= 85 ? _ok : (pct >= 70 ? _warn : _danger)),
            ),
          ),
          const SizedBox(height: 14),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            _stat('Present', att.present, _ok),
            _stat('Absent', att.absent, _danger),
            _stat('Late', att.late, _warn),
            _stat('Half Day', att.halfDay, _brandPurple),
          ],
        ),
        if (att.total > 0) ...[
          const SizedBox(height: 10),
          Center(
            child: Text('${att.total} school day${att.total != 1 ? 's' : ''} recorded', style: const TextStyle(fontSize: 11.5, color: AppColors.ink3)),
          ),
        ],
      ],
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.ink3)),
        ],
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LEGEND', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.6)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                for (final type in ['P', 'A', 'L', 'F', 'H']) _legendItem(type, _typeConfig[type]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String type, _TypeConfig cfg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: cfg.bg, borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: Text(type == 'F' ? '½' : type, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: cfg.color)),
        ),
        const SizedBox(width: 6),
        Text(cfg.label, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
      ],
    );
  }
}

class _HolidaysCard extends StatelessWidget {
  final List<HolidayEntity> holidays;
  const _HolidaysCard({required this.holidays});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Text('HOLIDAYS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.6)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [for (var i = 0; i < holidays.length; i++) _holidayRow(holidays[i], i < holidays.length - 1)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _holidayRow(HolidayEntity h, bool showDivider) {
    final d = DateTime.tryParse(h.date);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(d != null ? '${d.day}' : '—', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _info)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(h.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink1)),
                if (d != null) Text(DateFormat('EEE, d MMM').format(d), style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
