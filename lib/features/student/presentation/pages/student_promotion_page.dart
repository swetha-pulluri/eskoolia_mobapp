import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/models/academic_year.dart';
import '../../domain/models/promotion.dart';
import '../providers/student_providers.dart';
import '../widgets/promotion_widgets.dart';
import '../widgets/student_group_widgets.dart' show GroupPill;

/// Student Promote — full port of frontend
/// app/(dashboard)/students/promote/{page.tsx,PromotePageContainer.tsx} +
/// its components/ family (PromoteHeader, PromoteKPICards, PromoteSmartFilter,
/// ClassAccordionCard, PromoteSectionTabs, PromoteStudentTable,
/// BulkActionFooter, ConfirmBatchModal, NotPromotedDialog,
/// PromoteOverrideDialog, PromoteCircularProgress). Backend: apps/students —
/// `PromotionBatchViewSet` (fully real, transactional, audit-logged — see
/// views.py `confirm`, which is where students actually move
/// class/section/academic-year; `ai-recommendation` is a real, deterministic
/// server-side generator, not a stub).
///
/// Deviations from a literal 1:1 port (disclosed):
///  - No separate "decisions" overlay state distinct from the batch's own
///    records: every mutating action awaits the repository call and then
///    replaces the affected record(s) with the server's response, instead of
///    optimistically updating local state before the network call resolves.
///    Same end visual result, one fewer local/server divergence risk —
///    matches how the already-shipped Student Group/Multi Subject Assignment
///    screens in this app handle mutations.
///  - `persistRecord`-style calls never rethrow (they toast on error and
///    return), matching the reference's own `persistRecord`, which never
///    rejects either — so, exactly as in the reference, the Not
///    Promoted/Override dialogs close and show a "saved" toast even on a
///    failed persist (the earlier error toast is visible only briefly before
///    being overwritten) — a real, if odd, quirk of the source of truth,
///    ported rather than fixed.
///  - The accordion header wraps onto two lines on narrow widths instead of
///    the reference's single non-wrapping flex row (every chip, badge, and
///    control from the reference is still present) — required to satisfy
///    this project's no-RenderFlex-overflow mobile rule; nothing is hidden
///    or removed.
///  - No standalone "Export" action exists anywhere in the reference
///    frontend for this screen, so none is added here.
class StudentPromotionPage extends ConsumerStatefulWidget {
  const StudentPromotionPage({super.key});

  @override
  ConsumerState<StudentPromotionPage> createState() => _StudentPromotionPageState();
}

class _SectionGroup {
  final String key;
  final int? sectionId;
  final String sectionName;
  final List<PromotionRecord> records;
  const _SectionGroup({required this.key, required this.sectionId, required this.sectionName, required this.records});
}

class _ClassGroup {
  final String classKey;
  final int? classId;
  final String className;
  final List<_SectionGroup> sections;
  const _ClassGroup({required this.classKey, required this.classId, required this.className, required this.sections});
  int get totalRecords => sections.fold(0, (s, sec) => s + sec.records.length);
}

List<_ClassGroup> _groupByClass(List<PromotionRecord> records) {
  final classNames = <String, String>{};
  final classIds = <String, int?>{};
  final sectionNames = <String, Map<String, String>>{};
  final sectionIds = <String, Map<String, int?>>{};
  final buckets = <String, Map<String, List<PromotionRecord>>>{};

  for (final r in records) {
    final ckey = r.fromClassId == null ? 'unassigned' : '${r.fromClassId}';
    classNames.putIfAbsent(ckey, () => promoteFormatClassLabel(r.fromClassName));
    classIds.putIfAbsent(ckey, () => r.fromClassId);
    final skey = r.fromSectionId == null ? 'no-section' : '${r.fromSectionId}';
    (sectionNames[ckey] ??= {}).putIfAbsent(skey, () => r.fromSectionName.isNotEmpty ? r.fromSectionName : '—');
    (sectionIds[ckey] ??= {}).putIfAbsent(skey, () => r.fromSectionId);
    (buckets[ckey] ??= {}).putIfAbsent(skey, () => []).add(r);
  }

  final groups = buckets.entries.map((entry) {
    final ckey = entry.key;
    final sections = entry.value.entries
        .map((se) => _SectionGroup(key: se.key, sectionId: sectionIds[ckey]![se.key], sectionName: sectionNames[ckey]![se.key]!, records: se.value))
        .toList()
      ..sort((a, b) => a.sectionName.compareTo(b.sectionName));
    return _ClassGroup(classKey: ckey, classId: classIds[ckey], className: classNames[ckey]!, sections: sections);
  }).toList()
    ..sort((a, b) {
      final d = promoteClassRank(a.className) - promoteClassRank(b.className);
      return d != 0 ? d : a.className.compareTo(b.className);
    });
  return groups;
}

class _NotPromotedResult {
  final String reason;
  final String notes;
  const _NotPromotedResult(this.reason, this.notes);
}

class _StudentPromotionPageState extends ConsumerState<StudentPromotionPage> {
  List<AcademicYear> _years = [];
  bool _loadingYears = true;
  int? _fromYearId;
  int? _toYearId;

  PromotionBatch? _batch;
  bool _loadingBatch = false;

  Map<int, PromotionRecord> _liveRecords = {};
  Set<int> _selectedIds = {};

  String _classKey = 'all';
  String _sectionKey = 'all';
  String _statusFilter = 'all'; // all | pending | promote | not_promoted
  final _searchController = TextEditingController();
  String _searchActive = '';

  final Map<String, bool> _expanded = {};

  ({String tone, String message})? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String tone, String message) {
    _toastTimer?.cancel();
    setState(() => _toast = (tone: tone, message: message));
    _toastTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _loadYears() async {
    try {
      final years = await ref.read(studentRepositoryProvider).fetchAcademicYears();
      final filtered = years.where((y) => RegExp(r'^\d{4}-\d{4}$').hasMatch(y.name.trim())).toList();
      if (!mounted) return;
      setState(() {
        _years = filtered;
        _loadingYears = false;
        final current = filtered.where((y) => y.isCurrent).firstOrNull;
        if (current != null) {
          _fromYearId = current.id;
          final startYear = int.tryParse(current.name.trim().split('-').first) ?? 0;
          if (startYear > 0) {
            final nextName = '${startYear + 1}-${startYear + 2}';
            final next = filtered.where((y) => y.name.trim() == nextName).firstOrNull;
            if (next != null) _toYearId = next.id;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingYears = false);
    }
  }

  Future<void> _loadBatch() async {
    if (_fromYearId == null || _toYearId == null) return;
    if (_fromYearId == _toYearId) {
      _showToast('error', 'From and To academic years must be different.');
      return;
    }
    setState(() => _loadingBatch = true);
    try {
      final batch = await ref.read(promotionRepositoryProvider).createOrGetBatch(academicYearId: _fromYearId!, targetYearId: _toYearId!);
      if (!mounted) return;
      setState(() {
        _batch = batch;
        _liveRecords = {for (final r in batch.records) r.id: r};
        _selectedIds = {};
        _expanded.clear();
        _classKey = 'all';
        _sectionKey = 'all';
        _statusFilter = 'all';
        _searchController.clear();
        _searchActive = '';
        _loadingBatch = false;
        _autoExpandFirstIfNone();
      });
      _showToast('success', 'Batch loaded · ${batch.records.length} students');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingBatch = false);
      _showToast('error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  bool get _isReadOnly => _batch?.status == 'confirmed' || _batch?.status == 'finalized';

  List<PromotionRecord> get _allRecords => _liveRecords.values.toList();

  List<({String key, String label})> get _classOptions {
    if (_batch == null) return const [];
    final map = <String, String>{};
    for (final r in _allRecords) {
      final key = r.fromClassId == null ? 'unassigned' : '${r.fromClassId}';
      map.putIfAbsent(key, () => promoteFormatClassLabel(r.fromClassName));
    }
    final list = map.entries.map((e) => (key: e.key, label: e.value)).toList();
    list.sort((a, b) {
      final d = promoteClassRank(a.label) - promoteClassRank(b.label);
      return d != 0 ? d : a.label.compareTo(b.label);
    });
    return list;
  }

  List<({String key, String label})> get _sectionOptions {
    if (_batch == null || _classKey == 'all') return const [];
    final map = <String, String>{};
    for (final r in _allRecords) {
      final ckey = r.fromClassId == null ? 'unassigned' : '${r.fromClassId}';
      if (ckey != _classKey) continue;
      final skey = r.fromSectionId == null ? 'no-section' : '${r.fromSectionId}';
      map.putIfAbsent(skey, () => r.fromSectionName.isNotEmpty ? r.fromSectionName : 'No section');
    }
    return map.entries.map((e) => (key: e.key, label: e.value)).toList();
  }

  List<PromotionRecord> get _filteredRecords {
    final q = _searchActive.trim().toLowerCase();
    return _allRecords.where((r) {
      if (_statusFilter != 'all' && r.status != _statusFilter) return false;
      final ckey = r.fromClassId == null ? 'unassigned' : '${r.fromClassId}';
      if (_classKey != 'all' && ckey != _classKey) return false;
      if (_classKey != 'all' && _sectionKey != 'all') {
        final skey = r.fromSectionId == null ? 'no-section' : '${r.fromSectionId}';
        if (skey != _sectionKey) return false;
      }
      if (q.isNotEmpty) {
        final hay = '${r.studentName} ${r.admissionNo} ${r.fromClassName} ${r.fromSectionName}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<_ClassGroup> get _classGroups => _groupByClass(_filteredRecords);

  ({int total, int promoted, int notPromoted, int pending, int completionPct})? get _liveKpi {
    if (_batch == null) return null;
    var promoted = 0, notPromoted = 0, pending = 0;
    for (final r in _allRecords) {
      if (r.status == 'promote') {
        promoted++;
      } else if (r.status == 'not_promoted') {
        notPromoted++;
      } else {
        pending++;
      }
    }
    final total = _allRecords.length;
    final decided = promoted + notPromoted;
    return (total: total, promoted: promoted, notPromoted: notPromoted, pending: pending, completionPct: total > 0 ? ((decided / total) * 100).round() : 0);
  }

  void _autoExpandFirstIfNone() {
    final groups = _classGroups;
    if (groups.isEmpty) return;
    if (_expanded.values.any((v) => v)) return;
    _expanded[groups.first.classKey] = true;
  }

  Future<void> _persistRecord(int recordId, {required String status, String? retentionReason, String? notes}) async {
    if (_batch == null) return;
    try {
      final updated = await ref.read(promotionRepositoryProvider).updateRecord(
            _batch!.id,
            recordId: recordId,
            status: status,
            retentionReason: retentionReason,
            notes: notes,
          );
      if (!mounted) return;
      setState(() => _liveRecords[recordId] = updated);
    } catch (e) {
      if (!mounted) return;
      _showToast('error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleStatusChange(int recordId, String newStatus) async {
    if (newStatus == 'not_promoted') return; // handled via NotPromotedDialog by the caller
    final current = _liveRecords[recordId];
    if (newStatus == 'promote' && current?.status == 'not_promoted') {
      if (current != null) _openOverrideDialog(current);
      return;
    }
    await _persistRecord(recordId, status: newStatus, retentionReason: '', notes: '');
  }

  Future<void> _openOverrideDialog(PromotionRecord record) async {
    final note = await showDialog<String>(context: context, builder: (_) => _PromoteOverrideDialog(record: record));
    if (note == null) return;
    await _persistRecord(record.id, status: 'promote', retentionReason: '', notes: note);
    _showToast('success', 'Override saved — student will be promoted.');
  }

  Future<void> _openNotPromotedDialog(PromotionRecord record) async {
    if (_batch == null) return;
    final result = await showDialog<_NotPromotedResult>(
      context: context,
      builder: (_) => _NotPromotedDialog(
        record: record,
        onGenerateAi: (reason) => ref.read(promotionRepositoryProvider).aiRecommendation(_batch!.id, recordId: record.id, reason: reason),
      ),
    );
    if (result == null) return;
    await _persistRecord(record.id, status: 'not_promoted', retentionReason: result.reason, notes: result.notes);
    _showToast('success', 'Retention reason saved.');
  }

  void _handleSelect(int recordId, bool checked) {
    setState(() {
      if (checked) {
        _selectedIds.add(recordId);
      } else {
        _selectedIds.remove(recordId);
      }
    });
  }

  void _handleSelectMany(List<int> ids, bool checked) {
    setState(() {
      if (checked) {
        _selectedIds.addAll(ids);
      } else {
        _selectedIds.removeAll(ids);
      }
    });
  }

  Future<void> _bulkApply(List<PromotionRecord> records, String action) async {
    if (_batch == null || records.isEmpty) return;
    try {
      final refreshed = await ref.read(promotionRepositoryProvider).bulkUpdate(
            _batch!.id,
            action: action,
            scope: 'selection',
            recordIds: records.map((r) => r.id).toList(),
          );
      if (!mounted) return;
      setState(() {
        _batch = refreshed;
        _liveRecords = {for (final r in refreshed.records) r.id: r};
        _selectedIds = {};
      });
      _showToast('success', '${records.length} record${records.length == 1 ? '' : 's'} updated');
    } catch (e) {
      if (!mounted) return;
      _showToast('error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handlePromoteAll(List<PromotionRecord> records) {
    final eligible = records.where((r) => r.status == 'pending').toList();
    if (eligible.isEmpty) {
      _showToast('info', 'No pending students to promote in this section.');
      return;
    }
    _bulkApply(eligible, 'promote');
  }

  void _handleNotPromotedAll(List<PromotionRecord> records) {
    final eligible = records.where((r) => r.status == 'pending').toList();
    if (eligible.isEmpty) {
      _showToast('info', 'No pending students left in this section.');
      return;
    }
    _bulkApply(eligible, 'skip');
  }

  void _handleResetAll(List<PromotionRecord> records) => _bulkApply(records, 'reset');

  Future<void> _openConfirmDialog() async {
    final kpi = _liveKpi;
    if (_batch == null || kpi == null) return;
    await showDialog<void>(
      context: context,
      builder: (dctx) => _ConfirmBatchDialog(
        promoted: kpi.promoted,
        notPromoted: kpi.notPromoted,
        pending: kpi.pending,
        targetYearName: _batch!.targetYearName,
        onConfirm: () async {
          final refreshed = await ref.read(promotionRepositoryProvider).confirmBatch(_batch!.id);
          if (!mounted) return;
          setState(() {
            _batch = refreshed;
            _liveRecords = {for (final r in refreshed.records) r.id: r};
          });
          if (dctx.mounted) Navigator.of(dctx).pop();
          _showToast('success', 'Batch confirmed — students promoted.');
        },
      ),
    );
  }

  Future<void> _handleFinalize() async {
    if (_batch == null) return;
    try {
      final refreshed = await ref.read(promotionRepositoryProvider).finalizeBatch(_batch!.id);
      if (!mounted) return;
      setState(() {
        _batch = refreshed;
        _liveRecords = {for (final r in refreshed.records) r.id: r};
      });
      _showToast('success', 'Batch finalized.');
    } catch (e) {
      if (!mounted) return;
      _showToast('error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), border: Border.all(color: const Color(0xFFDFDFEA)), borderRadius: BorderRadius.circular(16)),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          PromoteToast(toast: _toast),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final batch = _batch;
    final kpi = _liveKpi;
    final groups = _classGroups;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(batch),
        if (batch != null) ...[
          const SizedBox(height: 4),
          _buildStatusRow(batch, kpi!),
          const SizedBox(height: 16),
          _buildKpis(kpi),
          const SizedBox(height: 16),
          _PromoteSmartFilterPanel(
            classOptions: _classOptions,
            sectionOptions: _sectionOptions,
            appliedClass: _classKey,
            appliedSection: _sectionKey,
            appliedStatus: _statusFilter,
            searchController: _searchController,
            onSearchSubmit: () => setState(() {
              _searchActive = _searchController.text;
              _autoExpandFirstIfNone();
            }),
            onApply: (cls, sec, status) => setState(() {
              _classKey = cls;
              _sectionKey = sec;
              _statusFilter = status;
              _autoExpandFirstIfNone();
            }),
            onReset: () => setState(() {
              _classKey = 'all';
              _sectionKey = 'all';
              _statusFilter = 'all';
              _searchController.clear();
              _searchActive = '';
              _autoExpandFirstIfNone();
            }),
          ),
          const SizedBox(height: 16),
          if (groups.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(16)),
              child: const Text('No students match the current filters.', style: TextStyle(fontSize: 13, color: Color(0xFF6B6B7B))),
            )
          else
            Column(
              children: [
                for (final g in groups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ClassAccordionCard(
                      group: g,
                      isOpen: _expanded[g.classKey] ?? false,
                      isReadOnly: _isReadOnly,
                      liveRecords: _liveRecords,
                      selectedIds: _selectedIds,
                      onToggle: () => setState(() => _expanded[g.classKey] = !(_expanded[g.classKey] ?? false)),
                      onSelect: _handleSelect,
                      onSelectMany: _handleSelectMany,
                      onStatusChange: _handleStatusChange,
                      onOpenNotPromoted: _openNotPromotedDialog,
                      onPromoteAll: _handlePromoteAll,
                      onNotPromotedAll: _handleNotPromotedAll,
                      onResetAll: _handleResetAll,
                    ),
                  ),
              ],
            ),
        ] else if (!_loadingBatch)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC), style: BorderStyle.solid), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Color(0xFF4729F4), size: 24),
                ),
                const SizedBox(height: 12),
                const Text('Start a promotion batch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
                const SizedBox(height: 4),
                const Text(
                  'Select the source and target academic years, then click Load batch to begin reviewing students.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B6B7B)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(PromotionBatch? batch) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 16,
      runSpacing: 12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.4, color: const Color(0xFF0F172A)),
                  children: [
                    const TextSpan(text: 'Student '),
                    TextSpan(text: 'Promote', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: const Color(0xFF6C3CE1))),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage year-end promotions${batch != null ? ' · ${batch.records.length} students' : ''}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B80)),
              ),
            ],
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _yearField('From', _fromYearId, (v) => setState(() => _fromYearId = v)),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA0AE)),
            _yearField('To', _toYearId, (v) => setState(() => _toYearId = v)),
            ElevatedButton(
              onPressed: (_loadingYears || _loadingBatch || _fromYearId == null || _toYearId == null) ? null : _loadBatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4729F4),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF4729F4).withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text((_loadingYears || _loadingBatch) ? 'Loading…' : 'Load batch', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _yearField(String label, int? value, ValueChanged<int?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B6B80))),
        const SizedBox(width: 6),
        SizedBox(
          width: 118,
          child: AppDropdown<int>(
            value: value,
            height: 34,
            fontSize: 13,
            hint: const Text('Select year', style: TextStyle(fontSize: 13)),
            items: _years.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name))).toList(),
            onChanged: _loadingYears ? null : onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(PromotionBatch batch, ({int total, int promoted, int notPromoted, int pending, int completionPct}) kpi) {
    final (bg, fg) = switch (batch.status) {
      'finalized' => (const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
      'confirmed' => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      'in_progress' => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      _ => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(batch.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: fg)),
          ]),
        ),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B7B)),
            children: [
              TextSpan(text: '${batch.academicYearName} → '),
              TextSpan(text: batch.targetYearName, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
            ],
          ),
        ),
        if (batch.status != 'confirmed' && batch.status != 'finalized')
          ElevatedButton(
            onPressed: kpi.pending == 0 ? _openConfirmDialog : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4729F4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF4729F4).withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Confirm & Promote', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          )
        else if (batch.status == 'confirmed')
          ElevatedButton(
            onPressed: _handleFinalize,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('Finalize Batch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildKpis(({int total, int promoted, int notPromoted, int pending, int completionPct}) kpi) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 520 ? 2 : 1);
      final gap = 12.0;
      final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
      final cards = [
        PromoteKpiCard(label: 'Total Students', value: '${kpi.total}', sub: '${kpi.completionPct}% decisions completed', badgeText: 'TS', badgeBg: const Color(0xFFEEF2FF), badgeColor: const Color(0xFF4729F4)),
        PromoteKpiCard(label: 'Marked to Promote', value: '${kpi.promoted}', sub: kpi.total > 0 ? '${((kpi.promoted / kpi.total) * 100).round()}% of class' : '—', badgeText: 'PR', badgeBg: const Color(0xFFECFDF5), badgeColor: const Color(0xFF16A34A)),
        PromoteKpiCard(label: 'Not Promoted', value: '${kpi.notPromoted}', sub: kpi.notPromoted > 0 ? 'Retention reason captured' : 'No retentions yet', badgeText: 'NP', badgeBg: const Color(0xFFFFF1F2), badgeColor: const Color(0xFFE11D48)),
        PromoteKpiCard(label: 'Pending Decisions', value: '${kpi.pending}', sub: kpi.pending > 0 ? 'Awaiting review' : 'All reviewed', badgeText: 'PD', badgeBg: const Color(0xFFFFFBEB), badgeColor: const Color(0xFFD97706)),
      ];
      return Wrap(spacing: gap, runSpacing: gap, children: [for (final c in cards) SizedBox(width: w, child: c)]);
    });
  }
}

// ── Smart Filter ─────────────────────────────────────────────────────────

class _PromoteSmartFilterPanel extends StatefulWidget {
  final List<({String key, String label})> classOptions;
  final List<({String key, String label})> sectionOptions;
  final String appliedClass;
  final String appliedSection;
  final String appliedStatus;
  final TextEditingController searchController;
  final VoidCallback onSearchSubmit;
  final void Function(String cls, String sec, String status) onApply;
  final VoidCallback onReset;

  const _PromoteSmartFilterPanel({
    required this.classOptions,
    required this.sectionOptions,
    required this.appliedClass,
    required this.appliedSection,
    required this.appliedStatus,
    required this.searchController,
    required this.onSearchSubmit,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_PromoteSmartFilterPanel> createState() => _PromoteSmartFilterPanelState();
}

class _PromoteSmartFilterPanelState extends State<_PromoteSmartFilterPanel> {
  bool _open = false;
  late String _pendingClass = widget.appliedClass;
  late String _pendingSection = widget.appliedSection;
  late String _pendingStatus = widget.appliedStatus;

  static const _statusOptions = [('all', 'All'), ('pending', 'Pending'), ('promote', 'Promote'), ('not_promoted', 'Not Promoted')];

  @override
  void didUpdateWidget(covariant _PromoteSmartFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appliedClass != oldWidget.appliedClass) _pendingClass = widget.appliedClass;
    if (widget.appliedSection != oldWidget.appliedSection) _pendingSection = widget.appliedSection;
    if (widget.appliedStatus != oldWidget.appliedStatus) _pendingStatus = widget.appliedStatus;
  }

  bool get _hasChanges => _pendingClass != widget.appliedClass || _pendingSection != widget.appliedSection || _pendingStatus != widget.appliedStatus;

  int get _pendingCount => (_pendingClass != 'all' ? 1 : 0) + (_pendingSection != 'all' ? 1 : 0) + (_pendingStatus != 'all' ? 1 : 0);

  String _statusLabel(String v) => _statusOptions.firstWhere((s) => s.$1 == v, orElse: () => ('all', 'All')).$2;

  void _apply() {
    widget.onApply(_pendingClass, _pendingSection, _pendingStatus);
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final chips = <(String key, String label, VoidCallback clear)>[];
    if (widget.appliedClass != 'all') {
      final c = widget.classOptions.where((o) => o.key == widget.appliedClass).firstOrNull;
      if (c != null) {
        chips.add(('class', c.label, () => widget.onApply('all', widget.appliedSection, widget.appliedStatus)));
      }
    }
    if (widget.appliedSection != 'all') {
      final s = widget.sectionOptions.where((o) => o.key == widget.appliedSection).firstOrNull;
      if (s != null) {
        chips.add(('section', 'Sec ${s.label}', () => widget.onApply(widget.appliedClass, 'all', widget.appliedStatus)));
      }
    }
    if (widget.appliedStatus != 'all') {
      chips.add(('status', _statusLabel(widget.appliedStatus), () => widget.onApply(widget.appliedClass, widget.appliedSection, 'all')));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF9FBFF)]),
        border: Border.all(color: const Color(0xFFE2E6F0)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x141A2744), blurRadius: 18, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B894), Color(0xFF8FD3FF)]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 260),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFD0D8EC)), borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_alt_outlined, size: 15, color: Color(0xFF8FA3C8)),
                            const SizedBox(width: 9),
                            Expanded(
                              child: TextField(
                                controller: widget.searchController,
                                onSubmitted: (_) => widget.onSearchSubmit(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1A2744)),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Search student, admission no, class or section',
                                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF8FA3C8)),
                                ),
                              ),
                            ),
                            if (widget.searchController.text.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  widget.searchController.clear();
                                  widget.onSearchSubmit();
                                },
                                child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 14, color: Color(0xFF8FA3C8))),
                              ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _open = !_open),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _open ? const Color(0xFFF0EEFF) : Colors.white,
                          border: Border.all(color: _open ? const Color(0xFF6C5CE7) : const Color(0xFFD0D8EC)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.filter_alt_outlined, size: 14, color: _open ? const Color(0xFF6C5CE7) : const Color(0xFF4A5A7A)),
                          const SizedBox(width: 5),
                          Text('Filters', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _open ? const Color(0xFF6C5CE7) : const Color(0xFF4A5A7A))),
                          if (_pendingCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: Color(0xFF6C5CE7), shape: BoxShape.circle),
                              child: Text('$_pendingCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                          if (_hasChanges) ...[const SizedBox(width: 5), Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFE67E22), shape: BoxShape.circle))],
                          const SizedBox(width: 5),
                          Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 14, color: const Color(0xFF8FA3C8)),
                        ]),
                      ),
                    ),
                    if (chips.isNotEmpty || _hasChanges)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _pendingClass = 'all';
                            _pendingSection = 'all';
                            _pendingStatus = 'all';
                          });
                          widget.onReset();
                        },
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF8FA3C8), padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: const Text('Reset all', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final c in chips)
                        Container(
                          padding: const EdgeInsets.fromLTRB(11, 5, 5, 5),
                          decoration: BoxDecoration(color: const Color(0xFF1A2744), borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(c.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 7),
                            InkWell(
                              onTap: c.$3,
                              child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            ),
                          ]),
                        ),
                    ],
                  ),
                ],
                if (_open) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0x248FA3C8)),
                  const SizedBox(height: 14),
                  _pillGroup('Decision Status', [for (final s in _statusOptions) (s.$1, s.$2)], _pendingStatus, (v) => setState(() => _pendingStatus = v)),
                  const SizedBox(height: 12),
                  _pillGroup(
                    'Class',
                    [('all', 'All'), for (final c in widget.classOptions) (c.key, c.label)],
                    _pendingClass,
                    (v) => setState(() {
                      _pendingClass = v;
                      _pendingSection = 'all';
                    }),
                  ),
                  if (_pendingClass != 'all' && widget.sectionOptions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _pillGroup('Section', [('all', 'All'), for (final s in widget.sectionOptions) (s.key, s.label)], _pendingSection, (v) => setState(() => _pendingSection = v)),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges ? const Color(0xFF6C5CE7) : const Color(0xFFD0D8EC),
                        foregroundColor: _hasChanges ? Colors.white : const Color(0xFF4A5A7A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      ),
                      child: Text(_hasChanges ? '✓ Apply Filter' : '✓ Applied', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    if (_hasChanges) ...[
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _pendingClass = widget.appliedClass;
                          _pendingSection = widget.appliedSection;
                          _pendingStatus = widget.appliedStatus;
                          _open = false;
                        }),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8FA3C8), side: const BorderSide(color: Color(0xFFE2E6F0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillGroup(String label, List<(String, String)> options, String selected, void Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final o in options) GroupPill(label: o.$2, active: selected == o.$1, onTap: () => onSelect(o.$1))]),
      ],
    );
  }
}

// ── Class accordion ──────────────────────────────────────────────────────

class _ClassAccordionCard extends StatefulWidget {
  final _ClassGroup group;
  final bool isOpen;
  final bool isReadOnly;
  final Map<int, PromotionRecord> liveRecords;
  final Set<int> selectedIds;
  final VoidCallback onToggle;
  final void Function(int, bool) onSelect;
  final void Function(List<int>, bool) onSelectMany;
  final void Function(int, String) onStatusChange;
  final void Function(PromotionRecord) onOpenNotPromoted;
  final void Function(List<PromotionRecord>) onPromoteAll;
  final void Function(List<PromotionRecord>) onNotPromotedAll;
  final void Function(List<PromotionRecord>) onResetAll;

  const _ClassAccordionCard({
    required this.group,
    required this.isOpen,
    required this.isReadOnly,
    required this.liveRecords,
    required this.selectedIds,
    required this.onToggle,
    required this.onSelect,
    required this.onSelectMany,
    required this.onStatusChange,
    required this.onOpenNotPromoted,
    required this.onPromoteAll,
    required this.onNotPromotedAll,
    required this.onResetAll,
  });

  @override
  State<_ClassAccordionCard> createState() => _ClassAccordionCardState();
}

class _ClassAccordionCardState extends State<_ClassAccordionCard> {
  late String _activeKey = widget.group.sections.isNotEmpty ? widget.group.sections.first.key : '';

  @override
  void didUpdateWidget(covariant _ClassAccordionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group.sections.every((s) => s.key != _activeKey) && widget.group.sections.isNotEmpty) {
      _activeKey = widget.group.sections.first.key;
    }
  }

  List<PromotionRecord> _liveOf(List<PromotionRecord> base) => base.map((r) => widget.liveRecords[r.id] ?? r).toList();

  @override
  Widget build(BuildContext context) {
    final allRecords = _liveOf(widget.group.sections.expand((s) => s.records).toList());
    var promoted = 0, notPromoted = 0, pending = 0;
    for (final r in allRecords) {
      if (r.status == 'promote') {
        promoted++;
      } else if (r.status == 'not_promoted') {
        notPromoted++;
      } else {
        pending++;
      }
    }
    final total = allRecords.length;

    final activeSection = widget.group.sections.where((s) => s.key == _activeKey).firstOrNull ?? (widget.group.sections.isNotEmpty ? widget.group.sections.first : null);
    final sectionRecords = activeSection != null ? _liveOf(activeSection.records) : <PromotionRecord>[];
    final sectionSelectedIds = sectionRecords.where((r) => widget.selectedIds.contains(r.id)).map((r) => r.id).toSet();
    final targetForBulk = sectionSelectedIds.isNotEmpty ? sectionRecords.where((r) => sectionSelectedIds.contains(r.id)).toList() : sectionRecords;

    final syncColor = pending == 0 && total > 0 ? const Color(0xFF0A8C5A) : (pending < total ? const Color(0xFFB4721B) : const Color(0xFFE6E6EC));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6E6EC)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: widget.isOpen ? const [BoxShadow(color: Color(0xFF4729F4), offset: Offset(-4, 0))] : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: widget.isOpen ? const Color(0xFFF8F6FF) : Colors.transparent,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        turns: widget.isOpen ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA0AE)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.group.className, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
                          Text('${widget.group.sections.length} section${widget.group.sections.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA0AE))),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final sec in widget.group.sections)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF1F1F5), borderRadius: BorderRadius.circular(4)),
                          child: Text(sec.sectionName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B6B7B))),
                        ),
                    ],
                  ),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _countBadge('$total students', const Color(0xFFFAFAFD), const Color(0xFF3A3A4A), border: const Color(0xFFE6E6EC)),
                    _countBadge('$promoted promote', const Color(0xFFE4F6ED), const Color(0xFF0A8C5A)),
                    if (notPromoted > 0) _countBadge('$notPromoted not promoted', const Color(0xFFFCE8EE), const Color(0xFFC2264E)),
                    if (pending > 0) _countBadge('$pending pending', const Color(0xFFFDF1DC), const Color(0xFFB4721B)),
                  ]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    PromoteCircularProgress(promoted: promoted, total: total),
                    const SizedBox(width: 10),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: syncColor, shape: BoxShape.circle)),
                  ]),
                ],
              ),
            ),
          ),
          if (widget.isOpen && activeSection != null)
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.group.sections.length > 1)
                    _SectionTabsRow(sections: widget.group.sections, activeKey: activeSection.key, liveRecords: widget.liveRecords, onChange: (k) => setState(() => _activeKey = k)),
                  _StudentTable(
                    records: sectionRecords,
                    selectedIds: sectionSelectedIds,
                    isReadOnly: widget.isReadOnly,
                    onSelect: widget.onSelect,
                    onSelectAll: (checked) => widget.onSelectMany(sectionRecords.map((r) => r.id).toList(), checked),
                    onStatusChange: widget.onStatusChange,
                    onOpenNotPromoted: widget.onOpenNotPromoted,
                  ),
                  _BulkActionFooter(
                    selectedCount: sectionSelectedIds.length,
                    totalRecords: sectionRecords.length,
                    isReadOnly: widget.isReadOnly,
                    onPromoteAll: () => widget.onPromoteAll(targetForBulk),
                    onNotPromotedAll: () => widget.onNotPromotedAll(targetForBulk),
                    onReset: () => widget.onResetAll(targetForBulk),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _countBadge(String text, Color bg, Color fg, {Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: border != null ? Border.all(color: border) : null),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _SectionTabsRow extends StatelessWidget {
  final List<_SectionGroup> sections;
  final String activeKey;
  final Map<int, PromotionRecord> liveRecords;
  final ValueChanged<String> onChange;
  const _SectionTabsRow({required this.sections, required this.activeKey, required this.liveRecords, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFF1F1F5)))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final sec in sections) _tab(sec),
          ],
        ),
      ),
    );
  }

  Widget _tab(_SectionGroup sec) {
    final isActive = sec.key == activeKey;
    final total = sec.records.length;
    final decided = sec.records.where((r) => (liveRecords[r.id] ?? r).status != 'pending').length;
    final isComplete = total > 0 && decided == total;
    final isPartial = total > 0 && decided > 0 && decided < total;
    final (badgeBg, badgeFg) = isComplete
        ? (const Color(0xFFDCFCE7), const Color(0xFF15803D))
        : (isPartial ? (const Color(0xFFFEF9C3), const Color(0xFF854D0E)) : (isActive ? (const Color(0xFFEEEBFF), const Color(0xFF4729F4)) : (const Color(0xFFF1F1F5), const Color(0xFF9CA0AE))));

    return InkWell(
      onTap: () => onChange(sec.key),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF4729F4) : Colors.transparent, width: 2))),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Section ${sec.sectionName}', style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? const Color(0xFF4729F4) : const Color(0xFF9CA0AE))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
              child: Text('$total', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: badgeFg)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Student table ────────────────────────────────────────────────────────

class _StudentTable extends StatelessWidget {
  final List<PromotionRecord> records;
  final Set<int> selectedIds;
  final bool isReadOnly;
  final void Function(int, bool) onSelect;
  final ValueChanged<bool> onSelectAll;
  final void Function(int, String) onStatusChange;
  final void Function(PromotionRecord) onOpenNotPromoted;

  const _StudentTable({
    required this.records,
    required this.selectedIds,
    required this.isReadOnly,
    required this.onSelect,
    required this.onSelectAll,
    required this.onStatusChange,
    required this.onOpenNotPromoted,
  });

  static const _statusPill = {
    'pending': (label: 'Pending', bg: Color(0xFFFFFBEB), fg: Color(0xFF92400E), dot: Color(0xFFD97706)),
    'promote': (label: 'Promote', bg: Color(0xFFECFDF5), fg: Color(0xFF166534), dot: Color(0xFF16A34A)),
    'not_promoted': (label: 'Not Promoted', bg: Color(0xFFFFF1F2), fg: Color(0xFF991B1B), dot: Color(0xFFDC2626)),
  };

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No students match the current filters.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA0AE)))));
    }
    var promote = 0, notPromoted = 0, pending = 0;
    for (final r in records) {
      if (r.status == 'promote') {
        promote++;
      } else if (r.status == 'not_promoted') {
        notPromoted++;
      } else {
        pending++;
      }
    }
    final allSelected = records.every((r) => selectedIds.contains(r.id));
    final someSelected = records.any((r) => selectedIds.contains(r.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F1F5)))),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              _dotStat('$promote promote', const Color(0xFF16A34A)),
              _dotStat('$notPromoted not promoted', const Color(0xFFDC2626)),
              _dotStat('$pending pending', const Color(0xFFD97706)),
              Text('${records.length} student${records.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B7B))),
              InkWell(
                onTap: () => onSelectAll(!allSelected),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Checkbox(value: allSelected, tristate: someSelected && !allSelected, onChanged: (v) => onSelectAll(v ?? false), visualDensity: VisualDensity.compact, activeColor: const Color(0xFF4729F4)),
                  const Text('Select all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3A3A4A))),
                ]),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1010,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFF1F1F5)))),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Row(children: [
                    SizedBox(width: 44),
                    SizedBox(width: 64, child: _Th('Roll')),
                    SizedBox(width: 220, child: _Th('Student name')),
                    SizedBox(width: 150, child: _Th('Class · Section')),
                    SizedBox(width: 120, child: _Th('Promote to')),
                    SizedBox(width: 170, child: _Th('Action')),
                    SizedBox(width: 220, child: _Th('Notes / remarks')),
                  ]),
                ),
                for (final rec in records) _row(rec),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dotStat(String label, Color dot) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3A3A4A))),
    ]);
  }

  Widget _row(PromotionRecord rec) {
    final pill = _statusPill[rec.status]!;
    final isSelected = selectedIds.contains(rec.id);
    final fromLabel = promoteFormatClassLabel(rec.fromClassName);
    final toLabel = promoteFormatClassLabel(rec.toClassName);
    final sectionTxt = rec.fromSectionName.isNotEmpty ? ' · ${rec.fromSectionName}' : '';
    final avBg = promoteAvatarColor(rec.studentName);

    return Container(
      decoration: BoxDecoration(color: isSelected ? const Color(0xFFF8F6FF) : Colors.transparent, border: const Border(bottom: BorderSide(color: Color(0xFFF1F1F5)))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 44, child: Checkbox(value: isSelected, onChanged: (v) => onSelect(rec.id, v ?? false), visualDensity: VisualDensity.compact, activeColor: const Color(0xFF4729F4))),
          SizedBox(width: 64, child: Text(rec.admissionNo, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF6B6B7B)))),
          SizedBox(
            width: 220,
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: avBg, shape: BoxShape.circle),
                child: Text(promoteInitials(rec.studentName), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(rec.studentName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14)), overflow: TextOverflow.ellipsis),
                    Text('$fromLabel$sectionTxt', style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA0AE)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ]),
          ),
          SizedBox(width: 150, child: Text('$fromLabel$sectionTxt', style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A4A)), overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), border: Border.all(color: const Color(0xFFA7F3D0)), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.arrow_outward_rounded, size: 12, color: Color(0xFF0F766E)),
                const SizedBox(width: 4),
                Flexible(child: Text(toLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)), overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
          SizedBox(
            width: 170,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isReadOnly
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: pill.bg, borderRadius: BorderRadius.circular(999)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: pill.dot, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(pill.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pill.fg)),
                      ]),
                    )
                  : Container(
                      decoration: BoxDecoration(color: pill.bg, border: Border.all(color: pill.dot.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: rec.status,
                          isDense: true,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          dropdownColor: Colors.white,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pill.fg),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('⧗ Pending')),
                            DropdownMenuItem(value: 'promote', child: Text('✓ Promote')),
                            DropdownMenuItem(value: 'not_promoted', child: Text('✗ Not Promoted')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            if (v == 'not_promoted') {
                              onOpenNotPromoted(rec);
                            } else {
                              onStatusChange(rec.id, v);
                            }
                          },
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: 220,
            child: rec.status == 'not_promoted'
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFFF1F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          rec.retentionReason.isNotEmpty ? rec.retentionReason.replaceAll('_', ' ') : 'No reason set',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!isReadOnly)
                      IconButton(
                        onPressed: () => onOpenNotPromoted(rec),
                        icon: const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF6B6B7B)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: 'Edit retention details',
                      ),
                  ])
                : const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFFC8C8D4))),
          ),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  const _Th(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF9CA0AE))),
      );
}

// ── Bulk action footer ───────────────────────────────────────────────────

class _BulkActionFooter extends StatelessWidget {
  final int selectedCount;
  final int totalRecords;
  final bool isReadOnly;
  final VoidCallback onPromoteAll;
  final VoidCallback onNotPromotedAll;
  final VoidCallback onReset;

  const _BulkActionFooter({
    required this.selectedCount,
    required this.totalRecords,
    required this.isReadOnly,
    required this.onPromoteAll,
    required this.onNotPromotedAll,
    required this.onReset,
  });

  Future<void> _confirmReset(BuildContext context, String scope) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Reset decisions?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text.rich(TextSpan(
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B7B)),
          children: [
            TextSpan(text: 'All $scope will be set back to '),
            const TextSpan(text: 'Pending', style: TextStyle(fontWeight: FontWeight.w700)),
            const TextSpan(text: '. Retention reasons will be cleared.'),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2264E), foregroundColor: Colors.white),
            child: const Text('Yes, Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) onReset();
  }

  @override
  Widget build(BuildContext context) {
    final scope = selectedCount > 0 ? '$selectedCount selected' : 'all $totalRecords students';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF1F1F5)))),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text.rich(TextSpan(
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B7B), fontWeight: FontWeight.w500),
            children: [const TextSpan(text: 'Bulk actions on '), TextSpan(text: scope, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0B0B14)))],
          )),
          if (isReadOnly)
            const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, size: 13, color: Color(0xFF9CA0AE)),
              SizedBox(width: 5),
              Text('Read-only', style: TextStyle(fontSize: 11, color: Color(0xFF9CA0AE), fontStyle: FontStyle.italic)),
            ])
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              _footerBtn('✓ Promote All', const Color(0xFFE4F6ED), const Color(0xFF0A8C5A), onPromoteAll),
              _footerBtn('✗ Not Promoted All', const Color(0xFFFCE8EE), const Color(0xFFC2264E), onNotPromotedAll),
              OutlinedButton(
                onPressed: () => _confirmReset(context, scope),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: const Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _footerBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(backgroundColor: bg, foregroundColor: fg, side: BorderSide(color: fg.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Confirm & Promote dialog ─────────────────────────────────────────────

class _ConfirmBatchDialog extends StatefulWidget {
  final int promoted;
  final int notPromoted;
  final int pending;
  final String targetYearName;
  final Future<void> Function() onConfirm;

  const _ConfirmBatchDialog({required this.promoted, required this.notPromoted, required this.pending, required this.targetYearName, required this.onConfirm});

  @override
  State<_ConfirmBatchDialog> createState() => _ConfirmBatchDialogState();
}

class _ConfirmBatchDialogState extends State<_ConfirmBatchDialog> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = widget.pending == 0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Confirm & Promote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
                  const SizedBox(height: 4),
                  Text.rich(TextSpan(
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B7B)),
                    children: [const TextSpan(text: 'Promote students to '), TextSpan(text: widget.targetYearName, style: const TextStyle(fontWeight: FontWeight.w700)), const TextSpan(text: '. This will commit all decisions.')],
                  )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Expanded(child: _statTile('${widget.promoted}', 'Promote', const Color(0xFF16A34A))),
                const SizedBox(width: 10),
                Expanded(child: _statTile('${widget.notPromoted}', 'Not Promoted', const Color(0xFFDC2626))),
                const SizedBox(width: 10),
                Expanded(child: _statTile('${widget.pending}', 'Pending', const Color(0xFFD97706))),
              ]),
            ),
            if (!canConfirm)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(10)),
                child: const Text('Resolve all pending decisions before confirming.', style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: (_submitting || !canConfirm) ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text(_submitting ? 'Confirming…' : '✓ Confirm & Promote'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 0.6, color: Color(0xFF6B6B7B))),
      ]),
    );
  }
}

// ── Not Promoted dialog ──────────────────────────────────────────────────

class _NotPromotedDialog extends StatefulWidget {
  final PromotionRecord record;
  final Future<String> Function(String reason) onGenerateAi;
  const _NotPromotedDialog({required this.record, required this.onGenerateAi});

  @override
  State<_NotPromotedDialog> createState() => _NotPromotedDialogState();
}

class _NotPromotedDialogState extends State<_NotPromotedDialog> {
  late String _reason = widget.record.retentionReason.isNotEmpty ? widget.record.retentionReason : 'academic';
  late final _notesController = TextEditingController(text: _stripSubjectsLine(widget.record.notes));
  late final _aiController = TextEditingController(text: widget.record.aiRecommendation);
  bool _aiLoading = false;
  String _aiError = '';
  late final Set<String> _selectedSubjects = _seedSubjects();

  static final _subjectsLineRegex = RegExp(r'^Subjects of concern:[^\n]*\n?', caseSensitive: false);

  Set<String> _seedSubjects() {
    final m = RegExp(r'Subjects of concern:\s*([^\n]+)', caseSensitive: false).firstMatch(widget.record.notes);
    if (m == null) return {};
    return m.group(1)!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  }

  String _stripSubjectsLine(String notes) => notes.replaceFirst(_subjectsLineRegex, '').trim();

  @override
  void dispose() {
    _notesController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _aiLoading = true;
      _aiError = '';
    });
    try {
      final text = await widget.onGenerateAi(_reason);
      if (!mounted) return;
      setState(() => _aiController.text = text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _confirm() {
    var mergedNotes = _notesController.text;
    if (_selectedSubjects.isNotEmpty) {
      final subjectsLine = 'Subjects of concern: ${_selectedSubjects.join(', ')}';
      final stripped = _stripSubjectsLine(_notesController.text);
      mergedNotes = stripped.isNotEmpty ? '$subjectsLine\n$stripped' : subjectsLine;
    } else {
      mergedNotes = _stripSubjectsLine(_notesController.text);
    }
    Navigator.of(context).pop(_NotPromotedResult(_reason, mergedNotes));
  }

  static const _reasons = [
    ('academic', 'Academic', 'Failed exams / performance'),
    ('attendance', 'Attendance', 'Below required threshold'),
    ('medical', 'Medical Leave', 'Prolonged health-related'),
    ('behavioral', 'Behavioral', 'Disciplinary concerns'),
    ('parent_request', 'Parent Request', 'Guardian requested retention'),
    ('other', 'Other', 'Specify in notes'),
  ];

  @override
  Widget build(BuildContext context) {
    final showSubjects = _reason == 'academic' || _reason == 'other';
    final subjectsForClass = promotionSubjectsForClass(widget.record.fromClassName);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 680, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.record.studentName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
                        Text(
                          '${widget.record.admissionNo} · ${widget.record.fromClassName.isEmpty ? '—' : widget.record.fromClassName}${widget.record.fromSectionName.isNotEmpty ? ' · ${widget.record.fromSectionName}' : ''}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(999)),
                    child: const Text('NOT PROMOTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('REASON FOR RETENTION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF6B6B7B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in _reasons)
                          SizedBox(
                            width: 200,
                            child: InkWell(
                              onTap: () => setState(() => _reason = r.$1),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _reason == r.$1 ? const Color(0xFFFEF2F2) : Colors.white,
                                  border: Border.all(color: _reason == r.$1 ? const Color(0xFFDC2626) : const Color(0xFFE6E6EC), width: 1.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _RadioDot(selected: _reason == r.$1, color: const Color(0xFFDC2626)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                        Text(r.$2, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
                                        Text(r.$3, style: const TextStyle(fontSize: 10, color: Color(0xFF6B6B7B))),
                                      ]),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (showSubjects) ...[
                      const SizedBox(height: 18),
                      Text.rich(TextSpan(
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF6B6B7B)),
                        children: const [TextSpan(text: 'SUBJECTS OF CONCERN'), TextSpan(text: '  (select all that failed or are of concern)', style: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0, color: Color(0xFF9CA0AE)))],
                      )),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in subjectsForClass)
                            InkWell(
                              onTap: () => setState(() {
                                if (_selectedSubjects.contains(s)) {
                                  _selectedSubjects.remove(s);
                                } else {
                                  _selectedSubjects.add(s);
                                }
                              }),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedSubjects.contains(s) ? const Color(0xFFF1ECFF) : Colors.white,
                                  border: Border.all(color: _selectedSubjects.contains(s) ? const Color(0xFF4729F4) : const Color(0xFFE6E6EC), width: 1.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(_selectedSubjects.contains(s) ? Icons.check_box : Icons.check_box_outline_blank, size: 15, color: _selectedSubjects.contains(s) ? const Color(0xFF4729F4) : const Color(0xFF9CA0AE)),
                                  const SizedBox(width: 6),
                                  Text(s, style: TextStyle(fontSize: 11, fontWeight: _selectedSubjects.contains(s) ? FontWeight.w700 : FontWeight.w500, color: _selectedSubjects.contains(s) ? const Color(0xFF3A21D4) : const Color(0xFF3A3A4A))),
                                ]),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(children: [
                      const Expanded(child: Text('AI RECOMMENDATION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF6B6B7B)))),
                      TextButton.icon(
                        onPressed: _aiLoading ? null : _generate,
                        icon: const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF4729F4)),
                        label: Text(_aiLoading ? 'Generating…' : (_aiController.text.isNotEmpty ? 'Regenerate' : 'Generate AI'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4729F4))),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _aiController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0B0B14)),
                      decoration: InputDecoration(
                        hintText: 'Click Generate AI to draft a recommendation, or write one yourself.',
                        filled: true,
                        fillColor: const Color(0xFFFAFAFD),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE6E6EC))),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    if (_aiError.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_aiError, style: const TextStyle(fontSize: 10.5, color: Color(0xFFDC2626)))),
                    const SizedBox(height: 16),
                    const Text('INTERNAL NOTES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF6B6B7B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0B0B14)),
                      decoration: InputDecoration(
                        hintText: 'Anything else for the record (visible to teachers/admin)…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE6E6EC))),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Text('Reason & notes will be saved with this student record.', style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA0AE))),
                  Wrap(spacing: 10, runSpacing: 8, children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('✗ Confirm Not Promoted'),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Promote override dialog ──────────────────────────────────────────────

class _PromoteOverrideDialog extends StatefulWidget {
  final PromotionRecord record;
  const _PromoteOverrideDialog({required this.record});

  @override
  State<_PromoteOverrideDialog> createState() => _PromoteOverrideDialogState();
}

class _PromoteOverrideDialogState extends State<_PromoteOverrideDialog> {
  String _reasonKey = 'reviewed_records';
  final _noteController = TextEditingController();

  static const _reasons = [
    ('reviewed_records', 'Records reviewed', 'Performance / attendance re-checked and is acceptable'),
    ('remedial_completed', 'Remedial work completed', 'Student finished assigned catch-up work'),
    ('parent_appeal', 'Parent appeal accepted', 'Guardian appeal granted by school committee'),
    ('admin_decision', 'Administrative decision', 'Approved by principal / academic head'),
    ('data_correction', 'Data correction', 'Earlier "not promoted" was a data-entry mistake'),
    ('other', 'Other', 'Provide a custom message below'),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isOther => _reasonKey == 'other';
  bool get _isValid => _isOther ? _noteController.text.trim().length >= 3 : true;

  void _submit() {
    if (!_isValid) {
      setState(() {});
      return;
    }
    final reason = _reasons.firstWhere((r) => r.$1 == _reasonKey);
    final trimmed = _noteController.text.trim();
    final note = _isOther ? '[Promote override] $trimmed' : (trimmed.isNotEmpty ? '[Promote override · ${reason.$2}] $trimmed' : '[Promote override] ${reason.$2}');
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Override "Not Promoted" decision?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B7B)),
                            children: [
                              TextSpan(text: '${widget.record.studentName} ', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
                              const TextSpan(text: 'is currently marked as Not Promoted'),
                              if (widget.record.retentionReason.isNotEmpty) TextSpan(text: ' (reason: ${widget.record.retentionReason.replaceAll('_', ' ')})'),
                              const TextSpan(text: '. Please record why this is being changed.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('REASON FOR OVERRIDE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF6B6B7B))),
                    const SizedBox(height: 8),
                    for (final r in _reasons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() => _reasonKey = r.$1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _reasonKey == r.$1 ? const Color(0xFFF8F6FF) : Colors.white,
                              border: Border.all(color: _reasonKey == r.$1 ? const Color(0xFF4729F4) : const Color(0xFFE6E6EC)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _RadioDot(selected: _reasonKey == r.$1, color: const Color(0xFF4729F4)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                    Text(r.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
                                    Text(r.$3, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B6B7B))),
                                  ]),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(_isOther ? 'CUSTOM MESSAGE (REQUIRED)' : 'ADDITIONAL NOTE (OPTIONAL)', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF6B6B7B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0B0B14)),
                      decoration: InputDecoration(
                        hintText: _isOther ? 'Describe the reason for this override…' : 'Add context for audit log…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE6E6EC))),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    if (_isOther && !_isValid) const Padding(padding: EdgeInsets.only(top: 4), child: Text('A custom message of at least 3 characters is required.', style: TextStyle(fontSize: 10.5, color: Color(0xFFC2264E)))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _isValid ? _submit : null,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Confirm override'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plain circle indicator standing in for a radio-button glyph — the
/// enclosing row is already the tap target (via InkWell), so this avoids
/// Flutter's deprecated `Radio.groupValue`/`onChanged` API entirely rather
/// than triggering it for a purely decorative dot.
class _RadioDot extends StatelessWidget {
  final bool selected;
  final Color color;
  const _RadioDot({required this.selected, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? color : const Color(0xFF9CA0AE), width: 1.6)),
        child: selected ? Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)) : null,
      ),
    );
  }
}
