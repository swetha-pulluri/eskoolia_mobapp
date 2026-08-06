import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/due_student.dart';
import '../../domain/models/dues_class_group.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fees_summary.dart';
import '../providers/fees_config_providers.dart';
import '../providers/fees_dues_providers.dart';
import '../providers/fees_providers.dart';
import '../providers/fees_year_end_providers.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../utils/fee_assignment_format.dart' show groupIndian;
import '../utils/fy_report_pdf.dart';
import '../widgets/fees_layout.dart';
import '../widgets/fees_year_end_styles.dart';
import '../widgets/fy_edit_amounts_dialog.dart';

const _resolutionGroups = [
  (
    'Continue enrollment',
    [
      ('carry', 'Carry dues to next year'),
      ('writeoff', 'Write off balance'),
      ('scholarship', 'Mark as scholarship / waiver'),
      ('legal', 'Legal follow-up'),
    ],
  ),
  (
    'Discontinue student',
    [
      ('archive', 'Discontinue — Archive student'),
      ('offboard', 'Discontinue — Offboard & generate TC'),
    ],
  ),
];

const _reports = [
  ('Fee Collection Summary', 'fee_collection_summary'),
  ('Class-wise Report', 'class_wise_report'),
  ('Outstanding Dues Report', 'outstanding_dues'),
  ('Concession Report', 'concession_report'),
  ('Payment Method Breakdown', 'payment_method_breakdown'),
];

const _wizardSteps = [(1, 'Confirm totals'), (2, 'Set year & date'), (3, 'Copy structures'), (4, 'Execute rollover')];

/// Year-End — converted from
/// `frontend/app/(dashboard)/fees/year-end/page.tsx` (the "Year-End" tab of
/// the Fees module, `/fees/year-end`). Unlike the other Fees screens, the
/// real implementation lives directly in this page.tsx file rather than a
/// separate `*Panel.tsx` component — the frontend is the sole source of
/// truth for this port; see the Carry Forward table, Year-End Reports
/// table, Archive & Rollover wizard (fy_edit_amounts_dialog.dart for its
/// "Edit Amounts" modal), and PDF/CSV report generators
/// (fy_report_pdf.dart / file_download_helper.dart).
class FeesYearEndPage extends ConsumerStatefulWidget {
  const FeesYearEndPage({super.key});

  @override
  ConsumerState<FeesYearEndPage> createState() => _FeesYearEndPageState();
}

class _FeesYearEndPageState extends ConsumerState<FeesYearEndPage> {
  List<DuesClassGroup> _groups = [];
  FeesSummary? _summary;
  bool _loading = true;
  final Map<String, String> _resolutions = {};
  final Set<String> _applied = {};
  int _wizardStep = 1;
  String _csvLoading = '';
  String _pdfLoading = '';
  String? _toast;
  List<FeesGroup> _feeGroups = [];
  bool _grpLoading = false;

  final _nextYearCtrl = TextEditingController(text: '2026-27');
  final _rolloverDateCtrl = TextEditingController(text: '2026-04-01');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _nextYearCtrl.dispose();
    _rolloverDateCtrl.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    setState(() => _toast = message);
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted && _toast == message) setState(() => _toast = null);
    });
  }

  Future<List<DuesClassGroup>?> _tryTier(int tier) async {
    try {
      return await ref.read(feesDuesRepositoryProvider).fetchByClass(tier: tier);
    } catch (_) {
      return null;
    }
  }

  Future<FeesSummary?> _trySummary() async {
    try {
      return await ref.read(feesRepositoryProvider).fetchAssignmentsSummary();
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final f1 = _tryTier(1);
    final f2 = _tryTier(2);
    final f3 = _tryTier(3);
    final fSum = _trySummary();
    final tiers = [await f1, await f2, await f3];
    final summary = await fSum;
    if (!mounted) return;

    final seen = <String>{};
    final clsMap = <String, List<DueStudent>>{};
    for (final tier in tiers) {
      if (tier == null) continue;
      for (final g in tier) {
        for (final st in g.students) {
          if (seen.contains(st.id)) continue;
          seen.add(st.id);
          clsMap.putIfAbsent(g.cls, () => []).add(st);
        }
      }
    }
    final merged = [
      for (final entry in clsMap.entries)
        DuesClassGroup(cls: entry.key, totalStudents: entry.value.length, assignedStudents: entry.value.length, students: entry.value),
    ];

    setState(() {
      _groups = merged;
      if (summary != null) _summary = summary;
      _loading = false;
    });
  }

  Future<void> _maybeLoadFeeGroups() async {
    if (_feeGroups.isNotEmpty || _grpLoading) return;
    setState(() => _grpLoading = true);
    try {
      final groups = await ref.read(feesConfigRepositoryProvider).fetchGroups();
      final seen = <String, FeesGroup>{};
      for (final g in groups) {
        final existing = seen[g.name];
        if (existing == null || g.id > existing.id) seen[g.name] = g;
      }
      final deduped = seen.values.toList()..sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _feeGroups = deduped;
        _grpLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _grpLoading = false);
    }
  }

  // ── Derived data ─────────────────────────────────────────────────────────

  List<DueStudent> get _allStudents => _groups.expand((g) => g.students).toList();
  int get _pendingCount => _allStudents.where((s) => !_applied.contains(s.id)).length;
  int get _resolvedCount => _applied.length;
  double get _collected => double.tryParse(_summary?.totalPaid ?? '0') ?? 0;
  double get _outstanding => double.tryParse(_summary?.totalDue ?? '0') ?? 0;
  double get _concessions => double.tryParse(_summary?.totalConcession ?? '0') ?? 0;

  // ── Actions ──────────────────────────────────────────────────────────────

  void _applyOne(DueStudent st) {
    final res = _resolutions[st.id] ?? 'carry';
    final allOpts = [for (final g in _resolutionGroups) ...g.$2];
    final match = allOpts.where((o) => o.$1 == res);
    final label = match.isEmpty ? '' : match.first.$2;
    setState(() => _applied.add(st.id));
    _showToast('$label — applied for ${st.name}.');
  }

  void _carryAllForward() {
    final all = _allStudents;
    setState(() => _applied.addAll(all.map((s) => s.id)));
    _showToast('Carried forward dues for all ${all.length} students.');
  }

  Future<void> _openEditModal(int groupId, String groupName) {
    return FyEditAmountsDialog.show(context, groupId: groupId, groupName: groupName, onToast: _showToast);
  }

  Future<void> _exportCsv(String reportType, String reportName) async {
    setState(() => _csvLoading = reportType);
    try {
      final bytes = await ref.read(feesYearEndRepositoryProvider).fetchReportCsv(reportType);
      await saveBytesForDownload(bytes: bytes, filename: '$reportType.csv');
      _showToast('$reportName CSV downloaded.');
    } catch (e, st) {
      debugPrint('exportCSV failed: $e\n$st');
      _showToast('Failed to export CSV. Please try again.');
    } finally {
      if (mounted) setState(() => _csvLoading = '');
    }
  }

  Future<void> _generatePdf(String reportName, String reportType) async {
    setState(() => _pdfLoading = reportType);
    try {
      await shareYearEndReportPdf(
        reportName: reportName,
        reportType: reportType,
        groups: _groups,
        allStudents: _allStudents,
        collected: _collected,
        outstanding: _outstanding,
        concessions: _concessions,
      );
      _showToast('$reportName PDF downloaded.');
    } catch (e, st) {
      debugPrint('generatePDF failed: $e\n$st');
      _showToast('Failed to generate PDF.');
    } finally {
      if (mounted) setState(() => _pdfLoading = '');
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FeesLayout(
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCarryForwardCard(),
                  const SizedBox(height: 20),
                  _buildReportsCard(),
                  const SizedBox(height: 20),
                  _buildWizardCard(),
                ],
              ),
            ),
            if (_toast != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 28, offset: Offset(0, 8))]),
                    child: Text(_toast!, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 12,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('ACADEMIC YEAR CLOSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: fyPurple)),
            SizedBox(height: 5),
            Text('Year-End', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: fyInk1, height: 1.1)),
            SizedBox(height: 6),
            Text('Resolve carry-forward dues, generate reports, and roll fee structures into the next academic year.', style: TextStyle(fontSize: 14, color: fyInk3)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x406D4AFF), blurRadius: 10, offset: Offset(0, 2))]),
            child: ElevatedButton(
              onPressed: () => _showToast('Year-end review saved.'),
              style: ElevatedButton.styleFrom(
                backgroundColor: fyPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              child: const Text('Save Year-End Review'),
            ),
          ),
        ),
      ],
    );
  }

  // ── Carry Forward ─────────────────────────────────────────────────────

  Widget _buildCarryForwardCard() {
    final students = _allStudents;
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: fyBorder), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: fyBorder))),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Carry Forward ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fyInk1)),
                        Text('2024-25 outstanding balances', style: TextStyle(fontSize: 12.5, color: fyInk3, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_pendingCount pending resolution', style: const TextStyle(fontSize: 12.5, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                        const Text('  ·  ', style: TextStyle(fontSize: 12.5, color: fyBorder)),
                        Text('$_resolvedCount resolved', style: const TextStyle(fontSize: 12.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                _carryAllButton(height: 34, fontSize: 13, padding: 16, radius: 8),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(color: Color(0xFFFAFAFF), border: Border(bottom: BorderSide(color: fyBorder))),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_pendingCount pending', style: const TextStyle(fontSize: 12.5, color: fyInk1, fontWeight: FontWeight.w600)),
                    const Text('  ·  ', style: TextStyle(fontSize: 12.5, color: fyBorder)),
                    Text('$_resolvedCount resolved', style: const TextStyle(fontSize: 12.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                  ],
                ),
                _carryAllButton(height: 26, fontSize: 12, padding: 12, radius: 6),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Loading outstanding balances…', style: TextStyle(color: fyInk3, fontSize: 14))),
            )
          else if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('✓ No outstanding dues — all balances resolved.', style: TextStyle(color: Color(0xFF16A34A), fontSize: 14, fontWeight: FontWeight.w600))),
            )
          else
            _carryForwardTable(students),
        ],
      ),
    );
  }

  Widget _carryAllButton({required double height, required double fontSize, required double padding, required double radius}) {
    final disabled = _pendingCount == 0;
    return ElevatedButton(
      onPressed: disabled ? null : _carryAllForward,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: fyPurple,
        disabledBackgroundColor: Colors.white,
        disabledForegroundColor: fyPurple.withValues(alpha: 0.5),
        elevation: 0,
        minimumSize: Size(0, height),
        padding: EdgeInsets.symmetric(horizontal: padding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: BorderSide(color: fyPurpleBorder.withValues(alpha: disabled ? 0.5 : 1))),
        textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      child: const Text('Carry all forward →'),
    );
  }

  static const _colCheck = 44.0;
  static const _colStudent = 190.0;
  static const _colOutstanding = 120.0;
  static const _colStatus = 110.0;
  static const _colResolution = 230.0;
  static const _colAction = 100.0;
  static const _cfTableWidth = _colCheck + _colStudent + _colOutstanding + _colStatus + _colResolution + _colAction + 40;

  Widget _carryForwardTable(List<DueStudent> students) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _cfTableWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: const Color(0xFFF8F8FB),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: _colCheck, child: Checkbox(value: false, onChanged: null)),
                  const SizedBox(width: _colStudent, child: Text('STUDENT', style: fyThStyle)),
                  const SizedBox(width: _colOutstanding, child: Text('OUTSTANDING', style: fyThStyle)),
                  const SizedBox(width: _colStatus, child: Text('STATUS', style: fyThStyle)),
                  const SizedBox(width: _colResolution, child: Text('RESOLUTION', style: fyThStyle)),
                  const SizedBox(width: _colAction, child: Text('ACTION', style: fyThStyle)),
                ],
              ),
            ),
            for (var i = 0; i < students.length; i++) _carryForwardRow(students[i], i < students.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _carryForwardRow(DueStudent st, bool hasDivider) {
    final isApplied = _applied.contains(st.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isApplied ? const Color(0xFFF0FDF4) : Colors.white,
        border: Border(bottom: hasDivider ? const BorderSide(color: fyBorder) : BorderSide.none),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _colCheck, child: Checkbox(value: false, onChanged: isApplied ? null : (_) {})),
          SizedBox(
            width: _colStudent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(st.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fyInk1), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Class ${st.cls}', style: const TextStyle(fontSize: 12, color: fyInk3)),
              ],
            ),
          ),
          SizedBox(width: _colOutstanding, child: Text('₹${groupIndian((double.tryParse(st.amountDue) ?? 0).round().toString())}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)))),
          SizedBox(
            width: _colStatus,
            child: isApplied
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Resolved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                  ),
          ),
          SizedBox(
            width: _colResolution,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DropdownButtonFormField<String>(
                initialValue: _resolutions[st.id] ?? 'carry',
                isExpanded: true,
                onChanged: isApplied ? null : (v) => setState(() => _resolutions[st.id] = v ?? 'carry'),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: fyBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: fyBorder)),
                ),
                style: const TextStyle(fontSize: 13, color: fyInk1),
                selectedItemBuilder: (context) => [
                  for (final grp in _resolutionGroups) ...[
                    const SizedBox.shrink(),
                    for (final opt in grp.$2)
                      Align(alignment: Alignment.centerLeft, child: Text(opt.$2, style: const TextStyle(fontSize: 13, color: fyInk1), overflow: TextOverflow.ellipsis)),
                  ],
                ],
                items: [
                  for (final grp in _resolutionGroups) ...[
                    DropdownMenuItem(
                      enabled: false,
                      value: '__group_${grp.$1}',
                      child: Text(grp.$1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fyInk1)),
                    ),
                    for (final opt in grp.$2)
                      DropdownMenuItem(
                        value: opt.$1,
                        child: Padding(padding: const EdgeInsets.only(left: 14), child: Text(opt.$2, style: const TextStyle(fontSize: 13, color: fyInk1))),
                      ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: _colAction,
            child: ElevatedButton(
              onPressed: isApplied ? null : () => _applyOne(st),
              style: ElevatedButton.styleFrom(
                backgroundColor: fyPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF3F4F6),
                disabledForegroundColor: const Color(0xFF9CA3AF),
                elevation: 0,
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: Text(isApplied ? '✓ Applied' : 'Apply'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Year-End Reports ─────────────────────────────────────────────────

  Widget _buildReportsCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: fyBorder), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: fyBorder))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Year-End Reports', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fyInk1)),
                SizedBox(height: 3),
                Text('Generate PDF or CSV for audit, board review, and statutory filing.', style: TextStyle(fontSize: 13, color: fyInk3)),
              ],
            ),
          ),
          for (var i = 0; i < _reports.length; i++) _reportRow(_reports[i].$1, _reports[i].$2, i < _reports.length - 1),
        ],
      ),
    );
  }

  Widget _reportRow(String name, String type, bool hasDivider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: hasDivider ? const BorderSide(color: fyBorder) : BorderSide.none)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fyInk1)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FyOutlineButton(label: _pdfLoading == type ? 'Generating…' : 'Generate PDF', onPressed: _pdfLoading == type ? null : () => _generatePdf(name, type)),
              const SizedBox(width: 8),
              FyOutlineButton(label: _csvLoading == type ? 'Exporting…' : 'Export CSV', onPressed: _csvLoading == type ? null : () => _exportCsv(type, name)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Archive & Rollover wizard ────────────────────────────────────────

  Widget _buildWizardCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: fyBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Archive & Rollover', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fyInk1)),
                    const SizedBox(width: 8),
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: fyPurpleTint, border: Border.all(color: fyPurpleBorder, width: 1.5)),
                      child: const Text('!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fyPurple, height: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Step-through wizard with confirmation gates.', style: TextStyle(fontSize: 12, color: fyInk3)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < _wizardSteps.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Opacity(
                          opacity: _wizardSteps[i].$1 < _wizardStep ? 0.5 : 1,
                          child: Container(
                            height: _wizardSteps[i].$1 == _wizardStep ? 5 : 3,
                            decoration: BoxDecoration(
                              color: _wizardSteps[i].$1 <= _wizardStep ? fyPurple : fyBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _wizardSteps.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_wizardSteps[i].$1}. ${_wizardSteps[i].$2}',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: _wizardSteps[i].$1 == _wizardStep ? FontWeight.w700 : FontWeight.w400,
                            color: _wizardSteps[i].$1 == _wizardStep ? fyPurple : fyInk3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            decoration: BoxDecoration(border: Border.all(color: fyBorder), borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: _wizardStepContent(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _wizardStep == 1 ? null : () => setState(() => _wizardStep -= 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: fyInk1,
                      disabledBackgroundColor: Colors.white,
                      disabledForegroundColor: fyInk1.withValues(alpha: 0.4),
                      elevation: 0,
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: fyBorder, width: 1.5)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('← Back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _wizardStep == 4 ? null : const [BoxShadow(color: Color(0x4D6D4AFF), blurRadius: 10, offset: Offset(0, 2))],
                    ),
                    child: ElevatedButton(
                      onPressed: _wizardStep == 4
                          ? null
                          : () {
                              setState(() => _wizardStep += 1);
                              if (_wizardStep == 3) _maybeLoadFeeGroups();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fyPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: fyBorder,
                        disabledForegroundColor: const Color(0xFF9CA3AF),
                        elevation: 0,
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Next →'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wizardStepContent() {
    switch (_wizardStep) {
      case 1:
        return _wizardStep1();
      case 2:
        return _wizardStep2();
      case 3:
        return _wizardStep3();
      default:
        return _wizardStep4();
    }
  }

  Widget _wizardStep1() {
    final stats = [
      ('COLLECTED', _collected, const Color(0xFF16A34A)),
      ('OUTSTANDING', _outstanding, const Color(0xFFDC2626)),
      ('CONCESSIONS', _concessions < 0 ? 0.0 : _concessions, const Color(0xFF7C3AED)),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Review 2025-26 final totals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fyInk1)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFF8F8FB), border: Border.all(color: fyBorder), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Text(stats[i].$1, textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: stats[i].$3)),
                        const SizedBox(height: 5),
                        Text('Rs.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: stats[i].$3, height: 1)),
                        const SizedBox(height: 2),
                        Text(groupIndian(stats[i].$2.round().toString()), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: stats[i].$3, height: 1.2)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Text('These figures are locked for review. Confirm they match your accounts before proceeding.', style: TextStyle(fontSize: 12, color: fyInk3, height: 1.55)),
        ],
      ),
    );
  }

  Widget _wizardStep2() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Set next academic year & date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fyInk1)),
          const SizedBox(height: 14),
          const Text('NEXT ACADEMIC YEAR', style: fyFieldLabelStyle),
          const SizedBox(height: 6),
          TextField(controller: _nextYearCtrl, decoration: fyFieldDecoration(), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          const Text('ROLLOVER DATE', style: fyFieldLabelStyle),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 5));
              if (picked != null) {
                setState(() => _rolloverDateCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
              }
            },
            child: InputDecorator(
              decoration: fyFieldDecoration(),
              child: Text(_rolloverDateCtrl.text, style: const TextStyle(fontSize: 13, color: fyInk1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wizardStep3() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 11.5, color: fyInk3, height: 1.55),
              children: [
                TextSpan(text: 'Select groups to roll over, then click '),
                TextSpan(text: 'Edit Amounts', style: TextStyle(color: fyInk1, fontWeight: FontWeight.w700)),
                TextSpan(text: ' to hike fees for next year.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_grpLoading)
            const Text('Loading groups…', style: TextStyle(color: fyInk3, fontSize: 12))
          else if (_feeGroups.isEmpty)
            const Text('No fee groups found.', style: TextStyle(color: fyInk3, fontSize: 12))
          else
            Column(
              children: [
                for (final group in _feeGroups) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(border: Border.all(color: fyBorder), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        SizedBox(width: 14, height: 14, child: Checkbox(value: true, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, activeColor: fyPurple)),
                        const SizedBox(width: 8),
                        const Text('Copy', style: TextStyle(fontSize: 11.5, color: fyInk3)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(group.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fyInk1), overflow: TextOverflow.ellipsis),
                              const Text('schedules & concessions', style: TextStyle(fontSize: 10.5, color: fyInk3)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _openEditModal(group.id, group.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: fyInk1,
                            elevation: 0,
                            minimumSize: const Size(0, 28),
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: fyBorder)),
                            textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                          child: const Text('Edit Amounts'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _wizardStep4() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Execute rollover', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fyInk1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), border: Border.all(color: const Color(0xFFFCD34D)), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              '⚠️ This will archive 2025-26 and create the 2026-27 academic year. This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.6),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showToast('Rollover executed — 2026-27 created successfully.'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('Execute Rollover'),
            ),
          ),
        ],
      ),
    );
  }
}
