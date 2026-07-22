import 'package:flutter/material.dart';
import '../../../domain/entities/attendance_entities.dart';

/// Export Options result — converted from web's `ExportOptions` type.
class ExportOptions {
  /// 'day' | 'month' | 'range'
  final String scope;
  final String date;
  final String? dateFrom;
  final String? dateTo;
  final String month;
  final String classId;
  final String sectionId;

  const ExportOptions({required this.scope, required this.date, this.dateFrom, this.dateTo, required this.month, required this.classId, required this.sectionId});
}

/// Export Options Dialog — converted from web
/// `attendance/student/components/ExportOptionsDialog.tsx`'s imperative
/// `ExportOptionsDialogHost` + `exportOptionsDialog()` pattern (see
/// `confirm_dialog.dart` for why a separate host isn't needed in Flutter).
Future<ExportOptions?> exportOptionsDialog(
  BuildContext context, {
  required String defaultDate,
  required List<ClassInfoEntity> classes,
  String? initialClassId,
  String? initialSectionId,
}) {
  return showDialog<ExportOptions>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (context) => _ExportOptionsDialogView(defaultDate: defaultDate, classes: classes, initialClassId: initialClassId, initialSectionId: initialSectionId),
  );
}

class _ExportOptionsDialogView extends StatefulWidget {
  final String defaultDate;
  final List<ClassInfoEntity> classes;
  final String? initialClassId;
  final String? initialSectionId;

  const _ExportOptionsDialogView({required this.defaultDate, required this.classes, this.initialClassId, this.initialSectionId});

  @override
  State<_ExportOptionsDialogView> createState() => _ExportOptionsDialogViewState();
}

class _ExportOptionsDialogViewState extends State<_ExportOptionsDialogView> {
  String _scope = 'month';
  late String _date = widget.defaultDate;
  late String _month = widget.defaultDate.substring(0, 7);
  late String _dateFrom = widget.defaultDate;
  late String _dateTo = widget.defaultDate;
  late String _classId = widget.initialClassId ?? 'all';
  late String _sectionId = widget.initialSectionId ?? 'all';

  List<SectionSummaryEntity> get _sections {
    if (_classId == 'all') return const [];
    final cls = widget.classes.where((c) => '${c.id}' == _classId).toList();
    return cls.isEmpty ? const [] : cls.first.sections;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Export Attendance Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
              const SizedBox(height: 4),
              const Text('Choose the date range and filter for the Excel report.', style: TextStyle(fontSize: 12, color: Color(0xFF6B6B7A))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DATE RANGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), letterSpacing: 0.4)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _scopeButton('Single Day', 'day')),
                const SizedBox(width: 8),
                Expanded(child: _scopeButton('Whole Month', 'month')),
                const SizedBox(width: 8),
                Expanded(child: _scopeButton('Custom Range', 'range')),
              ]),
              const SizedBox(height: 14),
              if (_scope == 'day') _dateField('Date', _date, (v) => setState(() => _date = v)),
              if (_scope == 'month') _monthField(),
              if (_scope == 'range')
                Row(children: [
                  Expanded(child: _dateField('From', _dateFrom, (v) => setState(() => _dateFrom = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _dateField('To', _dateTo, (v) => setState(() => _dateTo = v))),
                ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _labeled('Class', _classSelect())),
                const SizedBox(width: 12),
                Expanded(child: _labeled('Section', _sectionSelect())),
              ]),
            ]),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(ExportOptions(scope: _scope, date: _date, dateFrom: _scope == 'range' ? _dateFrom : null, dateTo: _scope == 'range' ? _dateTo : null, month: _month, classId: _classId, sectionId: _sectionId)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white),
                child: const Text('Download Excel'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _scopeButton(String label, String value) {
    final isActive = _scope == value;
    return OutlinedButton(
      onPressed: () => setState(() => _scope = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF4729F4) : Colors.white,
        foregroundColor: isActive ? Colors.white : const Color(0xFF3A3A4A),
        side: BorderSide(color: isActive ? const Color(0xFF4729F4) : const Color(0xFFE6E6EC)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  Widget _labeled(String label, Widget field) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), letterSpacing: 0.4)),
      const SizedBox(height: 6),
      field,
    ]);
  }

  Widget _dateField(String label, String value, ValueChanged<String> onChanged) {
    return _labeled(
      label,
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(value) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
          if (picked != null) onChanged('${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        },
        child: InputDecorator(
          decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE6E6EC)))),
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  Widget _monthField() {
    return _labeled(
      'Month',
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse('$_month-01') ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
          if (picked != null) setState(() => _month = '${picked.year}-${picked.month.toString().padLeft(2, '0')}');
        },
        child: InputDecorator(
          decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE6E6EC)))),
          child: Text(_month, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  Widget _classSelect() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _classId,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0B0B14)),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Classes')),
            ...widget.classes.map((c) => DropdownMenuItem(value: '${c.id}', child: Text(c.displayLabel))),
          ],
          onChanged: (v) => setState(() {
            _classId = v ?? 'all';
            _sectionId = 'all';
          }),
        ),
      ),
    );
  }

  Widget _sectionSelect() {
    final disabled = _classId == 'all' || _sections.isEmpty;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: disabled ? const Color(0xFFF4F4F8) : Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sectionId,
          isDense: true,
          isExpanded: true,
          style: TextStyle(fontSize: 13, color: disabled ? const Color(0xFF9CA0AE) : const Color(0xFF0B0B14)),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Sections')),
            ..._sections.map((s) => DropdownMenuItem(value: '${s.id}', child: Text('Section ${s.name}'))),
          ],
          onChanged: disabled ? null : (v) => setState(() => _sectionId = v ?? 'all'),
        ),
      ),
    );
  }
}
