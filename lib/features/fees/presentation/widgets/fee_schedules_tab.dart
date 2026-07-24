import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../student/domain/models/academic_year.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fee_schedule.dart';
import '../../domain/models/fee_type.dart';
import '../../domain/models/term_settings.dart';
import '../../domain/repositories/fees_config_repository.dart';
import '../providers/fees_config_providers.dart';
import '../utils/fees_format.dart';
import 'fee_config_styles.dart';

const _kFeeStructureOptions = ['Monthly', 'Term-wise', 'Quarterly', 'Half-Yearly', 'Yearly', 'Custom / One-time'];
const _kEditFrequencyOptions = ['Term-wise', 'Monthly', 'Quarterly', 'Half-Yearly', 'Yearly', 'One-Time', 'Custom'];
const _kBreakdownFrequencies = {'Term-wise', 'Quarterly', 'Half-Yearly', 'Custom', 'Monthly'};

String _fmtDateShort(String iso) {
  if (iso.isEmpty) return '';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

class _TermConfig {
  String name;
  String startDate;
  String endDate;
  String dueDate;
  _TermConfig({required this.name, required this.startDate, required this.endDate, required this.dueDate});
  _TermConfig copy() => _TermConfig(name: name, startDate: startDate, endDate: endDate, dueDate: dueDate);
}

final _defaultTerms = [
  _TermConfig(name: 'Term 1 (Apr–Jul)', startDate: '2026-04-01', endDate: '2026-07-31', dueDate: '2026-04-10'),
  _TermConfig(name: 'Term 2 (Aug–Nov)', startDate: '2026-08-01', endDate: '2026-11-30', dueDate: '2026-08-10'),
  _TermConfig(name: 'Term 3 (Dec–Mar)', startDate: '2026-12-01', endDate: '2027-03-31', dueDate: '2026-12-10'),
  _TermConfig(name: 'Term 4', startDate: '2027-04-01', endDate: '2027-05-31', dueDate: '2027-04-10'),
];

List<_TermConfig> _generateDefaultTerms(AcademicYear? year, int count) {
  final startStr = (year?.startDate.isNotEmpty ?? false) ? year!.startDate : '2026-06-12';
  final endStr = (year?.endDate.isNotEmpty ?? false) ? year!.endDate : '2027-03-14';
  final start = DateTime.parse(startStr);
  final end = DateTime.parse(endStr);
  final totalMicros = end.difference(start).inMicroseconds;
  final termMicros = totalMicros / count;
  final result = <_TermConfig>[];
  for (var i = 0; i < count; i++) {
    final tStart = start.add(Duration(microseconds: (termMicros * i).round()));
    final tEnd = start.add(Duration(microseconds: (termMicros * (i + 1)).round())).subtract(const Duration(days: 1));
    final tDue = tStart.add(const Duration(days: 20));
    final finalDue = tDue.isBefore(tEnd) ? tDue : tEnd;
    result.add(_TermConfig(
      name: 'Term ${i + 1}',
      startDate: DateFormat('yyyy-MM-dd').format(tStart),
      endDate: DateFormat('yyyy-MM-dd').format(tEnd),
      dueDate: DateFormat('yyyy-MM-dd').format(finalDue),
    ));
  }
  return result;
}

List<TermBreakdownSlot> _generateMonthlySlots(AcademicYear? year) {
  if (year == null || year.startDate.isEmpty || year.endDate.isEmpty) return [];
  final start = DateTime.parse(year.startDate);
  final end = DateTime.parse(year.endDate);
  var current = DateTime(start.year, start.month, 1);
  final endLimit = DateTime(end.year, end.month, 1);
  final slots = <TermBreakdownSlot>[];
  var count = 1;
  while (!current.isAfter(endLimit) && count <= 12) {
    slots.add(TermBreakdownSlot(
      termNumber: count,
      termName: DateFormat('MMMM yyyy').format(current),
      amount: '',
      dueDate: DateFormat('yyyy-MM-dd').format(DateTime(current.year, current.month, 10)),
    ));
    current = DateTime(current.year, current.month + 1, 1);
    count++;
  }
  return slots;
}

/// Fee Schedules tab — converted from FeeConfigurationPanel.tsx's
/// `renderFeeSchedules` (Academic Calendar card + School Term Settings +
/// Fee Schedule per Group list/create form) plus its Edit/Delete modals.
class FeeSchedulesTab extends ConsumerStatefulWidget {
  final int? academicYearId;
  final List<AcademicYear> academicYears;
  final void Function(String message) onToast;
  final VoidCallback onOpenHelp;

  const FeeSchedulesTab({
    super.key,
    required this.academicYearId,
    required this.academicYears,
    required this.onToast,
    required this.onOpenHelp,
  });

  @override
  ConsumerState<FeeSchedulesTab> createState() => _FeeSchedulesTabState();
}

class _FeeSchedulesTabState extends ConsumerState<FeeSchedulesTab> {
  List<FeesGroup> _feeGroups = [];
  List<FeesType> _feeTypes = [];

  // Term settings
  int _numTerms = 3;
  List<_TermConfig> _terms = _defaultTerms.map((t) => t.copy()).toList();
  List<_TermConfig> _initialTerms = [];
  List<TermSettings> _termSettings = [];
  bool _isTermSettingsOpen = false;
  bool _isSavingTermSettings = false;

  // Schedules list
  List<FeeSchedule> _schedules = [];
  bool _isLoadingSchedules = false;
  final _scheduleSearchCtrl = TextEditingController();
  String _scheduleStatusFilter = '';
  int _schedulePage = 1;
  static const _schedulePageSize = 10;
  int _scheduleTotalCount = 0;
  int get _scheduleTotalPages => (_scheduleTotalCount / _schedulePageSize).ceil().clamp(1, 1 << 30);

  // Create schedule form
  bool _isCreateOpen = false;
  int? _scheduleFeeGroup;
  int? _scheduleFeeType;
  final _scheduleAmountCtrl = TextEditingController();
  String _scheduleFrequency = 'Monthly';
  final _scheduleDueDateCtrl = TextEditingController();
  int _scheduleGracePeriod = 5;
  final _scheduleLateFeeAmountCtrl = TextEditingController();
  List<TermBreakdownSlot> _scheduleTermBreakdown = [];
  String _scheduleStatus = 'active';
  int _scheduleNumInstallments = 1;
  final Map<String, String> _scheduleErrors = {};
  bool _isSavingSchedule = false;
  final _createFormKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadStatic();
    _loadTermSettings();
    _loadSchedules();
  }

  @override
  void dispose() {
    _scheduleSearchCtrl.dispose();
    _scheduleAmountCtrl.dispose();
    _scheduleDueDateCtrl.dispose();
    _scheduleLateFeeAmountCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FeeSchedulesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.academicYearId != widget.academicYearId) _loadTermSettings();
  }

  AcademicYear? get _currentYear => widget.academicYears.where((y) => y.id == widget.academicYearId).firstOrNull;
  String get _currentYearName => _currentYear?.name ?? 'Unknown';

  Future<void> _loadStatic() async {
    final repo = ref.read(feesConfigRepositoryProvider);
    try {
      final groups = await repo.fetchGroups();
      if (mounted) setState(() => _feeGroups = groups);
    } catch (_) {}
    try {
      final types = await repo.fetchTypes(page: 1, pageSize: 500, sortBy: 'name');
      if (mounted) setState(() => _feeTypes = types.rows);
    } catch (_) {
      if (mounted) widget.onToast('Unable to load fee type options.');
    }
  }

  Future<void> _loadTermSettings() async {
    if (widget.academicYearId == null) return;
    try {
      final all = await ref.read(feesConfigRepositoryProvider).fetchTermSettings();
      final filtered = all.where((t) => t.academicYear == widget.academicYearId).toList()
        ..sort((a, b) => a.termNumber.compareTo(b.termNumber));
      if (!mounted) return;
      if (filtered.isNotEmpty) {
        setState(() {
          _termSettings = filtered;
          _numTerms = filtered.length;
          _terms = filtered
              .map((t) => _TermConfig(name: t.termName, startDate: t.startDate, endDate: t.endDate, dueDate: t.defaultDueDate))
              .toList();
          _initialTerms = _terms.map((t) => t.copy()).toList();
        });
      } else {
        setState(() {
          _termSettings = [];
          _terms = _generateDefaultTerms(_currentYear, _numTerms);
          _initialTerms = [];
        });
      }
    } catch (_) {
      widget.onToast('Failed to load school term settings.');
    }
  }

  bool _hasTermSettingsChanged() {
    final current = _terms.take(_numTerms).toList();
    if (current.length != _initialTerms.length) return true;
    for (var i = 0; i < _numTerms; i++) {
      final cur = current[i];
      final init = i < _initialTerms.length ? _initialTerms[i] : null;
      if (init == null) return true;
      if (cur.name.trim() != init.name.trim()) return true;
      if (cur.startDate != init.startDate) return true;
      if (cur.endDate != init.endDate) return true;
      if (cur.dueDate != init.dueDate) return true;
    }
    return false;
  }

  Future<void> _saveTermSettings() async {
    if (widget.academicYearId == null) {
      widget.onToast('Select an academic year first.');
      return;
    }
    if (!_hasTermSettingsChanged()) {
      widget.onToast('No changes detected.');
      return;
    }
    setState(() => _isSavingTermSettings = true);
    try {
      final payload = <TermSettings>[];
      for (var i = 0; i < _numTerms; i++) {
        final term = _terms[i];
        final existing = _termSettings.where((t) => t.termNumber == i + 1).firstOrNull;
        payload.add(TermSettings(
          id: existing?.id,
          academicYear: widget.academicYearId!,
          termNumber: i + 1,
          termName: term.name,
          startDate: term.startDate,
          endDate: term.endDate,
          defaultDueDate: term.dueDate,
        ));
      }
      await ref.read(feesConfigRepositoryProvider).saveTermSettings(payload);
      widget.onToast('Term settings updated successfully.');
      await _loadTermSettings();
    } on FeesConfigValidationException catch (e) {
      widget.onToast(e.message);
    } catch (_) {
      widget.onToast('Failed to save term settings.');
    } finally {
      if (mounted) setState(() => _isSavingTermSettings = false);
    }
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoadingSchedules = true);
    try {
      final result = await ref.read(feesConfigRepositoryProvider).fetchSchedules(
            page: _schedulePage,
            pageSize: _schedulePageSize,
            search: _scheduleSearchCtrl.text.trim(),
            status: _scheduleStatusFilter,
          );
      if (mounted) {
        setState(() {
          _schedules = result.rows;
          _scheduleTotalCount = result.count;
        });
      }
    } catch (_) {
      if (mounted) widget.onToast('Unable to load fee schedules.');
    } finally {
      if (mounted) setState(() => _isLoadingSchedules = false);
    }
  }

  void _resetCreateForm() {
    setState(() {
      _scheduleFeeGroup = null;
      _scheduleFeeType = null;
      _scheduleAmountCtrl.clear();
      _scheduleFrequency = 'Monthly';
      _scheduleNumInstallments = 12;
      _scheduleDueDateCtrl.clear();
      _scheduleGracePeriod = 5;
      _scheduleLateFeeAmountCtrl.clear();
      _scheduleTermBreakdown = [];
      _scheduleStatus = 'active';
      _scheduleErrors.clear();
      _isCreateOpen = false;
    });
  }

  void _openCreateForm({int? presetGroupId}) {
    setState(() {
      _scheduleFeeGroup = presetGroupId;
      _scheduleFeeType = null;
      _scheduleAmountCtrl.clear();
      _scheduleFrequency = 'Monthly';
      _scheduleNumInstallments = 12;
      _scheduleDueDateCtrl.clear();
      _scheduleGracePeriod = 5;
      _scheduleLateFeeAmountCtrl.clear();
      _scheduleTermBreakdown = [];
      _scheduleStatus = 'active';
      _scheduleErrors.clear();
      _isCreateOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _createFormKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
    });
  }

  void _onFrequencyChanged(String value) {
    setState(() {
      _scheduleFrequency = value;
      _scheduleTermBreakdown = [];
      if (value == 'Monthly') {
        _scheduleNumInstallments = 12;
      } else if (value == 'Term-wise') {
        _scheduleNumInstallments = _termSettings.isNotEmpty ? _termSettings.length : 3;
        if (_termSettings.isNotEmpty) {
          _scheduleTermBreakdown = _termSettings
              .map((t) => TermBreakdownSlot(termNumber: t.termNumber, termName: t.termName, amount: '', dueDate: t.defaultDueDate))
              .toList();
        }
      } else if (value == 'Quarterly') {
        _scheduleNumInstallments = 4;
        _scheduleTermBreakdown = List.generate(4, (i) => TermBreakdownSlot(termNumber: i + 1, termName: 'QUARTER ${i + 1}'));
      } else if (value == 'Half-Yearly') {
        _scheduleNumInstallments = 2;
        _scheduleTermBreakdown = List.generate(2, (i) => TermBreakdownSlot(termNumber: i + 1, termName: 'HALF-YEAR ${i + 1}'));
      } else if (value == 'Yearly') {
        _scheduleNumInstallments = 1;
      } else {
        _scheduleNumInstallments = 1;
      }
    });
  }

  void _recalcTotalFromBreakdown() {
    final total = _scheduleTermBreakdown.fold<double>(0, (sum, s) => sum + (double.tryParse(s.amount) ?? 0));
    _scheduleAmountCtrl.text = total > 0 ? total.toString() : '';
  }

  Future<void> _handleCreateSchedule() async {
    if (widget.academicYearId == null) {
      widget.onToast('Select an academic year first.');
      return;
    }
    final errors = <String, String>{};
    if (_scheduleFeeType == null) errors['fee_type'] = 'Fee Type is required.';

    final usesBreakdown = _scheduleFrequency.contains('Term-wise') || _scheduleTermBreakdown.isNotEmpty;
    if (usesBreakdown) {
      if (_scheduleTermBreakdown.isEmpty) {
        widget.onToast('Please apply installments or configure school terms first.');
        return;
      }
      final invalid = _scheduleTermBreakdown.any((s) => s.amount.isEmpty || (double.tryParse(s.amount) ?? -1) < 0 || s.dueDate.isEmpty);
      if (invalid) {
        widget.onToast('Please provide a valid amount and due date for all installments.');
        return;
      }
    } else {
      final amt = double.tryParse(_scheduleAmountCtrl.text);
      if (amt == null || amt <= 0) errors['amount'] = 'Valid amount required.';
      if (_scheduleDueDateCtrl.text.isEmpty) errors['due_date'] = 'Due date is required.';
    }

    setState(() => _scheduleErrors
      ..clear()
      ..addAll(errors));
    if (errors.isNotEmpty) {
      widget.onToast('Please fix validation errors before submitting.');
      return;
    }

    var finalAmount = _scheduleAmountCtrl.text;
    var finalDueDate = _scheduleDueDateCtrl.text;
    if (_scheduleTermBreakdown.isNotEmpty) {
      final sum = _scheduleTermBreakdown.fold<double>(0, (s, b) => s + (double.tryParse(b.amount) ?? 0));
      finalAmount = sum.toStringAsFixed(2);
      finalDueDate = _scheduleTermBreakdown.first.dueDate;
    }

    var normalizedFrequency = _scheduleFrequency;
    if (normalizedFrequency.contains('Monthly')) normalizedFrequency = 'Monthly';
    if (normalizedFrequency.contains('Term-wise')) normalizedFrequency = 'Term-wise';
    if (normalizedFrequency.contains('Custom')) normalizedFrequency = 'Custom';

    setState(() => _isSavingSchedule = true);
    try {
      await ref.read(feesConfigRepositoryProvider).createSchedule(
            academicYear: widget.academicYearId!,
            feeGroup: _scheduleFeeGroup,
            feeType: _scheduleFeeType!,
            amount: finalAmount,
            collectionFrequency: normalizedFrequency,
            dueDate: finalDueDate,
            lateFeeApplicable: _scheduleGracePeriod > 0 || _scheduleLateFeeAmountCtrl.text.isNotEmpty,
            gracePeriod: _scheduleGracePeriod,
            lateFeeRule: _scheduleLateFeeAmountCtrl.text.isEmpty ? '' : 'Rs. ${_scheduleLateFeeAmountCtrl.text} Flat',
            termBreakdown: _scheduleTermBreakdown,
            status: _scheduleStatus,
          );
      widget.onToast('Fee schedule created successfully.');
      _resetCreateForm();
      await _loadSchedules();
    } on FeesConfigValidationException catch (e) {
      setState(() => _scheduleErrors.addAll(e.fieldErrors));
      widget.onToast(e.fieldErrors.values.firstOrNull ?? e.message);
    } catch (_) {
      widget.onToast('Failed to create fee schedule.');
    } finally {
      if (mounted) setState(() => _isSavingSchedule = false);
    }
  }

  Future<void> _openEditSchedule(FeeSchedule schedule) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditScheduleDialog(
        schedule: schedule,
        feeGroups: _feeGroups,
        feeTypes: _feeTypes,
        termSettings: _termSettings,
      ),
    );
    if (saved == true) {
      widget.onToast('Fee schedule updated successfully.');
      await _loadSchedules();
    }
  }

  Future<void> _openDeleteSchedule(FeeSchedule schedule) async {
    final deleted = await showDialog<bool>(context: context, builder: (_) => _DeleteScheduleDialog(schedule: schedule));
    if (deleted == true) {
      widget.onToast('Fee schedule deleted successfully.');
      await _loadSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAcademicCalendarCard(),
        const SizedBox(height: 20),
        _buildTermSettingsCard(),
        const SizedBox(height: 20),
        FeeConfigCard(key: _createFormKey, child: _buildSchedulesSection()),
      ],
    );
  }

  Widget _buildAcademicCalendarCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(color: const Color(0xFFF5F6FF), border: Border.all(color: const Color(0xFFDDD8F8)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              const Text('📅 ACADEMIC CALENDAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: feeConfigPurple)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: feeConfigPurple, borderRadius: BorderRadius.circular(20)),
                child: Text(_currentYearName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: feeConfigBorder, borderRadius: BorderRadius.circular(20)),
                child: const Text('CBSE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: feeConfigInk2)),
              ),
              if (_currentYear != null && widget.academicYears.any((y) => y.id == widget.academicYearId && y.isCurrent))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Active Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 40,
            runSpacing: 10,
            children: [
              _calendarStat('YEAR START', _currentYear?.startDate.isNotEmpty == true ? _fmtDateShort(_currentYear!.startDate) : '—'),
              _calendarStat('YEAR END', _currentYear?.endDate.isNotEmpty == true ? _fmtDateShort(_currentYear!.endDate) : '—'),
              _calendarStat('BASED ON', '$_numTerms Fee Term${_numTerms > 1 ? 's' : ''}'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final t in _terms.take(_numTerms))
                Container(
                  constraints: const BoxConstraints(minWidth: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFC7C2F8)), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigPurple)),
                      const SizedBox(height: 4),
                      Text('${_fmtDateShort(t.startDate)} → ${_fmtDateShort(t.endDate)}', style: const TextStyle(fontSize: 12.5, color: feeConfigInk2)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: feeConfigInk3)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: feeConfigInk1)),
      ],
    );
  }

  Widget _buildTermSettingsCard() {
    return FeeConfigCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isTermSettingsOpen = !_isTermSettingsOpen),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('School Term Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: feeConfigInk1)),
                      SizedBox(height: 4),
                      Text('Set how many terms your school uses. This controls term slots in all fee schedules below.', style: TextStyle(fontSize: 13, color: feeConfigInk3)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isTermSettingsOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: feeConfigBorder)),
                    child: const Icon(Icons.keyboard_arrow_down, color: feeConfigPurple),
                  ),
                ),
              ],
            ),
          ),
          if (_isTermSettingsOpen) ...[
            const SizedBox(height: 20),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FeeConfigLabel('NUMBER OF TERMS PER YEAR'),
                      FeeConfigSelect<int>(
                        value: _numTerms,
                        items: const [1, 2, 3, 4],
                        labelOf: (n) => '$n Term${n > 1 ? 's' : ''} per year',
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _numTerms = v;
                            _terms = _generateDefaultTerms(_currentYear, v);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                FeeConfigPrimaryButton(
                  label: _isSavingTermSettings ? 'Saving...' : 'Save Term Settings',
                  onPressed: (_isSavingTermSettings || !_hasTermSettingsChanged()) ? null : _saveTermSettings,
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _numTerms; i++) _termRow(i),
          ],
        ],
      ),
    );
  }

  Widget _termRow(int i) {
    final term = i < _terms.length ? _terms[i] : _TermConfig(name: 'Term ${i + 1}', startDate: '', endDate: '', dueDate: '');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(top: i > 0 ? const BorderSide(color: feeConfigBorder) : BorderSide.none)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: feeConfigPurple),
            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TERM ${i + 1} NAME', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: feeConfigInk3)),
                const SizedBox(height: 6),
                TextField(
                  controller: TextEditingController(text: term.name)..selection = TextSelection.collapsed(offset: term.name.length),
                  decoration: feeConfigInputDecoration(),
                  onChanged: (v) => setState(() => _terms[i].name = v),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('START DATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: feeConfigInk3)),
                const SizedBox(height: 6),
                _dateField(term.startDate, (v) => setState(() => _terms[i].startDate = v)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('END DATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: feeConfigInk3)),
                const SizedBox(height: 6),
                _dateField(term.endDate, (v) => setState(() => _terms[i].endDate = v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String value, ValueChanged<String> onChanged) {
    return InkWell(
      onTap: () async {
        final initial = DateTime.tryParse(value) ?? DateTime.now();
        final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) onChanged(DateFormat('yyyy-MM-dd').format(picked));
      },
      child: InputDecorator(
        decoration: feeConfigInputDecoration(),
        child: Text(value.isEmpty ? '' : _fmtDateShort(value), style: const TextStyle(fontSize: 13.5)),
      ),
    );
  }

  Widget _buildSchedulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Fee Schedule per Group', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: feeConfigInk1)),
                        SizedBox(height: 4),
                        Text('Manage fee collection schedules for each fee type per group.', style: TextStyle(fontSize: 13, color: feeConfigInk3)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onOpenHelp,
                    tooltip: 'View Fee Schedule Help',
                    icon: const Icon(Icons.info_outline, size: 16, color: feeConfigPurple),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F3FE), side: const BorderSide(color: Color(0xFFDDD8F8)), shape: const CircleBorder()),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FeeConfigPrimaryButton(
          label: _isCreateOpen ? '- Close Form' : '+ Create Schedule',
          onPressed: () => _isCreateOpen ? _resetCreateForm() : _openCreateForm(),
        ),
        if (_isCreateOpen) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: feeConfigBorder), borderRadius: BorderRadius.circular(12)),
            child: _buildCreateScheduleForm(),
          ),
        ],
        const SizedBox(height: 18),
        TextField(controller: _scheduleSearchCtrl, decoration: feeConfigInputDecoration(hint: 'Search by fee group, fee type, or academic year...'), onSubmitted: (_) => _loadSchedules()),
        const SizedBox(height: 10),
        FeeConfigSelect<String>(
          value: _scheduleStatusFilter,
          items: const ['', 'active', 'inactive'],
          labelOf: (v) => v.isEmpty ? 'All Status' : (v == 'active' ? 'Active' : 'Inactive'),
          onChanged: (v) {
            setState(() {
              _scheduleStatusFilter = v ?? '';
              _schedulePage = 1;
            });
            _loadSchedules();
          },
        ),
        const SizedBox(height: 18),
        if (_isLoadingSchedules)
          const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Loading fee schedules...', style: TextStyle(color: feeConfigInk3))))
        else if (_schedules.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No fee schedules found. Create one to get started.', style: TextStyle(color: feeConfigInk3))))
        else ...[
          for (final entry in _groupSchedules().entries) _buildGroupBlock(entry.key, entry.value),
          if (_scheduleTotalPages > 1) ...[
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: _schedulePage == 1 ? null : () { setState(() => _schedulePage--); _loadSchedules(); }, child: const Text('← Prev')),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('Page $_schedulePage of $_scheduleTotalPages', style: const TextStyle(color: feeConfigInk3))),
                  TextButton(onPressed: _schedulePage >= _scheduleTotalPages ? null : () { setState(() => _schedulePage++); _loadSchedules(); }, child: const Text('Next →')),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Map<String, List<FeeSchedule>> _groupSchedules() {
    final map = <String, List<FeeSchedule>>{};
    for (final s in _schedules) {
      final key = s.feeGroupName ?? (s.feeGroup?.toString() ?? 'Ungrouped');
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  Widget _buildCreateScheduleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 260,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const FeeConfigLabel('FEE GROUP'),
                FeeConfigSelect<int?>(
                  value: _scheduleFeeGroup,
                  hint: 'Select fee group',
                  items: [null, for (final g in _feeGroups) g.id],
                  labelOf: (id) => id == null ? 'Select fee group' : _feeGroups.firstWhere((g) => g.id == id).name,
                  onChanged: (v) => setState(() => _scheduleFeeGroup = v),
                ),
                FeeConfigFieldError(_scheduleErrors['fee_group']),
              ]),
            ),
            SizedBox(
              width: 260,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const FeeConfigLabel('FEE TYPE'),
                FeeConfigSelect<int?>(
                  value: _scheduleFeeType,
                  hint: 'Select fee type',
                  items: [null, for (final t in _feeTypes) t.id],
                  labelOf: (id) => id == null ? 'Select fee type' : _feeTypes.firstWhere((t) => t.id == id).name,
                  onChanged: (v) => setState(() => _scheduleFeeType = v),
                ),
                if (_feeTypes.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 4), child: Text('No fee types configured yet — create one in the Fee Types tab first.', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))))
                else
                  FeeConfigFieldError(_scheduleErrors['fee_type']),
              ]),
            ),
            SizedBox(
              width: 260,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const FeeConfigLabel('COLLECTION STRUCTURE'),
                FeeConfigSelect<String>(value: _scheduleFrequency, items: _kFeeStructureOptions, labelOf: (v) => v, onChanged: (v) => v != null ? _onFrequencyChanged(v) : null),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 200,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const FeeConfigLabel('GRACE PERIOD (DAYS)'),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: feeConfigInputDecoration(hint: '5'),
                  controller: TextEditingController(text: '$_scheduleGracePeriod'),
                  onChanged: (v) => _scheduleGracePeriod = int.tryParse(v) ?? 0,
                ),
              ]),
            ),
            SizedBox(
              width: 260,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const FeeConfigLabel('LATE FEE AMOUNT (RS.)'),
                TextField(controller: _scheduleLateFeeAmountCtrl, keyboardType: TextInputType.number, decoration: feeConfigInputDecoration(hint: '0')),
              ]),
            ),
            SizedBox(
              width: 200,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const FeeConfigLabel('STATUS'),
                FeeConfigSelect<String>(value: _scheduleStatus, items: const ['active', 'inactive'], labelOf: (v) => v == 'active' ? 'Active' : 'Inactive', onChanged: (v) => setState(() => _scheduleStatus = v ?? 'active')),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_scheduleFrequency == 'Monthly') _buildMonthlyForm(),
        if (_scheduleFrequency == 'Yearly') _buildYearlyForm(),
        if (_scheduleFrequency == 'Custom / One-time') _buildCustomForm(),
        if (_scheduleFrequency == 'Term-wise' && _termSettings.isEmpty && _scheduleTermBreakdown.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border.all(color: feeConfigBorder, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No terms configured. Please set them up in "School Term Settings" above.', style: TextStyle(color: feeConfigInk3))),
          ),
        if (_scheduleTermBreakdown.isNotEmpty && _scheduleFrequency != 'Monthly') _buildBreakdownGrid(),
      ],
    );
  }

  Widget _buildMonthlyForm() {
    final slots = _scheduleTermBreakdown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FeeConfigLabel('MONTHLY AMOUNT (RS.) — APPLIES PER MONTH'),
        Row(
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _scheduleAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: feeConfigInputDecoration(hint: 'e.g. 2800'),
                onChanged: (v) {
                  if (v.isEmpty) return;
                  final generated = _generateMonthlySlots(_currentYear).map((s) => s.copyWith(amount: v)).toList();
                  setState(() => _scheduleTermBreakdown = generated);
                },
              ),
            ),
            const SizedBox(width: 12),
            FeeConfigPrimaryButton(label: _isSavingSchedule ? 'Saving...' : 'Save Schedule', onPressed: _isSavingSchedule ? null : _handleCreateSchedule),
            const SizedBox(width: 10),
            FeeConfigOutlineButton(label: 'Cancel', onPressed: _resetCreateForm),
          ],
        ),
        if (slots.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final s in slots)
                Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.termName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            Text('Due: ${s.dueDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Text('₹${s.amount}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildYearlyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FeeConfigLabel('YEARLY AMOUNT (RS.)'),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: 200, child: TextField(controller: _scheduleAmountCtrl, keyboardType: TextInputType.number, decoration: feeConfigInputDecoration(hint: 'e.g. 25000'))),
            SizedBox(width: 180, child: _dateField(_scheduleDueDateCtrl.text, (v) => setState(() => _scheduleDueDateCtrl.text = v))),
            FeeConfigPrimaryButton(label: _isSavingSchedule ? 'Saving...' : 'Save Schedule', onPressed: _isSavingSchedule ? null : _handleCreateSchedule),
            FeeConfigOutlineButton(label: 'Cancel', onPressed: _resetCreateForm),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FeeConfigLabel('HOW MANY INSTALLMENTS?'),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: feeConfigInputDecoration(hint: '1'),
                controller: TextEditingController(text: '$_scheduleNumInstallments'),
                onChanged: (v) => _scheduleNumInstallments = int.tryParse(v) ?? 1,
              ),
            ),
            const SizedBox(width: 8),
            FeeConfigGhostButton(
              label: 'Apply →',
              onPressed: () {
                final count = _scheduleNumInstallments < 1 ? 1 : _scheduleNumInstallments;
                setState(() => _scheduleTermBreakdown = List.generate(count, (i) => TermBreakdownSlot(termNumber: i + 1, termName: 'INSTALLMENT ${i + 1}')));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const FeeConfigLabel('BREAKDOWN SLOTS'),
        for (var i = 0; i < _scheduleTermBreakdown.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _breakdownSlotRow(i),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Total Amount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(width: 10),
                Text('₹${feesFormatAmountFromString(_scheduleAmountCtrl.text.isEmpty ? '0' : _scheduleAmountCtrl.text)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                FeeConfigPrimaryButton(label: _isSavingSchedule ? 'Saving...' : 'Save Schedule', onPressed: _isSavingSchedule ? null : _handleCreateSchedule),
                const SizedBox(width: 10),
                FeeConfigOutlineButton(label: 'Cancel', onPressed: _resetCreateForm),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _breakdownSlotRow(int i) {
    final slot = _scheduleTermBreakdown[i];
    final readOnly = _scheduleFrequency == 'Term-wise';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1A6D4AFF)),
            child: Text(
              _scheduleFrequency == 'Term-wise' ? 'T${slot.termNumber}' : '${i + 1}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: feeConfigPurple),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: slot.termName)..selection = TextSelection.collapsed(offset: slot.termName.length),
              readOnly: readOnly,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              onChanged: (v) => setState(() => _scheduleTermBreakdown[i] = slot.copyWith(termName: v)),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 130,
            child: TextField(
              controller: TextEditingController(text: slot.amount),
              keyboardType: TextInputType.number,
              decoration: feeConfigInputDecoration(hint: '0.00'),
              onChanged: (v) {
                setState(() => _scheduleTermBreakdown[i] = slot.copyWith(amount: v));
                _recalcTotalFromBreakdown();
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: _dateField(slot.dueDate, (v) => setState(() => _scheduleTermBreakdown[i] = slot.copyWith(dueDate: v))),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupBlock(String groupName, List<FeeSchedule> rows) {
    final words = groupName.split(' ').where((w) => w.isNotEmpty).take(2);
    final initials = words.map((w) => w[0].toUpperCase()).join();
    final summary = rows.map((s) {
      final amt = feesFormatAmountFromString(s.amount);
      if (s.collectionFrequency == 'Custom') return '₹$amt custom';
      if (s.collectionFrequency == 'Monthly') return '₹$amt / mo';
      return '₹$amt / yr';
    }).join(' + ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFF5B4FCF), borderRadius: BorderRadius.circular(12)),
                  child: Text(initials.isEmpty ? 'FG' : initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(groupName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      Text('${rows.length} fee types configured · $summary', style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                FeeConfigOutlineButton(label: '+ Add Fee Type', onPressed: () {
                  final gid = rows.first.feeGroup ?? _feeGroups.where((g) => g.name == groupName).firstOrNull?.id;
                  _openCreateForm(presetGroupId: gid);
                }),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) _scheduleRow(rows[i], isLast: i == rows.length - 1),
        ],
      ),
    );
  }

  Widget _scheduleRow(FeeSchedule s, {required bool isLast}) {
    final (badgeBg, badgeFg) = s.collectionFrequency == 'Term-wise'
        ? (const Color(0xFFDDF7E7), const Color(0xFF19A159))
        : s.collectionFrequency == 'Custom'
            ? (const Color(0xFFFEE5E2), const Color(0xFFE54D42))
            : (const Color(0xFFE6E9FF), const Color(0xFF4A57E2));

    Widget amountChips;
    if (s.termBreakdown.isNotEmpty) {
      final shown = s.termBreakdown.take(3).toList();
      amountChips = Wrap(spacing: 8, runSpacing: 6, children: [
        for (final slot in shown)
          _chip('${slot.termName.replaceFirst('INSTALLMENT ', 'I')}: ₹${feesFormatAmountFromString(slot.amount)}'),
        if (s.termBreakdown.length > 3) Text('+${s.termBreakdown.length - 3} more', style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
      ]);
    } else {
      final dueSuffix = s.dueDate.isNotEmpty ? ' (${_fmtDateShort(s.dueDate).replaceAll(RegExp(r' \d{4}$'), '')})' : '';
      amountChips = _chip('I1: ₹${feesFormatAmountFromString(s.amount)}$dueSuffix');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: isLast ? BorderSide.none : const BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.feeTypeName ?? '${s.feeType}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(s.collectionFrequency, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: badgeFg)),
                ),
                const SizedBox(height: 6),
                amountChips,
                const SizedBox(height: 6),
                Text('Grace: ${s.gracePeriod} days', style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                Text('Late fee: ${s.lateFeeRule.isEmpty ? 'None' : s.lateFeeRule}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A94A6))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FeeConfigOutlineButton(small: true, label: 'Edit', onPressed: () => _openEditSchedule(s)),
              const SizedBox(height: 8),
              FeeConfigDangerButton(small: true, label: 'Delete', onPressed: () => _openDeleteSchedule(s)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFEEF0F6), border: Border.all(color: const Color(0xFFD8DCE8)), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF50607A))),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _EditScheduleDialog extends ConsumerStatefulWidget {
  final FeeSchedule schedule;
  final List<FeesGroup> feeGroups;
  final List<FeesType> feeTypes;
  final List<TermSettings> termSettings;

  const _EditScheduleDialog({required this.schedule, required this.feeGroups, required this.feeTypes, required this.termSettings});

  @override
  ConsumerState<_EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends ConsumerState<_EditScheduleDialog> {
  late int? _feeGroup = widget.schedule.feeGroup;
  late int? _feeType = widget.schedule.feeType;
  late String _frequency = widget.schedule.collectionFrequency;
  late final _amountCtrl = TextEditingController(text: widget.schedule.amount);
  late final _dueDateCtrl = TextEditingController(text: widget.schedule.dueDate);
  late bool _lateFeeApplicable = widget.schedule.lateFeeApplicable;
  late int _gracePeriod = widget.schedule.gracePeriod;
  late final _lateFeeAmountCtrl = TextEditingController(text: RegExp(r'(\d+(\.\d+)?)').firstMatch(widget.schedule.lateFeeRule)?.group(1) ?? '');
  late String _status = widget.schedule.status;
  late List<TermBreakdownSlot> _breakdown = widget.schedule.termBreakdown.isNotEmpty
      ? widget.schedule.termBreakdown.map((s) => s.copyWith()).toList()
      : widget.termSettings.map((t) => TermBreakdownSlot(termNumber: t.termNumber, termName: t.termName, dueDate: t.defaultDueDate)).toList();
  final Map<String, String> _errors = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dueDateCtrl.dispose();
    _lateFeeAmountCtrl.dispose();
    super.dispose();
  }

  bool get _usesBreakdown => _kBreakdownFrequencies.contains(_frequency);

  void _recalcTotal() {
    final total = _breakdown.fold<double>(0, (s, b) => s + (double.tryParse(b.amount) ?? 0));
    _amountCtrl.text = total > 0 ? total.toString() : '';
  }

  Future<void> _save() async {
    final errors = <String, String>{};
    if (_feeType == null) errors['fee_type'] = 'Fee Type is required.';

    if (_frequency == 'Term-wise') {
      if (_breakdown.isEmpty) {
        errors['general'] = 'No terms configured for this academic year.';
      } else {
        final invalid = _breakdown.any((s) => s.amount.isEmpty || (double.tryParse(s.amount) ?? -1) < 0 || s.dueDate.isEmpty);
        if (invalid) errors['general'] = 'Please provide a valid amount and due date for all terms.';
      }
    } else if (!_usesBreakdown) {
      final amt = double.tryParse(_amountCtrl.text);
      if (amt == null || amt <= 0) errors['amount'] = 'Valid amount required.';
      if (_dueDateCtrl.text.isEmpty) errors['due_date'] = 'Due date is required.';
    }

    setState(() => _errors
      ..clear()
      ..addAll(errors));
    if (errors.isNotEmpty) return;

    var finalAmount = _amountCtrl.text;
    var finalDueDate = _dueDateCtrl.text;
    if (_frequency == 'Term-wise') {
      final sum = _breakdown.fold<double>(0, (s, b) => s + (double.tryParse(b.amount) ?? 0));
      finalAmount = sum.toString();
      if (_breakdown.isNotEmpty) finalDueDate = _breakdown.first.dueDate;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(feesConfigRepositoryProvider).updateSchedule(
            widget.schedule.id,
            academicYear: widget.schedule.academicYear,
            feeGroup: _feeGroup,
            feeType: _feeType,
            amount: finalAmount,
            collectionFrequency: _frequency,
            dueDate: finalDueDate,
            lateFeeApplicable: _lateFeeApplicable,
            gracePeriod: _gracePeriod,
            lateFeeRule: _lateFeeAmountCtrl.text.isEmpty ? '' : 'Rs. ${_lateFeeAmountCtrl.text} Flat',
            termBreakdown: _frequency == 'Term-wise' ? _breakdown : const [],
            status: _status,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on FeesConfigValidationException catch (e) {
      setState(() => _errors.addAll(e.fieldErrors));
    } catch (_) {
      // keep dialog open
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = _usesBreakdown;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 900 : 520, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Fee Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 24, color: feeConfigBorder),
              Flexible(
                child: SingleChildScrollView(
                  child: Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildLeftColumn()),
                      if (wide) const SizedBox(width: 28),
                      if (wide) Expanded(child: _buildBreakdownColumn()) else _buildBreakdownColumn(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: FeeConfigOutlineButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false))),
                  const SizedBox(width: 10),
                  Expanded(child: FeeConfigPrimaryButton(label: _isSaving ? 'Updating...' : 'Update Schedule', onPressed: _isSaving ? null : _save)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Fee Group', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigInk2)),
        const SizedBox(height: 6),
        FeeConfigSelect<int?>(
          value: _feeGroup,
          hint: 'Select fee group',
          items: [null, for (final g in widget.feeGroups) g.id],
          labelOf: (id) => id == null ? 'Select fee group' : widget.feeGroups.firstWhere((g) => g.id == id).name,
          hasError: _errors.containsKey('fee_group'),
          onChanged: (v) => setState(() => _feeGroup = v),
        ),
        FeeConfigFieldError(_errors['fee_group']),
        const SizedBox(height: 14),
        const Text('Fee Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigInk2)),
        const SizedBox(height: 6),
        FeeConfigSelect<int?>(
          value: _feeType,
          hint: 'Select fee type',
          items: [null, for (final t in widget.feeTypes) t.id],
          labelOf: (id) => id == null ? 'Select fee type' : widget.feeTypes.firstWhere((t) => t.id == id).name,
          hasError: _errors.containsKey('fee_type'),
          onChanged: (v) => setState(() => _feeType = v),
        ),
        FeeConfigFieldError(_errors['fee_type']),
        const SizedBox(height: 14),
        const Text('Collection Frequency / Structure', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigInk2)),
        const SizedBox(height: 6),
        FeeConfigSelect<String>(
          value: _frequency,
          items: _kEditFrequencyOptions,
          labelOf: (v) => v,
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _frequency = v;
              if (v == 'Term-wise' && _breakdown.isEmpty) {
                _breakdown = widget.termSettings.map((t) => TermBreakdownSlot(termNumber: t.termNumber, termName: t.termName, dueDate: t.defaultDueDate)).toList();
              }
            });
          },
        ),
        if (!_usesBreakdown) ...[
          const SizedBox(height: 14),
          const Text('Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigInk2)),
          const SizedBox(height: 6),
          TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: feeConfigInputDecoration(hint: '0.00', hasError: _errors.containsKey('amount'))),
          FeeConfigFieldError(_errors['amount']),
          const SizedBox(height: 14),
          const Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigInk2)),
          const SizedBox(height: 6),
          _EditDateField(controller: _dueDateCtrl, hasError: _errors.containsKey('due_date')),
          FeeConfigFieldError(_errors['due_date']),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Checkbox(value: _lateFeeApplicable, onChanged: (v) => setState(() => _lateFeeApplicable = v ?? false)),
            const Text('Late fee applicable', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: feeConfigInk1)),
          ],
        ),
        if (_lateFeeApplicable) ...[
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  const Text('Grace Period (Days)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigInk2)),
                  const SizedBox(height: 6),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: feeConfigInputDecoration(hint: '0'),
                    controller: TextEditingController(text: '$_gracePeriod'),
                    onChanged: (v) => _gracePeriod = int.tryParse(v) ?? 0,
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  const Text('Late Fee Amount (Rs.)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigInk2)),
                  const SizedBox(height: 6),
                  TextField(controller: _lateFeeAmountCtrl, keyboardType: TextInputType.number, decoration: feeConfigInputDecoration(hint: '0')),
                ]),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: feeConfigInk2)),
        const SizedBox(height: 6),
        FeeConfigSelect<String>(value: _status, items: const ['active', 'inactive'], labelOf: (v) => v == 'active' ? 'Active' : 'Inactive', onChanged: (v) => setState(() => _status = v ?? 'active')),
        FeeConfigFieldError(_errors['general']),
      ],
    );
  }

  Widget _buildBreakdownColumn() {
    if (!_usesBreakdown) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$_frequency Breakdown Slots', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: feeConfigInk1)),
        const Text('Specify amounts and due dates. Total amount is calculated automatically.', style: TextStyle(fontSize: 11, color: feeConfigInk3)),
        const SizedBox(height: 12),
        if (_breakdown.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(border: Border.all(color: feeConfigBorder), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('No slots configured for this schedule.', style: TextStyle(fontSize: 13, color: feeConfigInk3))),
          )
        else
          for (var i = 0; i < _breakdown.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _slotRow(i),
          ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEEF2F6), border: Border.all(color: const Color(0xFFD2D6DC)), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Fee Schedule Amount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              Text('₹${feesFormatAmountFromString(_amountCtrl.text.isEmpty ? '0' : _amountCtrl.text)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slotRow(int i) {
    final slot = _breakdown[i];
    final readOnly = _frequency == 'Term-wise' || _frequency == 'Monthly';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FB), border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEDE9FE), border: Border.all(color: const Color(0xFFC4B5FD))),
            child: Text(_frequency == 'Term-wise' ? 'T${slot.termNumber}' : '${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: slot.termName)..selection = TextSelection.collapsed(offset: slot.termName.length),
              readOnly: readOnly,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              onChanged: (v) => setState(() => _breakdown[i] = slot.copyWith(termName: v)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: TextField(
              controller: TextEditingController(text: slot.amount),
              keyboardType: TextInputType.number,
              decoration: feeConfigInputDecoration(hint: '₹0.00'),
              style: const TextStyle(fontSize: 12.5),
              onChanged: (v) {
                setState(() => _breakdown[i] = slot.copyWith(amount: v));
                _recalcTotal();
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 130, child: _EditDateField(value: slot.dueDate, onChanged: (v) => setState(() => _breakdown[i] = slot.copyWith(dueDate: v)))),
        ],
      ),
    );
  }
}

class _EditDateField extends StatelessWidget {
  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  const _EditDateField({this.controller, this.value, this.onChanged, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    final text = controller?.text ?? value ?? '';
    return Builder(builder: (context) {
      return InkWell(
        onTap: () async {
          final initial = DateTime.tryParse(text) ?? DateTime.now();
          final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (picked != null) {
            final formatted = DateFormat('yyyy-MM-dd').format(picked);
            if (controller != null) controller!.text = formatted;
            onChanged?.call(formatted);
          }
        },
        child: InputDecorator(
          decoration: feeConfigInputDecoration(hasError: hasError),
          child: Text(text.isEmpty ? '' : _fmtDateShort(text), style: const TextStyle(fontSize: 13)),
        ),
      );
    });
  }
}

class _DeleteScheduleDialog extends ConsumerStatefulWidget {
  final FeeSchedule schedule;
  const _DeleteScheduleDialog({required this.schedule});

  @override
  ConsumerState<_DeleteScheduleDialog> createState() => _DeleteScheduleDialogState();
}

class _DeleteScheduleDialogState extends ConsumerState<_DeleteScheduleDialog> {
  bool _isDeleting = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await ref.read(feesConfigRepositoryProvider).deleteSchedule(widget.schedule.id);
      if (mounted) Navigator.of(context).pop(true);
    } on FeesConfigValidationException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to delete fee schedule.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Delete Fee Schedule?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to delete this fee schedule? This action cannot be undone.', style: TextStyle(fontSize: 14, color: feeConfigInk2)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6), border: const Border(left: BorderSide(color: Color(0xFFDC2626), width: 3))),
              child: Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B))),
            ),
          ],
        ],
      ),
      actions: [
        FeeConfigOutlineButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
        FeeConfigDangerButton(label: _isDeleting ? 'Deleting...' : 'Delete', onPressed: _isDeleting ? null : _delete),
      ],
    );
  }
}
