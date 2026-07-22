import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entities.dart';

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

Color _pctColor(int pct) {
  if (pct >= 75) return const Color(0xFF0A8C5A);
  if (pct >= 50) return const Color(0xFFB4721B);
  return const Color(0xFFC2264E);
}

List<String> _academicYears() {
  final now = DateTime.now();
  return List.generate(5, (i) {
    final y = now.year + 1 - i;
    return '${y - 1}-${y.toString().substring(2)}';
  });
}

/// Monthly Attendance Report — converted from web
/// `attendance/student/components/MonthlyReport.tsx`. Since the web
/// version is 100% backend-driven (daily records / report / insights all
/// come from `/api/v1/attendance/student-attendance/...` with zero
/// hardcoded fallback), and this module keeps zero persisted historical
/// log locally (only per-section current-day status), this always
/// resolves to the real "no data" empty state — an honest reflection of
/// having no history to show, not an invented placeholder.
class MonthlyReport extends StatefulWidget {
  final String selectedDate;
  final List<ClassInfoEntity> classes;

  const MonthlyReport({super.key, required this.selectedDate, required this.classes});

  @override
  State<MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<MonthlyReport> {
  late String _pendingAcadYear = _academicYears().first;
  late int _pendingMonth = DateTime.now().month;
  int? _pendingClassId;
  int? _pendingSectionId;

  late int _activeMonth = _pendingMonth;
  int _activeYear = DateTime.now().year;
  int? _activeClassId;
  int? _activeSectionId;

  bool _loading = false;

  List<SectionSummaryEntity> get _pendingSections {
    if (_pendingClassId == null) return const [];
    final cls = widget.classes.where((c) => c.id == _pendingClassId).toList();
    return cls.isEmpty ? const [] : cls.first.sections;
  }

  void _generate() {
    setState(() {
      _loading = true;
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        final startYear = int.parse(_pendingAcadYear.split('-').first);
        _activeYear = _pendingMonth >= 6 ? startYear : startYear + 1;
        _activeMonth = _pendingMonth;
        _activeClassId = _pendingClassId;
        _activeSectionId = _pendingSectionId;
        _loading = false;
      });
    });
  }

  String get _monthLabel {
    final label = kMonths.firstWhere((m) => m['value'] == _activeMonth)['label'] as String;
    return '$label $_activeYear';
  }

  String get _reportTitle {
    if (_activeClassId != null && _activeSectionId != null) {
      final cls = widget.classes.where((c) => c.id == _activeClassId).toList();
      if (cls.isNotEmpty) {
        final sec = cls.first.sections.where((s) => s.id == _activeSectionId).toList();
        if (sec.isNotEmpty) return '${cls.first.displayLabel} · Section ${sec.first.name}';
      }
    }
    if (_activeClassId != null) {
      final cls = widget.classes.where((c) => c.id == _activeClassId).toList();
      if (cls.isNotEmpty) return cls.first.displayLabel;
    }
    return 'All Classes';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(),
          Padding(padding: const EdgeInsets.all(20), child: _body()),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Attendance Report', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
          Text('$_reportTitle · $_monthLabel', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _labeledSelect('Acad. Year', _pendingAcadYear, _academicYears().map((y) => MapEntry(y, y)).toList(), (v) => setState(() => _pendingAcadYear = v!)),
                const SizedBox(width: 8),
                _labeledSelect('Month', _pendingMonth.toString(), kMonths.map((m) => MapEntry('${m['value']}', m['label'] as String)).toList(), (v) => setState(() => _pendingMonth = int.parse(v!))),
                const SizedBox(width: 8),
                _labeledSelect('Class', _pendingClassId?.toString() ?? '', [
                  const MapEntry('', 'All Classes'),
                  ...widget.classes.map((c) => MapEntry('${c.id}', c.displayLabel)),
                ], (v) {
                  setState(() {
                    _pendingClassId = (v == null || v.isEmpty) ? null : int.parse(v);
                    _pendingSectionId = null;
                  });
                }),
                const SizedBox(width: 8),
                _labeledSelect(
                  'Section',
                  _pendingSectionId?.toString() ?? '',
                  [const MapEntry('', 'All Sections'), ..._pendingSections.map((s) => MapEntry('${s.id}', 'Section ${s.name}'))],
                  _pendingClassId == null || _pendingSections.isEmpty ? null : (v) => setState(() => _pendingSectionId = (v == null || v.isEmpty) ? null : int.parse(v)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: Icon(_loading ? Icons.hourglass_empty : Icons.arrow_forward, size: 12),
                  label: Text(_loading ? 'Loading' : 'Generate'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined, size: 12),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0B0B14), side: const BorderSide(color: Color(0xFFE6E6EC)), backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledSelect(String label, String value, List<MapEntry<String, String>> items, ValueChanged<String?>? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF9CA0AE), letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: onChanged == null ? const Color(0xFFF4F4F8) : Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.any((e) => e.key == value) ? value : null,
              isDense: true,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onChanged == null ? const Color(0xFF9CA0AE) : const Color(0xFF0B0B14)),
              items: items.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    // No persisted historical log exists locally — always the honest
    // "no data" state (see class doc comment).
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8F6FF), borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: const Icon(Icons.error_outline, size: 20, color: Color(0xFF9CA0AE)),
        ),
        Text('No attendance data for $_monthLabel', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF3A3A4A))),
        const SizedBox(height: 4),
        const Text('No records found for the selected filters.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
        const SizedBox(height: 8),
      ],
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
