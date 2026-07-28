import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/attendance_monthly_report_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/repositories/hr_repository.dart';
import '../providers/hr_provider.dart';

const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _ink = Color(0xFF0B0B14);
const _muted = Color(0xFF9CA0AE);
const _line = Color(0xFFE6E6EC);
const _brand = Color(0xFF4729F4);

Color _pctColor(int pct) => pct >= 75 ? const Color(0xFF0A8C5A) : pct >= 50 ? const Color(0xFFB4721B) : const Color(0xFFC2264E);
Color _pctBg(int pct) => pct >= 75 ? const Color(0xFFE4F6ED) : pct >= 50 ? const Color(0xFFFEF3C7) : const Color(0xFFFCE8EE);

class _WeekRange {
  final int week;
  final String dateRange;
  final int start;
  final int end;
  const _WeekRange({required this.week, required this.dateRange, required this.start, required this.end});
}

List<_WeekRange> _weekRanges(int month, int year) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final monthAbbr = _monthNames[month - 1].substring(0, 3);
  final ranges = <_WeekRange>[];
  var weekIdx = 0;
  var cursor = 1;
  while (cursor <= daysInMonth) {
    final dow = DateTime(year, month, cursor).weekday % 7; // 0=Sun..6=Sat, matching JS getDay()
    final end = math.min(cursor + (6 - dow), daysInMonth);
    weekIdx += 1;
    ranges.add(_WeekRange(week: weekIdx, dateRange: '$monthAbbr $cursor–$end', start: cursor, end: end));
    cursor = end + 1;
    if (weekIdx > 7) break;
  }
  return ranges;
}

/// Real port of `StaffMonthlyReport.tsx` on `origin/demo` — the actual live
/// HR backend's `GET /api/v1/hr/staff-attendance/monthly-report/` (an
/// earlier pass checked only the stale `main` branch and wrongly concluded
/// this endpoint didn't exist, so this used to be a reduced-scope,
/// client-aggregated substitute). Week-donut cards + Monthly Avg, Top
/// Absent/Leave Reasons, and a per-staff summary table with CSV download.
class MonthlyAttendanceReport extends ConsumerStatefulWidget {
  final List<DepartmentEntity> departments;
  const MonthlyAttendanceReport({super.key, required this.departments});

  @override
  ConsumerState<MonthlyAttendanceReport> createState() => _MonthlyAttendanceReportState();
}

class _MonthlyAttendanceReportState extends ConsumerState<MonthlyAttendanceReport> {
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;
  int? _deptId;
  late int _pendingYear = _year;
  late int _pendingMonth = _month;
  int? _pendingDeptId;
  bool _loading = false;
  String? _error;
  AttendanceMonthlyReportEntity? _report;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _year = _pendingYear;
      _month = _pendingMonth;
      _deptId = _pendingDeptId;
      _loading = true;
      _error = null;
    });
    try {
      final report = await ref.read(hrRepositoryProvider).getMonthlyReport(month: _month, year: _year, departmentId: _deptId);
      if (mounted) setState(() => _report = report);
    } catch (e, st) {
      // Not an HrApiException — a client-side bug (bad parsing, unexpected
      // response shape), not a backend-reported error. Log the real cause
      // instead of only ever showing a generic message.
      if (e is! HrApiException) AppLogger.error('Monthly report failed unexpectedly', e, st);
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Failed to load report: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    final rows = _report?.rows ?? const [];
    final headers = ['Staff No', 'Name', 'Department', 'Present', 'Absent', 'Leave', 'Attendance %'];
    String quote(String v) => '"${v.replaceAll('"', '""')}"';
    final lines = rows.map((r) {
      final total = r.present + r.absent + r.leave;
      final pct = total == 0 ? 0 : (r.present / total * 100).round();
      return [quote(r.staffNo), quote(r.name), quote(r.departmentName), r.present, r.absent, r.leave, '$pct%'].join(',');
    });
    final csv = [headers.join(','), ...lines].join('\n');
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final monthLabel = '${_monthNames[_month - 1]}-$_year';
    await Share.shareXFiles([XFile.fromData(bytes, name: 'staff-attendance-report-$monthLabel.csv', mimeType: 'text/csv')]);
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final records = report?.records ?? const [];
    final rows = report?.rows ?? const [];
    final deptLabel = _deptId != null ? (widget.departments.where((d) => d.id == _deptId).map((d) => d.name).firstOrNull ?? 'Department') : 'All Departments';
    final monthLabel = '${_monthNames[_month - 1]} $_year';

    final weekRanges = _weekRanges(_month, _year);
    final weekCards = weekRanges.map((w) {
      final wr = records.where((r) {
        final day = DateTime.tryParse(r.attendanceDate)?.day;
        return day != null && day >= w.start && day <= w.end;
      }).toList();
      final present = wr.where((r) => r.attendanceType == 'P').length;
      final total = wr.length;
      final days = wr.map((r) => r.attendanceDate).toSet().length;
      return (week: w.week, dateRange: w.dateRange, present: present, absent: wr.where((r) => r.attendanceType == 'A').length, total: total, days: days, pct: total > 0 ? (present / total * 100).round() : 0);
    }).toList();

    final overallPresent = records.where((r) => r.attendanceType == 'P').length;
    final overallTotal = records.length;
    final overallPct = overallTotal > 0 ? (overallPresent / overallTotal * 100).round() : 0;
    final schoolDays = records.map((r) => r.attendanceDate).toSet().length;

    var totalP = 0, totalA = 0, totalL = 0;
    for (final r in rows) {
      totalP += r.present;
      totalA += r.absent;
      totalL += r.leave;
    }
    final totalAll = totalP + totalA + totalL;
    final totalPct = totalAll > 0 ? (totalP / totalAll * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFFAFAFD),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  const Text('Monthly Attendance Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                  const SizedBox(height: 2),
                  Text('$deptLabel · $monthLabel', style: const TextStyle(fontSize: 11, color: _muted)),
                ]),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    initialValue: _pendingYear,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), isDense: true),
                    items: [for (var y = DateTime.now().year - 3; y <= DateTime.now().year + 1; y++) DropdownMenuItem(value: y, child: Text('$y'))],
                    onChanged: (v) => setState(() => _pendingYear = v ?? _pendingYear),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    initialValue: _pendingMonth,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder(), isDense: true),
                    items: [for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]))],
                    onChanged: (v) => setState(() => _pendingMonth = v ?? _pendingMonth),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<int?>(
                    initialValue: _pendingDeptId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All Departments')),
                      for (final d in widget.departments) DropdownMenuItem<int?>(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _pendingDeptId = v),
                  ),
                ),
                FilledButton(onPressed: _loading ? null : _generate, child: Text(_loading ? 'Loading…' : 'Generate')),
                OutlinedButton(onPressed: (_loading || rows.isEmpty) ? null : _download, child: const Text('Download')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _error != null
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFFFF0F3), border: Border.all(color: const Color(0xFFFBCFE8)), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFC2264E), fontSize: 12))),
                      TextButton(onPressed: _generate, child: const Text('Retry')),
                    ]),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final w in weekCards) _weekCard(w),
                          _monthlyAvgCard(overallPct, weekCards.where((w) => w.total > 0).length, schoolDays, overallTotal),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 700;
                        final reasons = [
                          Expanded(child: _reasonsCard('Top Absent Reasons', 'Ranked from attendance notes for the selected period.', report?.topAbsentReasons ?? const [], const Color(0xFFFFF0F3), const Color(0xFFC2264E), const Color(0xFFFFF7F9))),
                          const SizedBox(width: 16, height: 16),
                          Expanded(child: _reasonsCard('Top Leave Reasons', 'Frequent leave reasons captured during attendance.', report?.topLeaveReasons ?? const [], const Color(0xFFEFF6FF), const Color(0xFF2563EB), const Color(0xFFF5F9FF))),
                        ];
                        return wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: reasons) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: reasons);
                      }),
                      const SizedBox(height: 20),
                      if (rows.isNotEmpty) ...[
                        const Text('STAFF SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: _muted)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Staff')),
                              DataColumn(label: Text('Present')),
                              DataColumn(label: Text('Absent')),
                              DataColumn(label: Text('Leave')),
                              DataColumn(label: Text('Attendance %')),
                            ],
                            rows: [
                              for (final r in rows)
                                DataRow(cells: [
                                  DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                    Text(r.name.isEmpty ? '—' : r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                    Text([r.staffNo, r.departmentName].where((s) => s.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 10.5, color: _muted)),
                                  ])),
                                  DataCell(Text('${r.present}', style: const TextStyle(color: Color(0xFF0A8C5A), fontWeight: FontWeight.w700))),
                                  DataCell(Text('${r.absent}', style: const TextStyle(color: Color(0xFFC2264E), fontWeight: FontWeight.w700))),
                                  DataCell(Text('${r.leave}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700))),
                                  DataCell(_pctChip((r.present + r.absent + r.leave) == 0 ? 0 : (r.present / (r.present + r.absent + r.leave) * 100).round())),
                                ]),
                              DataRow(cells: [
                                const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
                                DataCell(Text('$totalP', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0A8C5A)))),
                                DataCell(Text('$totalA', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC2264E)))),
                                DataCell(Text('$totalL', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB)))),
                                DataCell(_pctChip(totalPct)),
                              ]),
                            ],
                          ),
                        ),
                      ] else if (overallTotal == 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(children: [
                              Text('No attendance data for $monthLabel', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              const Text('No records found for the selected filters.', style: TextStyle(fontSize: 11.5, color: _muted)),
                            ]),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _pctChip(int pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _pctBg(pct), borderRadius: BorderRadius.circular(999)),
      child: Text('$pct%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _pctColor(pct))),
    );
  }

  Widget _weekCard(({int week, String dateRange, int present, int absent, int total, int days, int pct}) w) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: w.total > 0 ? Colors.white : const Color(0xFFFAFAFD),
        border: Border.all(color: w.total > 0 ? _line : const Color(0xFFF0F0F6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Opacity(
        opacity: w.total > 0 ? 1 : 0.5,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 4, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('Week ${w.week}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _ink)),
            if (w.total > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: _pctBg(w.pct), borderRadius: BorderRadius.circular(999)),
                child: Text(w.pct >= 75 ? 'Good' : w.pct >= 50 ? 'Avg' : 'Low', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _pctColor(w.pct))),
              ),
          ]),
          Text(w.dateRange, style: const TextStyle(fontSize: 9, color: _muted)),
          const SizedBox(height: 6),
          if (w.total > 0) ...[
            Center(child: _DonutRing(pct: w.pct)),
            const SizedBox(height: 6),
            Text('${w.days} ${w.days == 1 ? 'day' : 'days'}', style: const TextStyle(fontSize: 9, color: _muted)),
            _legendRow('Present', w.present, const Color(0xFF0A8C5A)),
            _legendRow('Absent', w.absent, const Color(0xFFC2264E)),
          ] else
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('No data', style: TextStyle(fontSize: 9, color: Color(0xFFC8C8D4))))),
        ]),
      ),
    );
  }

  Widget _monthlyAvgCard(int overallPct, int weeksWithData, int schoolDays, int overallTotal) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8F6FF), Color(0xFFEDE9FE)]),
        border: Border.all(color: _brand, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Wrap(spacing: 4, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('Monthly', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _brand)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(999)),
            child: const Text('Avg', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _brand)),
          ),
        ]),
        Text('$weeksWithData wk${weeksWithData != 1 ? 's' : ''} · $schoolDays ${schoolDays == 1 ? 'day' : 'days'}', style: const TextStyle(fontSize: 9, color: _muted)),
        const SizedBox(height: 6),
        if (overallTotal > 0) ...[
          Center(child: _DonutRing(pct: overallPct)),
          const SizedBox(height: 6),
          _legendRow('Present', overallPct, const Color(0xFF0A8C5A), suffix: '%'),
          _legendRow('Absent', 100 - overallPct, const Color(0xFFC2264E), suffix: '%'),
        ] else
          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('No data yet', style: TextStyle(fontSize: 9, color: Color(0xFFC8C8D4))))),
      ]),
    );
  }

  Widget _legendRow(String label, int value, Color color, {String suffix = ''}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF6B6B7B)))),
        Text('$value$suffix', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _reasonsCard(String title, String sub, List<AttendanceReasonInsightEntity> reasons, Color badgeBg, Color badgeColor, Color rowBg) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink)),
              Text(sub, style: const TextStyle(fontSize: 10, color: _muted)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
            child: Text('${reasons.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
          ),
        ]),
        const SizedBox(height: 10),
        if (reasons.isEmpty)
          Text('No ${title.toLowerCase()} insights for the selected filters.', style: const TextStyle(fontSize: 11, color: _muted))
        else
          for (final r in reasons)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: rowBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: Text(r.reason, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Text('${r.count}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor)),
              ]),
            ),
      ]),
    );
  }
}

class _DonutRing extends StatelessWidget {
  final int pct;
  static const _size = 56.0;
  const _DonutRing({required this.pct});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: const Size(_size, _size), painter: _DonutPainter(pct: pct)),
        Text('$pct%', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _pctColor(pct))),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int pct;
  const _DonutPainter({required this.pct});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 6.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final bg = Paint()
      ..color = const Color(0xFFE8E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bg);
    if (pct <= 0) return;
    final fg = Paint()
      ..color = _pctColor(pct)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweep = (pct.clamp(0, 100) / 100) * 2 * math.pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.pct != pct;
}
