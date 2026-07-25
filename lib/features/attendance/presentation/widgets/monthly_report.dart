import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/attendance_entities.dart';
import '../providers/attendance_provider.dart';

const List<Map<String, Object>> kMonths = [
  {'value': 1, 'label': 'January'},
  {'value': 2, 'label': 'February'},
  {'value': 3, 'label': 'March'},
  {'value': 4, 'label': 'April'},
  {'value': 5, 'label': 'May'},
  {'value': 6, 'label': 'June'},
  {'value': 7, 'label': 'July'},
  {'value': 8, 'label': 'August'},
  {'value': 9, 'label': 'September'},
  {'value': 10, 'label': 'October'},
  {'value': 11, 'label': 'November'},
  {'value': 12, 'label': 'December'},
];

const List<String> kMonthAbbr = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

Color _pctColor(int pct) {
  if (pct >= 75) return const Color(0xFF0A8C5A);
  if (pct >= 50) return const Color(0xFFB4721B);
  return const Color(0xFFC2264E);
}

Color _pctBg(int pct) {
  if (pct >= 75) return const Color(0xFFE4F6ED);
  if (pct >= 50) return const Color(0xFFFEF3C7);
  return const Color(0xFFFCE8EE);
}

/// Mirrors web's `getAcademicYears()` exactly (`MonthlyReport.tsx:84-89`) —
/// current year+1 down to current year-3, 5 entries total.
List<String> _academicYears() {
  final yr = DateTime.now().year;
  return [for (var y = yr + 1; y >= yr - 3; y--) '${y - 1}-${y.toString().substring(2)}'];
}

class _WeekRange {
  final int week;
  final String label;
  final String dateRange;
  final int start;
  final int end;
  const _WeekRange({required this.week, required this.label, required this.dateRange, required this.start, required this.end});
}

/// Mirrors web's `getWeekRanges()` exactly (`MonthlyReport.tsx:91-115`):
/// calendar Sunday→Saturday weeks inside the month, partial leading/
/// trailing weeks kept and clamped to the month's real day range.
List<_WeekRange> _weekRanges(int month, int year) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final monthAbbr = kMonthAbbr[month];
  final ranges = <_WeekRange>[];
  var weekIdx = 0;
  var cursor = 1;
  while (cursor <= daysInMonth) {
    final dow = DateTime(year, month, cursor).weekday % 7; // Dart: Mon=1..Sun=7 -> 0=Sun..6=Sat
    final remainingInWeek = 6 - dow;
    final end = math.min(cursor + remainingInWeek, daysInMonth);
    weekIdx += 1;
    ranges.add(_WeekRange(week: weekIdx, label: 'Week $weekIdx', dateRange: '$monthAbbr $cursor–$end', start: cursor, end: end));
    cursor = end + 1;
  }
  return ranges;
}

class _WeekCard {
  final _WeekRange range;
  final int present;
  final int absent;
  final int total;
  final int presentPct;
  final int schoolDays;
  const _WeekCard({required this.range, required this.present, required this.absent, required this.total, required this.presentPct, required this.schoolDays});
}

/// Monthly Attendance Report — converted from the real
/// `MonthlyReport.tsx`, line-for-line: same calendar-week cards (always
/// all weeks of the month, each independently empty/populated), same
/// "Monthly" summary card, same Top Absent/Late Reason cards (always
/// shown, own empty text), same 5-column Student Summary table (Student
/// combines name+admission_no; no Half Day/Holiday columns — the real web
/// table never renders those fields even though the backend returns them),
/// same loading/error/empty states and copy.
class MonthlyReport extends ConsumerStatefulWidget {
  final String selectedDate;
  final List<ClassInfoEntity> classes;

  const MonthlyReport({super.key, required this.selectedDate, required this.classes});

  @override
  ConsumerState<MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends ConsumerState<MonthlyReport> {
  final _today = DateTime.now();

  late String _pendingAcadYear = _defaultAcadYear();
  late int _pendingMonth = _today.month;
  int? _pendingClassId;
  int? _pendingSectionId;

  late int _activeMonth = _today.month;
  late int _activeYear = _today.year;
  int? _activeClassId;
  int? _activeSectionId;
  late String _activeAcadYear = _defaultAcadYear();

  bool _loading = false;
  bool _downloading = false;
  String? _error;
  List<DailyAttendanceRecordEntity> _rawRecords = const [];
  List<MonthlyReportRowEntity> _reportRows = const [];
  ReportInsightsEntity _insights = const ReportInsightsEntity();

  String _defaultAcadYear() {
    final m = _today.month;
    final y = _today.year;
    return m >= 6 ? '$y-${(y + 1).toString().substring(2)}' : '${y - 1}-${y.toString().substring(2)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  List<SectionSummaryEntity> get _pendingSections {
    if (_pendingClassId == null) return const [];
    final cls = widget.classes.where((c) => c.id == _pendingClassId).toList();
    return cls.isEmpty ? const [] : cls.first.sections;
  }

  int _currentAcademicYearStart() {
    final y = _today.year;
    final m = _today.month;
    return m >= 6 ? y : y - 1;
  }

  bool get _isCurrentAcademicYearSelected {
    final m = RegExp(r'^(\d{4})').firstMatch(_pendingAcadYear);
    if (m == null) return false;
    return int.parse(m.group(1)!) == _currentAcademicYearStart();
  }

  List<Map<String, Object>> get _availableMonths {
    if (!_isCurrentAcademicYearSelected) return kMonths;
    return kMonths.where((m) => (m['value'] as int) <= _today.month).toList();
  }

  int _deriveYear(String acadYear, int month) {
    final startYear = int.parse(acadYear.split('-').first);
    return month >= 6 ? startYear : startYear + 1;
  }

  Future<void> _fetchData({int attempt = 0}) async {
    if (attempt == 0) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final classId = _activeClassId;
    final sectionId = _activeSectionId;
    final month = _activeMonth;
    final year = _activeYear;
    final acadYear = _activeAcadYear;
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final records = await repo.getRawRecordsForReport(month: month, year: year, classId: classId, sectionId: sectionId, academicYear: acadYear);
      List<MonthlyReportRowEntity> rows = const [];
      if (classId != null && sectionId != null) {
        try {
          rows = await repo.getMonthlyReport(classId: classId, sectionId: sectionId, month: month, year: year, academicYear: acadYear);
        } catch (_) {
          rows = const [];
        }
      }
      final insights = await repo.getReportInsights(month: month, year: year, classId: classId, sectionId: sectionId, academicYear: acadYear);
      if (!mounted) return;
      setState(() {
        _rawRecords = records;
        _reportRows = rows;
        _insights = insights;
        _loading = false;
      });
    } catch (e) {
      // Matches web's own auto-retry-once-after-1.5s before surfacing the error.
      if (attempt < 1) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        return _fetchData(attempt: attempt + 1);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _generate() {
    final year = _deriveYear(_pendingAcadYear, _pendingMonth);
    setState(() {
      _activeClassId = _pendingClassId;
      _activeSectionId = _pendingClassId != null ? _pendingSectionId : null;
      _activeMonth = _pendingMonth;
      _activeYear = year;
      _activeAcadYear = _pendingAcadYear;
    });
    _fetchData();
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final bytes = await repo.exportAttendance(
        fmt: 'xlsx',
        classId: _activeClassId,
        sectionId: _activeSectionId,
        month: _activeMonth,
        year: _activeYear,
        academicYear: _activeAcadYear,
      );
      final monthName = (kMonths.firstWhere((m) => m['value'] == _activeMonth)['label'] as String);
      final activeClass = _activeClassId != null ? widget.classes.where((c) => c.id == _activeClassId).toList() : const <ClassInfoEntity>[];
      final activeSection = (activeClass.isNotEmpty && _activeSectionId != null) ? activeClass.first.sections.where((s) => s.id == _activeSectionId).toList() : const <SectionSummaryEntity>[];
      final scope = activeClass.isNotEmpty && activeSection.isNotEmpty
          ? '${activeClass.first.displayLabel}_Section_${activeSection.first.name}'
          : activeClass.isNotEmpty
              ? activeClass.first.displayLabel
              : 'All_Classes';
      final filename = 'Attendance_${scope.replaceAll(' ', '_')}_${monthName}_$_activeYear.xlsx';
      await Share.shareXFiles([XFile.fromData(bytes, name: filename, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')]);
    } catch (_) {
      // Matches web exactly: `handleDownload` swallows errors silently.
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String get _monthLabel {
    final label = kMonths.firstWhere((m) => m['value'] == _activeMonth)['label'] as String;
    return '$label $_activeYear';
  }

  String get _reportTitle {
    if (_activeClassId != null) {
      final cls = widget.classes.where((c) => c.id == _activeClassId).toList();
      if (cls.isNotEmpty) {
        if (_activeSectionId != null) {
          final sec = cls.first.sections.where((s) => s.id == _activeSectionId).toList();
          if (sec.isNotEmpty) return '${cls.first.displayLabel} · Section ${sec.first.name}';
        }
        return cls.first.displayLabel;
      }
    }
    return 'All Classes';
  }

  List<_WeekCard> get _weekCards {
    final ranges = _weekRanges(_activeMonth, _activeYear);
    return ranges.map((r) {
      final recs = _rawRecords.where((rec) {
        final d = DateTime.tryParse(rec.attendanceDate);
        return d != null && d.day >= r.start && d.day <= r.end;
      }).toList();
      final present = recs.where((rec) => rec.attendanceType == 'P' || rec.attendanceType == 'L').length;
      final absent = recs.where((rec) => rec.attendanceType == 'A').length;
      final total = recs.length;
      final schoolDays = recs.map((rec) => rec.attendanceDate).toSet().length;
      return _WeekCard(range: r, present: present, absent: absent, total: total, presentPct: total > 0 ? ((present / total) * 100).round() : 0, schoolDays: schoolDays);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6E6EC))),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_headerRow(), Padding(padding: const EdgeInsets.all(20), child: _body())]),
    );
  }

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 12,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 220,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Monthly Attendance Report', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
              Text('$_reportTitle · $_monthLabel', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
            ]),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _labeledSelect('Acad. Year', _pendingAcadYear, _academicYears().map((y) => MapEntry(y, y)).toList(), (v) => setState(() {
                    _pendingAcadYear = v!;
                    // Matches web's own `useEffect` (MonthlyReport.tsx:221-225):
                    // clamp the selected month back into range if switching
                    // academic year makes it invalid (future months of the
                    // current academic year aren't selectable).
                    if (!_availableMonths.any((m) => m['value'] == _pendingMonth)) {
                      _pendingMonth = _availableMonths.isNotEmpty ? _availableMonths.last['value'] as int : _today.month;
                    }
                  })),
              _labeledSelect('Month', _pendingMonth.toString(), _availableMonths.map((m) => MapEntry('${m['value']}', m['label'] as String)).toList(), (v) => setState(() => _pendingMonth = int.parse(v!))),
              _labeledSelect('Class', _pendingClassId?.toString() ?? '', [
                const MapEntry('', 'All Classes'),
                ...widget.classes.map((c) => MapEntry('${c.id}', c.displayLabel)),
              ], (v) {
                setState(() {
                  _pendingClassId = (v == null || v.isEmpty) ? null : int.parse(v);
                  _pendingSectionId = _pendingSections.isNotEmpty ? _pendingSections.first.id : null;
                });
              }),
              _labeledSelect(
                'Section',
                _pendingSectionId?.toString() ?? '',
                [const MapEntry('', 'All Sections'), ..._pendingSections.map((s) => MapEntry('${s.id}', 'Section ${s.name}'))],
                _pendingClassId == null || _pendingSections.isEmpty ? null : (v) => setState(() => _pendingSectionId = (v == null || v.isEmpty) ? null : int.parse(v)),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_forward, size: 12),
                label: Text(_loading ? 'Loading' : 'Generate'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
              OutlinedButton.icon(
                onPressed: (_downloading || _loading) ? null : _download,
                icon: _downloading
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0B14)))
                    : const Icon(Icons.download_outlined, size: 12),
                label: Text(_downloading ? 'Downloading' : 'Download'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0B0B14), side: const BorderSide(color: Color(0xFFE6E6EC)), backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labeledSelect(String label, String value, List<MapEntry<String, String>> items, ValueChanged<String?>? onChanged) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF9CA0AE), letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: onChanged == null ? const Color(0xFFF4F4F8) : Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.any((e) => e.key == value) ? value : null,
                isDense: true,
                isExpanded: true,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onChanged == null ? const Color(0xFF9CA0AE) : const Color(0xFF0B0B14)),
                items: items.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return SizedBox(
        height: 148,
        child: Row(
          children: List.generate(6, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 5 ? 12 : 0),
                  child: Opacity(opacity: 1 - i * 0.12, child: Container(decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(16)))),
                ),
              )),
        ),
      );
    }
    if (_error != null) {
      final lower = _error!.toLowerCase();
      final looksLikeColdStart = lower.contains('503') || lower.contains('502') || lower.contains('unavailable');
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFF0F3), border: Border.all(color: const Color(0xFFFBCFE8)), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Color(0xFFC2264E)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_error!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFC2264E))),
                if (looksLikeColdStart)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('The database may be waking up. Please wait a moment and retry.', style: TextStyle(fontSize: 10, color: Color(0xFFC2264E))),
                  ),
              ]),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _fetchData(),
              icon: const Icon(Icons.refresh, size: 12),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2264E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    final weeks = _weekCards;
    final overallPresent = _rawRecords.where((r) => r.attendanceType == 'P' || r.attendanceType == 'L').length;
    final overallTotal = _rawRecords.length;
    final overallPresentPct = overallTotal > 0 ? ((overallPresent / overallTotal) * 100).round() : 0;
    final weeksWithData = weeks.where((w) => w.total > 0).length;
    final schoolDaysThisMonth = _rawRecords.map((r) => r.attendanceDate).toSet().length;

    final reportPresentTotal = _reportRows.fold<int>(0, (s, r) => s + r.present);
    final reportAbsentTotal = _reportRows.fold<int>(0, (s, r) => s + r.absent);
    final reportLateTotal = _reportRows.fold<int>(0, (s, r) => s + r.late);
    final reportTotal = reportPresentTotal + reportAbsentTotal + reportLateTotal;
    final reportPct = reportTotal > 0 ? ((reportPresentTotal / reportTotal) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final w in weeks) Padding(padding: const EdgeInsets.only(right: 12), child: SizedBox(width: 158, child: _weekCardWidget(w))),
              SizedBox(width: 158, child: _monthlyCardWidget(overallPresentPct, weeksWithData, schoolDaysThisMonth, overallTotal)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final absentCard = _reasonCard('Top Absent Reasons', 'Ranked from attendance notes for the selected period.', _insights.topAbsentReasons, const Color(0xFFC2264E), const Color(0xFFFFF0F3), const Color(0xFFFFF7F9), 'No absent-note insights for the selected filters.', 'Absent note pattern');
          final lateCard = _reasonCard('Top Late Reasons', 'Frequent late-arrival reasons captured during attendance.', _insights.topLateReasons, const Color(0xFFB4721B), const Color(0xFFFFF8ED), const Color(0xFFFFF9F1), 'No late-note insights for the selected filters.', 'Late note pattern');
          if (wide) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: absentCard), const SizedBox(width: 16), Expanded(child: lateCard)]);
          }
          return Column(children: [absentCard, const SizedBox(height: 16), lateCard]);
        }),
        if (_activeClassId != null && _activeSectionId != null && _reportRows.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('STUDENT SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA0AE), letterSpacing: 0.4)),
          const SizedBox(height: 10),
          _studentSummaryTable(reportPresentTotal, reportAbsentTotal, reportLateTotal, reportPct),
        ],
        if (overallTotal == 0) ...[
          const SizedBox(height: 12),
          Center(
            child: Column(children: [
              Container(width: 40, height: 40, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFFF8F6FF), borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: const Icon(Icons.error_outline, size: 20, color: Color(0xFF9CA0AE))),
              Text('No attendance data for $_monthLabel', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF3A3A4A))),
              const SizedBox(height: 4),
              const Text('No records found for the selected filters.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _weekCardWidget(_WeekCard w) {
    final hasData = w.total > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasData ? Colors.white : const Color(0xFFFAFAFD),
        border: Border.all(color: hasData ? const Color(0xFFE6E6EC) : const Color(0xFFF0F0F6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Opacity(
        opacity: hasData ? 1 : 0.5,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(w.range.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
            if (hasData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _pctBg(w.presentPct), borderRadius: BorderRadius.circular(999)),
                child: Text(w.presentPct >= 75 ? 'Good' : w.presentPct >= 50 ? 'Avg' : 'Low', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _pctColor(w.presentPct))),
              ),
          ]),
          Text(w.range.dateRange, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA0AE))),
          const SizedBox(height: 8),
          if (hasData) ...[
            Center(child: DonutRing(pct: w.presentPct, size: 56)),
            const SizedBox(height: 8),
            Text('${w.schoolDays} school ${w.schoolDays == 1 ? 'day' : 'days'}', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA0AE))),
            const SizedBox(height: 3),
            _legendLine(const Color(0xFF0A8C5A), 'Present', '${w.present} ${w.present == 1 ? 'student' : 'students'}', const Color(0xFF0A8C5A)),
            _legendLine(const Color(0xFFC2264E), 'Absent', '${w.absent} ${w.absent == 1 ? 'student' : 'students'}', const Color(0xFFC2264E)),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.error_outline, size: 16, color: Color(0xFFC8C8D4)),
                  SizedBox(height: 4),
                  Text('No data', style: TextStyle(fontSize: 9, color: Color(0xFFC8C8D4))),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _monthlyCardWidget(int overallPresentPct, int weeksWithData, int schoolDays, int overallTotal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8F6FF), Color(0xFFEDE9FE)]),
        border: Border.all(color: const Color(0xFF4729F4), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Monthly', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4729F4))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(999)), child: const Text('Avg', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF4729F4)))),
        ]),
        Text('$weeksWithData wk${weeksWithData != 1 ? 's' : ''} · $schoolDays school ${schoolDays == 1 ? 'day' : 'days'}', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA0AE))),
        const SizedBox(height: 8),
        if (overallTotal > 0) ...[
          Center(child: DonutRing(pct: overallPresentPct, size: 56)),
          const SizedBox(height: 8),
          _legendLine(const Color(0xFF0A8C5A), 'Present', '$overallPresentPct%', const Color(0xFF0A8C5A)),
          _legendLine(const Color(0xFFC2264E), 'Absent', '${(100 - overallPresentPct).round()}%', const Color(0xFFC2264E)),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.error_outline, size: 16, color: Color(0xFFC8C8D4)),
                SizedBox(height: 4),
                Text('No data yet', style: TextStyle(fontSize: 9, color: Color(0xFFC8C8D4))),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _legendLine(Color dot, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6B6B7B)), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: valueColor)),
      ]),
    );
  }

  Widget _reasonCard(String title, String subtitle, List<ReasonCountEntity> reasons, Color color, Color badgeBg, Color rowBg, String emptyText, String patternLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA0AE))),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
              child: Text('${reasons.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ),
          ]),
          const SizedBox(height: 12),
          if (reasons.isEmpty)
            Text(emptyText, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE)))
          else
            ...reasons.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: rowBg, borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.reason, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3A3A4A))),
                      Text('$patternLabel #${index + 1}', style: const TextStyle(fontSize: 9, color: Color(0xFF9CA0AE))),
                    ]),
                  ),
                  Text('${item.count}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ]),
              );
            }),
        ],
      ),
    );
  }

  Widget _studentSummaryTable(int presentTotal, int absentTotal, int lateTotal, int totalPct) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF0F0F6)), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 480),
          child: Column(
            children: [
              Container(
                color: const Color(0xFFFAFAFD),
                child: Row(children: [
                  _headerCell('STUDENT', flex: 2, alignLeft: true),
                  _headerCell('PRESENT'),
                  _headerCell('ABSENT'),
                  _headerCell('LATE'),
                  _headerCell('ATTENDANCE %'),
                ]),
              ),
              for (final row in _reportRows) _studentRow(row),
              Container(
                decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFE6E6EC), width: 2))),
                child: Row(children: [
                  _bodyCell(const Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF3A3A4A))), flex: 2, alignLeft: true),
                  _bodyCell(Text('$presentTotal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0A8C5A)))),
                  _bodyCell(Text('$absentTotal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFC2264E)))),
                  _bodyCell(Text('$lateTotal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB4721B)))),
                  _bodyCell(_pctPill(totalPct)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentRow(MonthlyReportRowEntity row) {
    final total = row.present + row.absent + row.late;
    final pct = total > 0 ? ((row.present / total) * 100).round() : 0;
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
      child: Row(children: [
        _bodyCell(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row.name.isEmpty ? '-' : row.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14)), overflow: TextOverflow.ellipsis),
            if (row.admissionNo.isNotEmpty) Text(row.admissionNo, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA0AE))),
          ]),
          flex: 2,
          alignLeft: true,
        ),
        _bodyCell(Text('${row.present}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A8C5A)))),
        _bodyCell(Text('${row.absent}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC2264E)))),
        _bodyCell(Text('${row.late}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB4721B)))),
        _bodyCell(_pctPill(pct)),
      ]),
    );
  }

  Widget _pctPill(int pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: _pctBg(pct), borderRadius: BorderRadius.circular(999)),
      child: Text('$pct%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _pctColor(pct))),
    );
  }

  Widget _headerCell(String text, {int flex = 1, bool alignLeft = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(text, textAlign: alignLeft ? TextAlign.left : TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA0AE), letterSpacing: 0.4)),
      ),
    );
  }

  Widget _bodyCell(Widget child, {int flex = 1, bool alignLeft = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Align(alignment: alignLeft ? Alignment.centerLeft : Alignment.center, child: child),
      ),
    );
  }
}

class DonutRing extends StatelessWidget {
  final int pct;
  final double size;
  const DonutRing({super.key, required this.pct, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final color = _pctColor(pct);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size(size, size), painter: _DonutPainter(pct: pct, color: color)),
        Text('$pct%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int pct;
  final Color color;
  const _DonutPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFE8E8F0)..style = PaintingStyle.stroke..strokeWidth = stroke);
    final sweep = 2 * math.pi * (pct.clamp(0, 100) / 100);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}
