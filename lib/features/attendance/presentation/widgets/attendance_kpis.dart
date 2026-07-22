import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entities.dart';

/// Attendance KPIs — converted from web
/// `attendance/student/components/AttendanceKPIs.tsx`.
class AttendanceKpis extends StatelessWidget {
  final KpiDataEntity? data;
  final String? selectedDate;
  final String? today;
  final String? error;

  const AttendanceKpis({super.key, required this.data, this.selectedDate, this.today, this.error});

  String get _onText {
    final isToday = selectedDate == null || today == null || selectedDate == today;
    if (isToday) return 'Today';
    final d = DateTime.tryParse(selectedDate!);
    if (d == null) return 'on $selectedDate';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'on ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (data == null && error != null) return _errorGrid();
    if (data == null) return _skeletonGrid();
    return _dataGrid(data!);
  }

  /// Lays out [children] in a 2-column grid with equal column widths, same as
  /// `GridView.count(crossAxisCount: 2)`, but each row's height is intrinsic
  /// to its content instead of a fixed aspect ratio — avoiding RenderFlex
  /// overflow when a card's content needs more height than the ratio allows.
  Widget _grid(List<Widget> children) {
    const spacing = 12.0;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: spacing));
      final a = children[i];
      final b = i + 1 < children.length ? children[i + 1] : null;
      rows.add(LayoutBuilder(builder: (context, constraints) {
        final cellWidth = b == null ? constraints.maxWidth : (constraints.maxWidth - spacing) / 2;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: b == null
                ? [SizedBox(width: cellWidth, child: a)]
                : [SizedBox(width: cellWidth, child: a), const SizedBox(width: spacing), SizedBox(width: cellWidth, child: b)],
          ),
        );
      }));
    }
    return Column(children: rows);
  }

  Widget _errorGrid() {
    const labels = ['Present', 'Absent', 'Late Arrivals', 'RTE Compliance Risk'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _grid(labels
          .map((label) => _cardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    const Text('—', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), height: 1)),
                    const SizedBox(height: 8),
                    Text('Failed to load. $error', style: const TextStyle(fontSize: 12, color: Color(0xFFC2264E))),
                  ],
                ),
              ))
          .toList()),
    );
  }

  Widget _skeletonGrid() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _grid(List.generate(4, (i) => _skeletonCard())),
    );
  }

  Widget _skeletonCard() {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(height: height, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(4))),
        );
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: bar(0.33, 12)), const SizedBox(width: 8), Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)))]),
          const SizedBox(height: 12),
          bar(0.25, 40),
          const SizedBox(height: 12),
          bar(0.66, 12),
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }

  Widget _dataGrid(KpiDataEntity d) {
    final presentTrend = d.deltaPct > 0 ? '+${d.deltaPct}%' : d.deltaPct < 0 ? '-${d.deltaPct.abs()}%' : '+${d.presentPct}%';

    final absentDelta = d.absentDelta ?? -d.absentToday;
    String absentTrend;
    Color absentTrendColor;
    if (absentDelta < 0) {
      absentTrend = '↓ ${absentDelta.abs()} vs yesterday';
      absentTrendColor = const Color(0xFF16A34A);
    } else if (absentDelta > 0) {
      absentTrend = '↑ $absentDelta vs yesterday';
      absentTrendColor = const Color(0xFFE11D48);
    } else {
      absentTrend = 'Same as yesterday';
      absentTrendColor = const Color(0xFF9CA0AE);
    }

    String absentReasonSub;
    if (d.absentToday == 0) {
      absentReasonSub = 'No absences marked.';
    } else if (d.absentWithReason > 0) {
      absentReasonSub = '${d.absentWithReason} of ${d.absentToday} absent entr${d.absentToday == 1 ? "y has" : "ies have"} a recorded reason.';
    } else {
      absentReasonSub = 'Reasons are pending for absent entries.';
    }

    String lateSub;
    if (d.lateToday == 0) {
      lateSub = 'No late entries';
    } else if (d.lateStudentName != null) {
      lateSub = d.lateStudentName! + (d.lateMinutes != null ? ' - ${d.lateMinutes} min late' : '');
    } else {
      lateSub = '${d.lateToday} student${d.lateToday == 1 ? "" : "s"} arrived late today';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _grid([
        _KpiCard(
          label: 'Present $_onText',
          value: d.totalStudents == 0 ? '0/0' : '${d.presentToday}/${d.totalStudents}',
          sub: '${d.presentPct}% attendance ${_onText.toLowerCase()}',
          badgeText: 'PR',
          badgeBg: const Color(0xFFECFDF5),
          badgeColor: const Color(0xFF16A34A),
          trend: presentTrend,
          trendColor: const Color(0xFF16A34A),
        ),
        _KpiCard(
          label: 'Absent $_onText',
          value: '${d.absentToday}',
          sub: absentReasonSub,
          badgeText: 'AB',
          badgeBg: const Color(0xFFFFF1F2),
          badgeColor: const Color(0xFFE11D48),
          trend: absentTrend,
          trendColor: absentTrendColor,
        ),
        _KpiCard(
          label: 'Late Arrivals',
          value: '${d.lateToday}',
          sub: lateSub,
          badgeText: 'LT',
          badgeBg: const Color(0xFFFFFBEB),
          badgeColor: const Color(0xFFD97706),
        ),
        _KpiCard(
          label: 'RTE Compliance Risk',
          value: '${d.rteAtRisk}',
          sub: 'Shows students below 75% cumulative attendance. Calculated as present days / working days.',
          badgeText: 'RT',
          badgeBg: const Color(0xFFF5F3FF),
          badgeColor: const Color(0xFF7C3AED),
        ),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;
  final String? trend;
  final Color trendColor;

  const _KpiCard({
    required this.label,
    required this.value,
    this.sub,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
    this.trend,
    this.trendColor = const Color(0xFF16A34A),
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
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.6)),
              ),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFF111827), height: 1))),
              if (trend != null) Text(trend!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: trendColor)),
            ],
          ),
          if (sub != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(sub!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
        ],
      ),
    );
  }
}
