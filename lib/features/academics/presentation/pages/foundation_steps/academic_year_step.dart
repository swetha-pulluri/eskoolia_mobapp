import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../student/domain/models/academic_year.dart';
import '../../../domain/entities/holiday_entity.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/foundation_widgets.dart';

/// Step 1 — port of AcademicYearPane.tsx + HolidayCalendarCard.tsx.
class AcademicYearStep extends ConsumerStatefulWidget {
  final List<AcademicYear> years;
  final List<Holiday> holidays;
  final Future<void> Function() onRefreshYears;
  final Future<void> Function() onRefreshHolidays;
  final void Function(String message, {bool error}) showToast;
  final VoidCallback onNext;

  const AcademicYearStep({
    super.key,
    required this.years,
    required this.holidays,
    required this.onRefreshYears,
    required this.onRefreshHolidays,
    required this.showToast,
    required this.onNext,
  });

  @override
  ConsumerState<AcademicYearStep> createState() => _AcademicYearStepState();
}

String _fmtDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[1]}/${parts[2]}/${parts[0]}';
}

String _isoOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int _parseTermCount(String val) {
  final m = RegExp(r'^(\d+)').firstMatch(val);
  return m != null ? int.parse(m.group(1)!) : 0;
}

const _termLabels = {
  2: ['Semester 1', 'Semester 2'],
  3: ['Trimester 1', 'Trimester 2', 'Trimester 3'],
  4: ['Quarter 1', 'Quarter 2', 'Quarter 3', 'Quarter 4'],
};

String? _derivedName(String s, String e) {
  if (s.isEmpty || e.isEmpty) return null;
  final sy = DateTime.tryParse(s)?.year;
  final ey = DateTime.tryParse(e)?.year;
  if (sy == null || ey == null) return null;
  return '$sy-$ey';
}

class _AcademicYearStepState extends ConsumerState<AcademicYearStep> {
  String _board = '';
  String _numberOfTerms = '';
  String _startDate = '';
  String _endDate = '';
  bool _isCurrent = false;
  bool _isActive = true;
  List<(String start, String end)> _terms = [];

  int? _editingId;
  bool _saving = false;
  String _error = '';
  String _dateWarning = '';
  int? _deletingId;
  int? _makingId;
  AcademicYear? _pendingDelete;
  final GlobalKey _deleteConfirmKey = GlobalKey();
  final GlobalKey _formKey = GlobalKey();

  void _scrollToDeleteConfirm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _deleteConfirmKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.1);
      }
    });
  }

  void _scrollToForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _formKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.05);
      }
    });
  }

  void _resetForm() {
    setState(() {
      _board = '';
      _numberOfTerms = '';
      _startDate = '';
      _endDate = '';
      _isCurrent = false;
      _isActive = true;
      _terms = [];
      _editingId = null;
      _error = '';
      _dateWarning = '';
    });
  }

  List<(String, String)> _splitTermDates(String startStr, String endStr, int count) {
    if (count <= 0) return [];
    if (startStr.isEmpty || endStr.isEmpty) return List.generate(count, (_) => ('', ''));
    final start = DateTime.tryParse(startStr);
    final end = DateTime.tryParse(endStr);
    if (start == null || end == null || !end.isAfter(start)) return List.generate(count, (_) => ('', ''));
    final totalMs = end.difference(start).inMilliseconds;
    final chunk = totalMs / count;
    return List.generate(count, (i) {
      final s = start.add(Duration(milliseconds: (chunk * i).round()));
      final e = i == count - 1 ? end : start.add(Duration(milliseconds: (chunk * (i + 1)).round() - 86400000));
      return (_isoOf(s), _isoOf(e));
    });
  }

  void _onTermCountChange(String val) {
    final tc = _parseTermCount(val);
    setState(() {
      _numberOfTerms = val;
      _terms = _splitTermDates(_startDate, _endDate, tc);
    });
  }

  void _onMainDateChange({String? start, String? end}) {
    setState(() {
      if (start != null) _startDate = start;
      if (end != null) _endDate = end;
      final tc = _parseTermCount(_numberOfTerms);
      if (tc > 0) _terms = _splitTermDates(_startDate, _endDate, tc);
      _dateWarning = _computeDateWarning(_startDate, _endDate);
    });
  }

  String _computeDateWarning(String start, String end) {
    if (start.isEmpty || end.isEmpty) return '';
    final s = DateTime.tryParse(start);
    final e = DateTime.tryParse(end);
    if (s == null || e == null || !e.isAfter(s)) return '';
    final nineMonths = DateTime(s.year, s.month + 9, s.day);
    if (e.isBefore(nineMonths)) return 'Academic year must be at least 9 months.';
    final others = widget.years.where((y) => y.id != _editingId).toList();
    if (others.isNotEmpty) {
      final latestEnd = others.map((y) => DateTime.tryParse(y.endDate) ?? DateTime(1970)).reduce((a, b) => a.isAfter(b) ? a : b);
      final limit = DateTime(latestEnd.year, latestEnd.month + 3, latestEnd.day);
      if (s.isAfter(limit)) return 'Year should start close to when the previous year ends.';
    }
    return '';
  }

  void _openEdit(AcademicYear y) {
    final tc = _parseTermCount(y.numberOfTerms ?? '');
    setState(() {
      _board = y.board ?? '';
      _numberOfTerms = y.numberOfTerms ?? '';
      _startDate = y.startDate;
      _endDate = y.endDate;
      _isCurrent = y.isCurrent;
      _isActive = y.isActive;
      _terms = tc > 0 ? _splitTermDates(y.startDate, y.endDate, tc) : [];
      _editingId = y.id;
      _error = '';
      _dateWarning = '';
    });
    _scrollToForm();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = DateTime.tryParse(isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2015), lastDate: DateTime(2100));
    if (picked == null) return;
    _onMainDateChange(start: isStart ? _isoOf(picked) : null, end: !isStart ? _isoOf(picked) : null);
  }

  Future<void> _save() async {
    if (_startDate.isEmpty || _endDate.isEmpty) {
      setState(() => _error = 'Both dates are required.');
      return;
    }
    final s = DateTime.parse(_startDate);
    final e = DateTime.parse(_endDate);
    if (!e.isAfter(s)) {
      setState(() => _error = 'End date must be after the start date.');
      widget.showToast('End date must be after the start date.', error: true);
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final repo = ref.read(academicsRepositoryProvider);
      if (_editingId != null) {
        await repo.updateAcademicYear(_editingId!, board: _board.isEmpty ? null : _board, numberOfTerms: _numberOfTerms.isEmpty ? null : _numberOfTerms, startDate: _startDate, endDate: _endDate, isCurrent: _isCurrent, isActive: _isActive);
        widget.showToast('Academic year updated.');
      } else {
        await repo.createAcademicYear(board: _board.isEmpty ? null : _board, numberOfTerms: _numberOfTerms.isEmpty ? null : _numberOfTerms, startDate: _startDate, endDate: _endDate, isCurrent: _isCurrent, isActive: _isActive);
        widget.showToast('Year ${_derivedName(_startDate, _endDate) ?? ''} created.');
      }
      _resetForm();
      await widget.onRefreshYears();
    } catch (err) {
      var msg = err.toString().replaceFirst('Exception: ', '');
      final name = _derivedName(_startDate, _endDate) ?? '';
      if (RegExp(r'overlap', caseSensitive: false).hasMatch(msg)) {
        msg = 'This date range overlaps an existing academic year${name.isNotEmpty ? ' ($name)' : ''}. Pick different dates or edit the existing one.';
      } else if (RegExp(r'already exists|unique', caseSensitive: false).hasMatch(msg)) {
        msg = 'Academic year "$name" already exists. Edit it from the list below instead.';
      }
      setState(() => _error = msg);
      widget.showToast(msg, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final y = _pendingDelete;
    if (y == null) return;
    setState(() => _deletingId = y.id);
    try {
      await ref.read(academicsRepositoryProvider).deleteAcademicYear(y.id);
      widget.showToast('"${y.name}" deleted.');
      setState(() => _pendingDelete = null);
      await widget.onRefreshYears();
    } catch (err) {
      final msg = err.toString();
      if (RegExp(r'\b404\b|not.?found', caseSensitive: false).hasMatch(msg)) {
        widget.showToast('This academic year no longer exists. Refreshing the list…', error: true);
        setState(() => _pendingDelete = null);
        await widget.onRefreshYears();
      } else {
        widget.showToast('Failed to delete.', error: true);
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _makeCurrent(AcademicYear y) async {
    setState(() => _makingId = y.id);
    try {
      await ref.read(academicsRepositoryProvider).updateAcademicYear(y.id, startDate: y.startDate, endDate: y.endDate, isCurrent: true, isActive: y.isActive, board: y.board, numberOfTerms: y.numberOfTerms);
      widget.showToast('"${y.name}" is now the current academic year.');
      await widget.onRefreshYears();
    } catch (_) {
      widget.showToast('Failed to update.', error: true);
    } finally {
      if (mounted) setState(() => _makingId = null);
    }
  }

  bool _isTooFarFromToday(AcademicYear y) {
    final today = DateTime.now();
    final start = DateTime.tryParse(y.startDate) ?? today;
    final end = DateTime.tryParse(y.endDate) ?? today;
    return today.isBefore(DateTime(start.year, start.month, start.day)) || today.isAfter(DateTime(end.year, end.month, end.day));
  }

  @override
  Widget build(BuildContext context) {
    final derivedName = _derivedName(_startDate, _endDate);
    final sortedYears = [...widget.years]..sort((a, b) => (DateTime.tryParse(b.startDate) ?? DateTime(0)).compareTo(DateTime.tryParse(a.startDate) ?? DateTime(0)));

    return Stack(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _buildFormCard(derivedName, sortedYears);
          final holidays = _HolidayCalendarCard(years: widget.years, holidays: widget.holidays, onRefresh: widget.onRefreshHolidays, showToast: widget.showToast);
          if (wide) {
            return IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: form),
                const SizedBox(width: 16),
                Expanded(child: holidays),
              ]),
            );
          }
          return Column(children: [form, const SizedBox(height: 10), holidays]);
        }),
        if (_pendingDelete != null)
          FoundationConfirmDeleteDialog(
            key: _deleteConfirmKey,
            title: 'Delete Academic Year',
            message: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(text: '"${_pendingDelete!.name}"', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: '? All holidays and related data linked to this year will also be removed.'),
            ])),
            loading: _deletingId == _pendingDelete!.id,
            onConfirm: _confirmDelete,
            onCancel: () => setState(() => _pendingDelete = null),
          ),
      ],
    );
  }

  Widget _buildFormCard(String? derivedName, List<AcademicYear> sortedYears) {
    final termCount = _parseTermCount(_numberOfTerms);
    final today = DateTime.now();

    return FoundationCard(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: _editingId != null ? 'Edit Academic Year' : 'New Academic Year', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
            if (derivedName != null && _editingId == null) TextSpan(text: '  → $derivedName', style: const TextStyle(color: Color(0xFF5B4FCF), fontWeight: FontWeight.w600, fontSize: 13)),
          ])),
          const SizedBox(height: 2),
          Text(_editingId != null ? 'Update the year dates or current status' : 'Define the start and end dates for the school year', style: const TextStyle(fontSize: 11, color: Color(0xFF6F767E))),
          const SizedBox(height: 10),
          foundationFieldLabel('Board / Curriculum'),
          DropdownButtonFormField<String>(
            initialValue: _board.isEmpty ? null : _board,
            isExpanded: true,
            decoration: foundationFieldDecoration(hint: 'Select...'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D1F)),
            items: const ['CBSE', 'ICSE', 'State Board', 'IB', 'IGCSE', 'NIOS', 'Other']
                .map((b) => DropdownMenuItem(value: b, child: Text(b == 'IB' ? 'IB (International Baccalaureate)' : (b == 'IGCSE' ? 'IGCSE (Cambridge)' : b), overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _board = v ?? ''),
          ),
          const SizedBox(height: 8),
          foundationFieldLabel('Number of Terms'),
          DropdownButtonFormField<String>(
            initialValue: _numberOfTerms.isEmpty ? null : _numberOfTerms,
            isExpanded: true,
            decoration: foundationFieldDecoration(hint: 'Select...'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D1F)),
            items: const ['2 Terms (Semester)', '3 Terms (Trimester)', '4 Terms (Quarter)'].map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => _onTermCountChange(v ?? ''),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                foundationFieldLabel('Start Date', required: true),
                _dateField(_startDate, onTap: () => _pickDate(isStart: true)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                foundationFieldLabel('End Date', required: true),
                _dateField(_endDate, onTap: () => _pickDate(isStart: false)),
              ]),
            ),
          ]),
          if (termCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8ECEF)), borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(color: Color(0xFFF5F3FF), border: Border(bottom: BorderSide(color: Color(0xFFE8ECEF)))),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF5B4FCF)),
                      const SizedBox(width: 8),
                      const Text('FOUNDATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF5B4FCF))),
                      const Spacer(),
                      const Text('Auto-populated · editable', style: TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
                    ]),
                  ),
                  for (var i = 0; i < termCount; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(border: i < termCount - 1 ? const Border(bottom: BorderSide(color: Color(0xFFE8ECEF))) : null),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: 'Term ${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                            TextSpan(text: '  — ${(_termLabels[termCount] ?? List.generate(termCount, (j) => 'Term ${j + 1}'))[i]}', style: const TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
                          ])),
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(
                              child: _dateField(
                                _terms.length > i ? _terms[i].$1 : '',
                                small: true,
                                onTap: () async {
                                  final initial = DateTime.tryParse(_terms.length > i ? _terms[i].$1 : '') ?? DateTime.now();
                                  final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2015), lastDate: DateTime(2100));
                                  if (picked == null) return;
                                  setState(() {
                                    final list = [..._terms];
                                    list[i] = (_isoOf(picked), list[i].$2);
                                    _terms = list;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _dateField(
                                _terms.length > i ? _terms[i].$2 : '',
                                small: true,
                                onTap: () async {
                                  final initial = DateTime.tryParse(_terms.length > i ? _terms[i].$2 : '') ?? DateTime.now();
                                  final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2015), lastDate: DateTime(2100));
                                  if (picked == null) return;
                                  setState(() {
                                    final list = [..._terms];
                                    list[i] = (list[i].$1, _isoOf(picked));
                                    _terms = list;
                                  });
                                },
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (_dateWarning.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), border: Border.all(color: const Color(0xFFFCD34D)), borderRadius: BorderRadius.circular(10)),
              child: Text('⚠ $_dateWarning', style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
            ),
          InkWell(
            onTap: () => setState(() => _isCurrent = !_isCurrent),
            child: Row(children: [
              Checkbox(value: _isCurrent, onChanged: (v) => setState(() => _isCurrent = v ?? false), activeColor: const Color(0xFF5B4FCF), visualDensity: VisualDensity.compact),
              const Flexible(child: Text('Set as current academic year', style: TextStyle(fontSize: 13, color: Color(0xFF6F767E)))),
            ]),
          ),
          if (_editingId != null)
            InkWell(
              onTap: () => setState(() => _isActive = !_isActive),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Checkbox(value: _isActive, onChanged: (v) => setState(() => _isActive = v ?? true), activeColor: const Color(0xFF5B4FCF), visualDensity: VisualDensity.compact),
                const Flexible(child: Text('Active (uncheck to soft-deactivate this year)', style: TextStyle(fontSize: 13, color: Color(0xFF6F767E)))),
              ]),
            ),
          if (_error.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), border: Border.all(color: const Color(0xFFFCA5A5)), borderRadius: BorderRadius.circular(10)),
              child: Text(_error, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
            ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
              child: Text(_saving ? 'Saving…' : (_editingId != null ? 'Update Year' : 'Save Year'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            if (_editingId != null)
              OutlinedButton(
                onPressed: _resetForm,
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            OutlinedButton(
              onPressed: widget.onNext,
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
              child: const Text('Next: Classes →', style: TextStyle(fontSize: 13)),
            ),
          ]),
          if (widget.years.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE8ECEF)),
            const SizedBox(height: 10),
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'ACADEMIC YEARS ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF6F767E))),
              TextSpan(text: '(${widget.years.length})', style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD), fontWeight: FontWeight.normal)),
            ])),
            const SizedBox(height: 6),
            for (final y in sortedYears) _yearRow(y, today),
          ],
        ],
      ),
    );
  }

  Widget _dateField(String value, {required VoidCallback onTap, bool small = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(small ? 8 : 10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 4 : 6),
        decoration: BoxDecoration(color: small ? const Color(0xFFFAFBFC) : const Color(0xFFF0F2F5), border: Border.all(color: const Color(0xFFE8ECEF), width: 1.5), borderRadius: BorderRadius.circular(small ? 8 : 10)),
        child: Row(children: [
          Expanded(
            child: Text(
              value.isEmpty ? 'mm/dd/yyyy' : _fmtDate(value),
              style: TextStyle(fontSize: small ? 11 : 13, color: value.isEmpty ? const Color(0xFF9FA6AD) : const Color(0xFF1A1D1F)),
            ),
          ),
          SizedBox(width: small ? 6 : 8),
          Icon(Icons.calendar_today_outlined, size: small ? 12 : 14, color: const Color(0xFF9FA6AD)),
        ]),
      ),
    );
  }

  Widget _yearRow(AcademicYear y, DateTime today) {
    final endDate = DateTime.tryParse(y.endDate) ?? today;
    final isArchived = !y.isCurrent && endDate.isBefore(DateTime(today.year, today.month, today.day));
    final isInactive = !y.isActive;
    final tooFar = _isTooFarFromToday(y);
    final (border, bg) = isInactive
        ? (const Color(0xFFE8ECEF), const Color(0xFFFFF8F8))
        : y.isCurrent
            ? (const Color(0xFF5B4FCF), const Color(0xFFF5F3FF))
            : isArchived
                ? (const Color(0xFFE8ECEF), const Color(0xFFFAFBFC))
                : (const Color(0xFFE8ECEF), const Color(0xFFF0F2F5));
    final dotColor = isInactive ? const Color(0xFFFCA5A5) : (y.isCurrent ? const Color(0xFF22C55E) : (isArchived ? const Color(0xFFD2D7DC) : const Color(0xFF9FA6AD)));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 1.5), borderRadius: BorderRadius.circular(12)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                  Text(y.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isInactive ? const Color(0xFF9FA6AD) : (y.isCurrent ? const Color(0xFF5B4FCF) : const Color(0xFF1A1D1F)), decoration: isInactive ? TextDecoration.lineThrough : null)),
                  if (isInactive) _badge('Inactive', const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
                  if (y.isCurrent) _badge('✓ CURRENT', const Color(0xFF5B4FCF), Colors.white),
                  if (isArchived) _badge('Archived', const Color(0xFFF0F2F5), const Color(0xFF9FA6AD)),
                ]),
                Text('${y.startDate} → ${y.endDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
              ],
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (y.isCurrent)
              const Text('Current Year', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5B4FCF)))
            else if (isInactive)
              const Text('—', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD)))
            else if (tooFar)
              const Text('—', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD)))
            else
              TextButton(
                onPressed: _makingId == y.id ? null : () => _makeCurrent(y),
                style: TextButton.styleFrom(backgroundColor: const Color(0xFFEEF0FF), foregroundColor: const Color(0xFF5B4FCF), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(_makingId == y.id ? '…' : 'Make Current', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            IconButton(onPressed: () => _openEdit(y), icon: const Icon(Icons.edit_outlined, size: 15), color: const Color(0xFF9FA6AD), tooltip: 'Edit year', visualDensity: VisualDensity.compact),
            IconButton(
              onPressed: _deletingId == y.id
                  ? null
                  : () {
                      setState(() => _pendingDelete = y);
                      _scrollToDeleteConfirm();
                    },
              icon: _deletingId == y.id ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete_outline, size: 15),
              color: const Color(0xFF9FA6AD),
              tooltip: 'Delete year',
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      );
}

class _HolidayCalendarCard extends ConsumerStatefulWidget {
  final List<AcademicYear> years;
  final List<Holiday> holidays;
  final Future<void> Function() onRefresh;
  final void Function(String message, {bool error}) showToast;
  const _HolidayCalendarCard({required this.years, required this.holidays, required this.onRefresh, required this.showToast});

  @override
  ConsumerState<_HolidayCalendarCard> createState() => _HolidayCalendarCardState();
}

class _HolidayCalendarCardState extends ConsumerState<_HolidayCalendarCard> {
  int? _yearId;

  List<AcademicYear> get _sortedYears => [...widget.years]..sort((a, b) => b.startDate.compareTo(a.startDate));

  AcademicYear? get _selectedYear {
    final id = _yearId ?? widget.years.where((y) => y.isCurrent).firstOrNull?.id ?? _sortedYears.firstOrNull?.id;
    return widget.years.where((y) => y.id == id).firstOrNull;
  }

  List<Holiday> get _items {
    final id = _selectedYear?.id;
    return widget.holidays.where((h) => id == null || h.academicYearId == id).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _openAddEdit({Holiday? editing}) async {
    final result = await showDialog<_HolidayFormResult>(
      context: context,
      builder: (_) => _HolidayFormDialog(editing: editing, yearName: _selectedYear?.name),
    );
    if (result == null) return;
    final repo = ref.read(academicsRepositoryProvider);
    try {
      if (editing != null) {
        await repo.updateHoliday(editing.id, name: result.name, date: result.date, endDate: result.endDate, holidayType: result.type, description: result.description, academicYearId: _selectedYear?.id);
        widget.showToast('Holiday updated.');
      } else {
        await repo.createHoliday(name: result.name, date: result.date, endDate: result.endDate, holidayType: result.type, description: result.description, academicYearId: _selectedYear?.id);
        widget.showToast('Holiday added.');
      }
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _remove(Holiday h) async {
    try {
      await ref.read(academicsRepositoryProvider).deleteHoliday(h.id);
      widget.showToast('Holiday deleted.');
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _openCopy() async {
    final yearId = _selectedYear?.id;
    if (yearId == null) return;
    final result = await showDialog<({int sourceId, bool shift})>(
      context: context,
      builder: (_) => _CopyHolidaysDialog(years: _sortedYears, targetId: yearId, targetName: _selectedYear!.name),
    );
    if (result == null) return;
    try {
      final res = await ref.read(academicsRepositoryProvider).copyHolidaysFromYear(sourceYearId: result.sourceId, targetYearId: yearId, shiftYear: result.shift);
      widget.showToast('Copied ${res.created} holiday${res.created == 1 ? '' : 's'}${res.skipped > 0 ? ', skipped ${res.skipped}' : ''}.');
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = _sortedYears;
    final selected = _selectedYear;
    final items = _items;

    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Flexible(child: Text('Holiday Calendar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)), overflow: TextOverflow.ellipsis)),
                if (selected != null) ...[const SizedBox(width: 8), Flexible(child: Text(selected.name, style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD)), overflow: TextOverflow.ellipsis))],
              ]),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (years.length > 1)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selected?.id,
                      isDense: true,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1A1D1F)),
                      items: years.map((y) => DropdownMenuItem(value: y.id, child: Text('${y.name}${y.isCurrent ? ' ✓' : ''}'))).toList(),
                      onChanged: (v) => setState(() => _yearId = v),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: (selected == null || years.length < 2) ? null : _openCopy,
                  icon: const Icon(Icons.copy_outlined, size: 12),
                  label: const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF5B4FCF), side: const BorderSide(color: Color(0xFFE8ECEF)), minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                ),
                ElevatedButton.icon(
                  onPressed: selected == null ? null : () => _openAddEdit(),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Holiday', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8ECEF)), borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: const Color(0xFFF0F2F5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Row(children: [
                    SizedBox(width: 90, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6F767E)))),
                    Expanded(child: Text('EVENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6F767E)))),
                    SizedBox(width: 80, child: Text('TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6F767E)))),
                    SizedBox(width: 60, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6F767E)))),
                  ]),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(children: [
                      const Text('No holidays yet.', style: TextStyle(fontSize: 12, color: Color(0xFF6F767E))),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: selected == null ? null : () => _openAddEdit(),
                        child: const Text('+ Add your first holiday', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B4FCF))),
                      ),
                    ]),
                  )
                else
                  for (final h in items) _holidayRow(h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _holidayRow(Holiday h) {
    final badge = switch (h.holidayType) {
      'national' => (const Color(0xFFDCFCE7), const Color(0xFF15803D), 'National'),
      'religious' => (const Color(0xFFFEF3C7), const Color(0xFFB45309), 'Religious'),
      'public' => (const Color(0xFFEDE9FE), const Color(0xFF5B4FCF), 'Public'),
      'school' => (const Color(0xFFF3E8FF), const Color(0xFF7C3AED), 'School Event'),
      _ => (const Color(0xFFF3F4F6), const Color(0xFF6F767E), 'Other'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE8ECEF)))),
      child: Opacity(
        opacity: h.activeStatus ? 1 : 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(h.endDate != null && h.endDate != h.date ? '${h.date} – ${h.endDate}' : h.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1A1D1F)))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(h.name, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D1F))),
                  if (h.description.isNotEmpty) Text(h.description, style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: badge.$1, borderRadius: BorderRadius.circular(999)),
                child: Text(badge.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badge.$2)),
              ),
            ),
            SizedBox(
              width: 60,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                InkWell(onTap: () => _openAddEdit(editing: h), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 14, color: Color(0xFF9FA6AD)))),
                InkWell(onTap: () => _remove(h), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 14, color: Color(0xFF9FA6AD)))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayFormResult {
  final String name, date, type, description;
  final String? endDate;
  const _HolidayFormResult({required this.name, required this.date, this.endDate, required this.type, required this.description});
}

class _HolidayFormDialog extends StatefulWidget {
  final Holiday? editing;
  final String? yearName;
  const _HolidayFormDialog({this.editing, this.yearName});

  @override
  State<_HolidayFormDialog> createState() => _HolidayFormDialogState();
}

class _HolidayFormDialogState extends State<_HolidayFormDialog> {
  late final _nameController = TextEditingController(text: widget.editing?.name ?? '');
  late final _descController = TextEditingController(text: widget.editing?.description ?? '');
  late String _date = widget.editing?.date ?? '';
  late String _endDate = widget.editing?.endDate ?? '';
  late String _type = widget.editing?.holidayType ?? 'public';
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isStart}) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(isStart ? _date : _endDate) ?? DateTime.now(), firstDate: DateTime(2015), lastDate: DateTime(2100));
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _date = _isoOf(picked);
      } else {
        _endDate = _isoOf(picked);
      }
    });
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Holiday name is required.');
      return;
    }
    if (_date.isEmpty) {
      setState(() => _error = 'Date is required.');
      return;
    }
    if (_endDate.isNotEmpty && _endDate.compareTo(_date) < 0) {
      setState(() => _error = 'End date cannot be before start date.');
      return;
    }
    Navigator.of(context).pop(_HolidayFormResult(name: _nameController.text.trim(), date: _date, endDate: _endDate.isEmpty ? null : _endDate, type: _type, description: _descController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE8ECEF)))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(widget.editing != null ? 'Edit Holiday' : 'Add Holiday', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
                if (widget.yearName != null) Text('For Academic Year ${widget.yearName}', style: const TextStyle(fontSize: 11, color: Color(0xFF6F767E))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                    ),
                  foundationFieldLabel('Holiday Name', required: true),
                  TextField(controller: _nameController, decoration: foundationFieldDecoration(hint: 'e.g., Diwali')),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        foundationFieldLabel('Date', required: true),
                        InkWell(onTap: () => _pick(isStart: true), child: InputDecorator(decoration: foundationFieldDecoration(), child: Text(_date.isEmpty ? 'Select date' : _date, style: const TextStyle(fontSize: 13)))),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        foundationFieldLabel('End Date'),
                        InkWell(onTap: () => _pick(isStart: false), child: InputDecorator(decoration: foundationFieldDecoration(), child: Text(_endDate.isEmpty ? '—' : _endDate, style: const TextStyle(fontSize: 13)))),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  foundationFieldLabel('Type'),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: foundationFieldDecoration(),
                    items: holidayTypeOptions.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _type = v ?? 'public'),
                  ),
                  const SizedBox(height: 6),
                  foundationFieldLabel('Description'),
                  TextField(controller: _descController, maxLines: 2, decoration: foundationFieldDecoration(hint: 'Optional')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE8ECEF)))),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(widget.editing != null ? 'Update Holiday' : 'Add Holiday'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyHolidaysDialog extends StatefulWidget {
  final List<AcademicYear> years;
  final int targetId;
  final String targetName;
  const _CopyHolidaysDialog({required this.years, required this.targetId, required this.targetName});

  @override
  State<_CopyHolidaysDialog> createState() => _CopyHolidaysDialogState();
}

class _CopyHolidaysDialogState extends State<_CopyHolidaysDialog> {
  int? _sourceId;
  bool _shift = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sourceId = widget.years.where((y) => y.id != widget.targetId).firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.years.where((y) => y.id != widget.targetId).toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE8ECEF)))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('Copy Holidays From Another Year', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
                Text('Target: Academic Year ${widget.targetName}', style: const TextStyle(fontSize: 11, color: Color(0xFF6F767E))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)))),
                  foundationFieldLabel('Source Academic Year', required: true),
                  DropdownButtonFormField<int>(
                    initialValue: _sourceId,
                    isExpanded: true,
                    decoration: foundationFieldDecoration(hint: '— Select year —'),
                    items: options.map((y) => DropdownMenuItem(value: y.id, child: Text('${y.name}${y.isCurrent ? ' (current)' : ''}', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _sourceId = v),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => setState(() => _shift = !_shift),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Checkbox(value: _shift, onChanged: (v) => setState(() => _shift = v ?? true), activeColor: const Color(0xFF5B4FCF), visualDensity: VisualDensity.compact),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text('Shift dates to target year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                            Text("Re-base each holiday's date so it falls in the target academic year.", style: TextStyle(fontSize: 11, color: Color(0xFF6F767E))),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE8ECEF)))),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_sourceId == null) {
                      setState(() => _error = 'Select a source academic year.');
                      return;
                    }
                    Navigator.of(context).pop((sourceId: _sourceId!, shift: _shift));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Copy Holidays'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
