import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/due_student.dart';
import '../../domain/models/dues_class_group.dart';
import '../../domain/models/dues_summary.dart';
import '../providers/fees_dues_providers.dart';
import '../utils/fd_report_pdf.dart';
import '../utils/fee_assignment_format.dart' show fmtRs;
import '../utils/fees_dues_format.dart';
import '../widgets/fd_follow_up_panel.dart';
import '../widgets/fd_resolve_dialog.dart';
import '../widgets/fees_dues_styles.dart';
import '../widgets/fees_layout.dart';
import '../widgets/fees_module_sub_nav.dart';

const _tiers = [(1, 'Tier 1: 1-15 days overdue'), (2, 'Tier 2: 16-30 days overdue'), (3, 'Tier 3: 31+ days overdue')];
const _statBorders = [Color(0xFFF97316), Color(0xFFF59E0B), Color(0xFF6D4AFF), Color(0xFF16A34A)];

/// Dues & Reminders — converted from
/// `frontend/components/fees/FeesDuesRemindersPanel.tsx` (the "Dues &
/// Reminders" tab of the Fees module, `/fees/dues-reminders`). The
/// frontend is the sole source of truth for this port; see the tier tabs,
/// class-grouped student table, Late Fee Calculator preview, Follow-up
/// side panel (fd_follow_up_panel.dart), Resolve Outstanding Dues modal
/// (fd_resolve_dialog.dart), and PDF report generator (fd_report_pdf.dart).
class FeesDuesRemindersPage extends ConsumerStatefulWidget {
  const FeesDuesRemindersPage({super.key});

  @override
  ConsumerState<FeesDuesRemindersPage> createState() => _FeesDuesRemindersPageState();
}

class _FeesDuesRemindersPageState extends ConsumerState<FeesDuesRemindersPage> {
  int _activeTier = 1;
  List<DuesClassGroup> _groups = [];
  DuesSummary? _summary;
  bool _loading = true;
  Set<String> _expanded = {};
  final Set<String> _resolved = {};
  Set<String> _selSet = {};
  String? _toast;
  bool _reportLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData(_activeTier);
  }

  void _showToast(String message) {
    setState(() => _toast = message);
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted && _toast == message) setState(() => _toast = null);
    });
  }

  Future<List<DuesClassGroup>?> _tryFetchByClass(int tier) async {
    try {
      return await ref.read(feesDuesRepositoryProvider).fetchByClass(tier: tier);
    } catch (_) {
      return null;
    }
  }

  Future<DuesSummary?> _tryFetchSummary() async {
    try {
      return await ref.read(feesDuesRepositoryProvider).fetchSummary();
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchData(int tier) async {
    setState(() => _loading = true);
    final groupsFuture = _tryFetchByClass(tier);
    final summaryFuture = _tryFetchSummary();
    final groupsResult = await groupsFuture;
    final summaryResult = await summaryFuture;
    if (!mounted) return;
    setState(() {
      if (groupsResult != null) {
        _groups = groupsResult;
        _expanded = groupsResult.map((g) => g.cls).toSet();
      }
      if (summaryResult != null) _summary = summaryResult;
      _loading = false;
    });
  }

  // ── Derived data ─────────────────────────────────────────────────────────

  List<DuesClassGroup> get _filteredGroups {
    return _groups
        .map((g) => DuesClassGroup(
              cls: g.cls,
              totalStudents: g.totalStudents,
              assignedStudents: g.assignedStudents,
              students: g.students.where((s) => !_resolved.contains(s.id)).toList(),
            ))
        .where((g) => g.students.isNotEmpty)
        .toList();
  }

  List<DueStudent> get _allStudents => _filteredGroups.expand((g) => g.students).toList();

  DueStudent? get _previewStudent => _allStudents.isNotEmpty ? _allStudents.first : null;

  // ── Actions ──────────────────────────────────────────────────────────────

  void _toggleExpand(String cls) {
    setState(() => _expanded.contains(cls) ? _expanded.remove(cls) : _expanded.add(cls));
  }

  void _toggleSel(String id) {
    setState(() => _selSet.contains(id) ? _selSet.remove(id) : _selSet.add(id));
  }

  void _toggleClassSel(List<DueStudent> clsStudents, bool allSelected) {
    setState(() {
      final n = Set<String>.from(_selSet);
      for (final s in clsStudents) {
        if (allSelected) {
          n.remove(s.id);
        } else {
          n.add(s.id);
        }
      }
      _selSet = n;
    });
  }

  Future<void> _sendReminders([List<String>? ids]) async {
    final targets = ids ?? _selSet.toList();
    if (targets.isEmpty) {
      _showToast('Select students first.');
      return;
    }
    try {
      final sent = await ref.read(feesDuesRepositoryProvider).sendReminders(targets, 'Fee payment reminder from school administration.');
      _showToast('Reminder sent to $sent student(s).');
      if (mounted) setState(() => _selSet = {});
    } catch (_) {
      _showToast('Failed to send reminders.');
    }
  }

  Future<void> _openResolveModal(DueStudent student) async {
    final resolved = await FdResolveDialog.show(context, student: student, onToast: _showToast);
    if (resolved == true && mounted) {
      setState(() => _resolved.add(student.id));
    }
  }

  Future<void> _openFollowUp(DueStudent student) {
    return FdFollowUpPanel.show(context, student: student, onToast: _showToast);
  }

  Future<void> _generateReport() async {
    setState(() => _reportLoading = true);
    try {
      final tierLabel = _tiers.firstWhere((t) => t.$1 == _activeTier).$2;
      await shareDuesReportPdf(activeTier: _activeTier, tierLabel: tierLabel, summary: _summary, groups: _filteredGroups);
      _showToast('Report downloaded.');
    } catch (e, st) {
      debugPrint('generateReport failed: $e\n$st');
      _showToast('Failed to generate report.');
    } finally {
      if (mounted) setState(() => _reportLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    try {
      final bytes = await ref.read(feesDuesRepositoryProvider).exportCsv();
      final file = File('${Directory.systemTemp.path}/dues-report-${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsBytes(bytes);
      // The source's browser download is silent (no success toast) — mobile
      // has no download tray, so a success toast reporting the saved path
      // is shown here, mirroring the same disclosed necessary adaptation
      // already used by student_export_page.dart for its own file export.
      _showToast('CSV exported to ${file.path}');
    } catch (e, st) {
      debugPrint('exportCsv failed: $e\n$st');
      _showToast('Failed to export CSV.');
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FeesLayout(
      activeTab: FeesModuleTab.duesReminders,
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
                  const SizedBox(height: 24),
                  if (_summary != null) ...[_buildStats(_summary!), const SizedBox(height: 20)],
                  _buildTierTabs(),
                  const SizedBox(height: 20),
                  if (_previewStudent != null) ...[_buildLateFeePreview(_previewStudent!), const SizedBox(height: 20)],
                  _buildClassSections(),
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
            Text('COLLECTIONS FOLLOW-UP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: fdPurple)),
            SizedBox(height: 5),
            Text('Dues & Reminders', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: fdInk1, height: 1.1)),
            SizedBox(height: 6),
            Text('Escalation tiers, class-wise due lists, and a detailed interaction log for each student.', style: TextStyle(fontSize: 14, color: fdInk3)),
          ],
        ),
        Padding(padding: const EdgeInsets.only(top: 8), child: FdOutlineButton(label: 'Export CSV', onPressed: _exportCsv)),
      ],
    );
  }

  Widget _buildStats(DuesSummary summary) {
    final stats = [
      ('TOTAL OVERDUE AMOUNT', fmtRs(double.tryParse(summary.totalOverdueAmount) ?? 0), 'Across unpaid and partial records'),
      ('STUDENTS WITH DUES', '${summary.studentsWithDues}', 'Filtered by active academic year'),
      ('AVERAGE DAYS OVERDUE', '${summary.avgDaysOverdue}', 'Weighted across due students'),
      ('% COLLECTED', '${summary.pctCollected}%', 'Year-to-date collection'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: fdBorder), borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Wrap(
            children: [
              for (var i = 0; i < stats.length; i++)
                Container(
                  constraints: const BoxConstraints(minWidth: 160),
                  width: MediaQuery.of(context).size.width > 700 ? (MediaQuery.of(context).size.width - 32) / 4 : (MediaQuery.of(context).size.width - 32) / 2,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: _statBorders[i], width: 4),
                      right: BorderSide(color: fdBorder),
                      bottom: BorderSide(color: fdBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(stats[i].$1, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: fdInk3)),
                      const SizedBox(height: 10),
                      Text(stats[i].$2, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: fdInk1, height: 1.1)),
                      const SizedBox(height: 6),
                      Text(stats[i].$3, style: const TextStyle(fontSize: 12.5, color: fdInk3)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 3,
          margin: const EdgeInsets.only(top: 0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFF97316), Color(0xFFF59E0B), Color(0xFF6D4AFF), Color(0xFF16A34A)]),
          ),
        ),
      ],
    );
  }

  Widget _buildTierTabs() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in _tiers) _tierPill(t.$1, t.$2),
        FdOutlineButton(label: 'Send Reminder to All Selected', onPressed: () => _sendReminders()),
        FdOutlineButton(label: _reportLoading ? 'Generating…' : 'Generate Report', onPressed: _reportLoading ? null : _generateReport),
      ],
    );
  }

  Widget _tierPill(int n, String label) {
    final active = _activeTier == n;
    return InkWell(
      onTap: active
          ? null
          : () {
              setState(() => _activeTier = n);
              _fetchData(n);
            },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? fdPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: fdBorder),
          boxShadow: active ? const [BoxShadow(color: Color(0x386D4AFF), blurRadius: 8, offset: Offset(0, 2))] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? Colors.white : fdInk2)),
      ),
    );
  }

  Widget _buildLateFeePreview(DueStudent st) {
    final amount = double.tryParse(st.amountDue) ?? 0;
    final chargeable = st.daysOverdue - 7 < 0 ? 0 : st.daysOverdue - 7;
    final cells = [
      ('OUTSTANDING', fmtRs(amount)),
      ('DAYS OVERDUE', '${st.daysOverdue}'),
      ('CHARGEABLE DAYS', '$chargeable'),
      ('STATUS', st.status),
      ('CLASS', 'Class ${st.cls}'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: fdBorder), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Late Fee Calculator Preview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fdInk1)),
                    SizedBox(height: 3),
                    Text('Transparent penalty calculation shown before reminder, receipt, or ledger posting.', style: TextStyle(fontSize: 13, color: fdInk3)),
                  ],
                ),
              ),
              FdOutlineButton(label: 'Copy Breakdown', onPressed: () => _showToast('Breakdown copied to clipboard.')),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(border: Border.all(color: fdBorder), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${st.name} · Outstanding Fee', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fdInk1)),
                const SizedBox(height: 3),
                Text('Overdue by ${st.daysOverdue} days · Amount due: ${fmtRs(amount)}', style: const TextStyle(fontSize: 12.5, color: fdInk3)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in cells)
                      Container(
                        width: 130,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: fdBorder), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.$1, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: fdInk3)),
                            const SizedBox(height: 6),
                            Text(c.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fdInk1)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSections() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: Text('Loading dues data…', style: TextStyle(color: fdInk3, fontSize: 14))),
      );
    }
    final groups = _filteredGroups;
    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: Text('No overdue students found for this tier.', style: TextStyle(color: fdInk3, fontSize: 14))),
      );
    }
    return Column(children: [for (final g in groups) ...[_classCard(g), const SizedBox(height: 12)]]);
  }

  Widget _classCard(DuesClassGroup group) {
    final isExpanded = _expanded.contains(group.cls);
    final allSel = group.students.isNotEmpty && group.students.every((s) => _selSet.contains(s.id));
    final unassigned = group.totalStudents - group.assignedStudents < 0 ? 0 : group.totalStudents - group.assignedStudents;

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: fdBorder), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(width: 4, height: 44, decoration: BoxDecoration(color: fdPurple, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Class ${group.cls}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fdInk1)),
                      const SizedBox(height: 3),
                      Text('${group.totalStudents} students · ${group.assignedStudents} assigned · $unassigned unassigned', style: const TextStyle(fontSize: 12.5, color: fdInk3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FdOutlineButton(small: true, label: 'Remind All', onPressed: () => _sendReminders(group.students.map((s) => s.id).toList())),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)),
                  child: Text('${group.students.length} due', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _toggleExpand(group.cls),
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: fdBorder), borderRadius: BorderRadius.circular(7)),
                    child: AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.expand_more, size: 16, color: fdInk2)),
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) _studentTable(group, allSel),
        ],
      ),
    );
  }

  static const _colCheck = 44.0;
  static const _colStudent = 220.0;
  static const _colAmount = 120.0;
  static const _colDays = 110.0;
  static const _colLastReminder = 130.0;
  static const _colStatus = 140.0;
  static const _colActions = 190.0;
  static const _rowHPad = 32.0;
  static const _tableWidth = _colCheck + _colStudent + _colAmount + _colDays + _colLastReminder + _colStatus + _colActions + _rowHPad;

  Widget _studentTable(DuesClassGroup group, bool allSel) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: fdBorder))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFFF8F8FB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(width: _colCheck, child: Checkbox(value: allSel, onChanged: (_) => _toggleClassSel(group.students, allSel))),
                    const SizedBox(width: _colStudent, child: Text('STUDENT', style: fdThStyle)),
                    const SizedBox(width: _colAmount, child: Text('AMOUNT DUE', style: fdThStyle)),
                    const SizedBox(width: _colDays, child: Text('DAYS OVERDUE', style: fdThStyle)),
                    const SizedBox(width: _colLastReminder, child: Text('LAST REMINDER', style: fdThStyle)),
                    const SizedBox(width: _colStatus, child: Text('FEE STATUS', style: fdThStyle)),
                    const SizedBox(width: _colActions, child: Text('ACTIONS', style: fdThStyle)),
                  ],
                ),
              ),
              for (var i = 0; i < group.students.length; i++) _studentRow(group.students[i], i < group.students.length - 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentRow(DueStudent st, bool hasDivider) {
    final selected = _selSet.contains(st.id);
    final tier = duesTierStatus(st.daysOverdue);
    final tierStyle = duesStatusStyle[tier]!;
    return InkWell(
      onTap: () => _openFollowUp(st),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? fdPurpleTint : Colors.white,
          border: Border(bottom: hasDivider ? const BorderSide(color: fdBorder) : BorderSide.none),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _colCheck,
              child: GestureDetector(
                onTap: () {},
                child: Checkbox(value: selected, onChanged: (_) => _toggleSel(st.id)),
              ),
            ),
            SizedBox(
              width: _colStudent,
              child: Row(
                children: [
                  FdAvatar(background: duesAvatarBg(st.name), initials: _initials(st.name)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(st.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fdInk1), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${st.admNo} · Class ${st.cls}', style: const TextStyle(fontSize: 12, color: fdInk3), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _colAmount, child: Text(fmtRs(double.tryParse(st.amountDue) ?? 0), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fdInk1))),
            SizedBox(width: _colDays, child: Text('${st.daysOverdue}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: duesOverdueTextColor(st.daysOverdue)))),
            SizedBox(width: _colLastReminder, child: Text(fmtDuesDate(st.lastReminder), style: const TextStyle(fontSize: 13.5, color: fdInk2))),
            SizedBox(width: _colStatus, child: FdStatusPill(label: tier, bg: tierStyle.bg, color: tierStyle.color)),
            SizedBox(
              width: _colActions,
              child: GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    FdPrimaryButton(small: true, label: 'Resolve', onPressed: () => _openResolveModal(st)),
                    const SizedBox(width: 8),
                    FdOutlineButton(small: true, label: 'Log Call', onPressed: () => _openFollowUp(st)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts[0][0];
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return (first + second).toUpperCase();
}
