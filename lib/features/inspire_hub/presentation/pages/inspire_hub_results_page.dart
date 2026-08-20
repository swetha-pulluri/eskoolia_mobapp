import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../student/domain/models/student_group.dart';
import '../../../student/presentation/widgets/student_group_widgets.dart' show avatarColorFor, initialsOf;
import '../../domain/models/competition.dart';
import '../../domain/repositories/competitions_repository.dart';
import '../providers/inspire_hub_providers.dart';
import '../utils/inspire_hub_scope.dart';
import '../widgets/inspire_hub_competition_form.dart';

/// InspireHubResultsPage — the screen a teacher lands on right after saving
/// a competition (or reopening one from History): add participants, mark
/// positions/points, write or AI-generate a review per student, then
/// finalise. Its own dedicated page rather than a tab, so navigation
/// matches how the rest of the app moves between "list" and "detail"
/// screens. Mirrors web's ResultsEntryCards + AIReviewPanel + MiniDashboard +
/// ExportControls sitting inside the Compose tab; deliberately scoped down
/// from the reference: no multi-team sports builder (captain/vice-captain
/// squads), no confetti/keyboard shortcuts, no PDF export (CSV share only)
/// — all UX embellishments on top of the same underlying data, not part of
/// the core workflow.
class InspireHubResultsPage extends ConsumerStatefulWidget {
  final Competition competition;
  final List<StudentGroup> houses;
  final List<StudentGroup> clubs;
  final List<GroupStudentRow> allStudents;
  const InspireHubResultsPage({
    super.key,
    required this.competition,
    required this.houses,
    required this.clubs,
    required this.allStudents,
  });

  @override
  ConsumerState<InspireHubResultsPage> createState() => _InspireHubResultsPageState();
}

class _InspireHubResultsPageState extends ConsumerState<InspireHubResultsPage> {
  late Competition _competition = widget.competition;
  late List<ResultEntry> _results = List.of(widget.competition.results);
  bool _dirty = false;
  DateTime? _savedAt;
  int _aiBusy = 0;
  bool _editingForm = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleAutosave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _persistNow);
  }

  Future<void> _persistNow() async {
    final store = ref.read(inspireHubStoreProvider);
    final saved = await store.saveDraft(_competition.copyWith(results: _results));
    if (!mounted) return;
    setState(() {
      _competition = saved;
      _dirty = false;
      _savedAt = DateTime.now();
    });
  }

  void _onResultsChanged(List<ResultEntry> next) {
    setState(() {
      _results = next;
      _dirty = true;
    });
    _scheduleAutosave();
  }

  void _update(ResultEntry Function(ResultEntry r) transform, int studentId) {
    _onResultsChanged([
      for (final r in _results) if (r.studentId == studentId) transform(r) else r,
    ]);
  }

  void _addStudents(List<GroupStudentRow> students, {String position = ''}) {
    final existing = _results.map((r) => r.studentId).toSet();
    final def = positionDefFor(position);
    final additions = students.where((s) => !existing.contains(s.id)).map((s) {
      return ResultEntry(
        studentId: s.id,
        studentName: s.name,
        admissionNo: s.admissionNo,
        className: s.className,
        sectionName: s.sectionName,
        houseId: s.currentGroupId,
        houseName: s.currentGroupId != null
            ? widget.houses.where((h) => h.id == s.currentGroupId).map((h) => h.name).firstOrNull
            : null,
        clubIds: s.clubIds,
        position: position,
        points: def?.points ?? 0,
      );
    }).toList();
    if (additions.isEmpty) return;
    _onResultsChanged([..._results, ...additions]);
  }

  void _removeStudent(int studentId) {
    _onResultsChanged(_results.where((r) => r.studentId != studentId).toList());
  }

  Future<void> _onEditSubmit(Map<String, dynamic> values) async {
    final classes = List<String>.from(values['classes'] as List);
    final sections = List<String>.from(values['sections'] as List);
    final updated = _competition.copyWith(
      name: values['name'] as String,
      date: values['date'] as String,
      level: CompetitionLevel.fromValue(values['level'] as String),
      compType: CompetitionType.fromValue(values['comp_type'] as String),
      location: values['location'] as String,
      opponent: values['opponent'] as String,
      notes: values['notes'] as String,
      houseAId: values['house_a_id'] as int?,
      clearHouseA: values['house_a_id'] == null,
      houseBId: values['house_b_id'] as int?,
      clearHouseB: values['house_b_id'] == null,
      classes: classes,
      className: values['class_name'] as String,
      sections: sections,
      results: _results,
    );
    final store = ref.read(inspireHubStoreProvider);
    final saved = await store.saveDraft(updated);
    if (!mounted) return;
    setState(() {
      _competition = saved;
      _dirty = false;
      _savedAt = DateTime.now();
      _editingForm = false;
    });
  }

  Future<void> _finalize() async {
    if (_results.isEmpty) return;
    _debounce?.cancel();
    final store = ref.read(inspireHubStoreProvider);
    final finalised = await store.finalize(_competition.copyWith(results: _results));
    if (!mounted) return;
    setState(() {
      _competition = finalised;
      _dirty = false;
    });
  }

  Future<void> _deleteCurrent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this competition?'),
        content: Text('"${_competition.name}" and every result inside it will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFEE2E2), foregroundColor: const Color(0xFFB91C1C)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _debounce?.cancel();
    final store = ref.read(inspireHubStoreProvider);
    await store.remove(_competition.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveAndExit() async {
    final navigator = Navigator.of(context);
    await _persistNow();
    if (mounted) navigator.pop();
  }

  Future<bool> _confirmDiscardOrSave() async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save your progress?'),
        content: const Text('You have unsaved changes. Save them as a draft so you can finish later, or discard.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'discard'), child: const Text('Discard', style: TextStyle(color: Color(0xFFB91C1C)))),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save & exit')),
        ],
      ),
    );
    if (action == 'save') {
      await _persistNow();
      return true;
    }
    return action == 'discard';
  }

  Future<void> _tryClose() async {
    final navigator = Navigator.of(context);
    if (_dirty) {
      final should = await _confirmDiscardOrSave();
      if (should && mounted) navigator.pop();
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(competitionsRepositoryProvider);
    final scopeInfo = buildScopeInfo(_competition, widget.allStudents);
    final sorted = [..._results]
      ..sort((a, b) {
        final ra = a.position.isEmpty ? 99 : (kPositionRank[a.position] ?? 99);
        final rb = b.position.isEmpty ? 99 : (kPositionRank[b.position] ?? 99);
        if (ra != rb) return ra - rb;
        return a.studentName.compareTo(b.studentName);
      });
    final podium = sorted.where((r) => kPodiumPositions.contains(r.position)).toList();
    final others = sorted.where((r) => !kPodiumPositions.contains(r.position)).toList();

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final should = await _confirmDiscardOrSave();
        if (should && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF0F172A),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _tryClose),
          title: Text(_competition.name.isEmpty ? 'Untitled event' : _competition.name, overflow: TextOverflow.ellipsis),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (_editingForm)
              CompetitionFormCard(editing: _competition, houses: widget.houses, allStudents: widget.allStudents, onSubmit: _onEditSubmit)
            else
              _CollapsedCompetitionChip(competition: _competition, onEdit: () => setState(() => _editingForm = true)),
            const SizedBox(height: 16),
            _ParticipantPicker(
              scopeInfo: scopeInfo,
              allStudents: widget.allStudents,
              addedIds: _results.map((r) => r.studentId).toSet(),
              onAdd: (s) => _addStudents([s]),
              onBulkAdd: (list) => _addStudents(list),
            ),
            if (_results.isEmpty) ...[
              const SizedBox(height: 14),
              const _EmptyRoster(),
            ] else ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Mark results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Text(
                    '${_results.length} participants · ${_results.where((r) => r.aiResponse.isNotEmpty).length} reviewed',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (podium.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No podium participants yet.', style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)))),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < podium.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _ResultCard(
                        row: podium[i],
                        competition: _competition,
                        repository: repository,
                        onChanged: (next) => _update((_) => next, podium[i].studentId),
                        onRemove: () => _removeStudent(podium[i].studentId),
                        onAiBusyDelta: (d) => setState(() => _aiBusy = (_aiBusy + d).clamp(0, 999)),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              _OtherOutcomesSection(
                others: others,
                scopeInfo: scopeInfo,
                addedIds: _results.map((r) => r.studentId).toSet(),
                onBulkMark: (students, position) => _addStudents(students, position: position),
                onRemove: _removeStudent,
              ),
              const SizedBox(height: 12),
              _MiniDashboardSnapshot(results: _results),
              const SizedBox(height: 12),
              _ExportControls(competition: _competition, results: _results, repository: repository),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(top: false, child: _buildFooter()),
      ),
    );
  }

  Widget _buildFooter() {
    final total = _results.length;
    final positioned = _results.where((r) => r.position.isNotEmpty).length;
    final reviewed = _results.where((r) => r.aiResponse.isNotEmpty).length;
    final progressParts = <double>[
      1, // competition already exists on this page
      total > 0 ? 1 : 0,
      total == 0 ? 0 : positioned / total,
      total == 0 ? 0 : reviewed / total,
      _competition.isFinal ? 1 : 0,
    ];
    const weights = [1.0, 1.0, 2.0, 2.0, 1.0];
    var weighted = 0.0;
    var weightTotal = 0.0;
    for (var i = 0; i < progressParts.length; i++) {
      weighted += progressParts[i] * weights[i];
      weightTotal += weights[i];
    }
    final percent = weightTotal == 0 ? 0 : (weighted / weightTotal * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Progress $percent%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              if (_aiBusy > 0) ...[
                const SizedBox(width: 8),
                Text('Generating $_aiBusy…', style: const TextStyle(fontSize: 10.5, color: Color(0xFF047857))),
              ],
              const Spacer(),
              if (_competition.isFinal)
                const Text('✓ Finalised', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF047857)))
              else if (_savedAt != null)
                const Text('Saved', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percent / 100, minHeight: 5, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation(Color(0xFF0F172A))),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              IconButton(
                onPressed: _deleteCurrent,
                icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C)),
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
              ),
              TextButton(onPressed: _tryClose, child: const Text('Close')),
              OutlinedButton(onPressed: _saveAndExit, child: const Text('💾 Save & exit')),
              FilledButton(
                onPressed: (_competition.isFinal || _results.isEmpty) ? null : _finalize,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                child: Text(_competition.isFinal ? '✓ Finalised' : 'Finalise →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollapsedCompetitionChip extends StatelessWidget {
  final Competition competition;
  final VoidCallback onEdit;
  const _CollapsedCompetitionChip({required this.competition, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
            child: Text(competition.compType.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(competition.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                    if (competition.isLocal)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                        child: const Text('offline draft', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '📅 ${competition.date} · 🎯 ${competition.level.label}${competition.location.isNotEmpty ? ' · 📍 ${competition.location}' : ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('✏ Edit')),
        ],
      ),
    );
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
      child: const Text('No participants yet — search above to add a student.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Participant picker
// ═══════════════════════════════════════════════════════════════════════

class _ParticipantPicker extends StatefulWidget {
  final ScopeInfo scopeInfo;
  final List<GroupStudentRow> allStudents;
  final Set<int> addedIds;
  final ValueChanged<GroupStudentRow> onAdd;
  final ValueChanged<List<GroupStudentRow>> onBulkAdd;
  const _ParticipantPicker({required this.scopeInfo, required this.allStudents, required this.addedIds, required this.onAdd, required this.onBulkAdd});

  @override
  State<_ParticipantPicker> createState() => _ParticipantPickerState();
}

class _ParticipantPickerState extends State<_ParticipantPicker> {
  final _query = TextEditingController();
  bool _showAllScope = false;
  bool _pasteMode = false;
  final _pasteText = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    _pasteText.dispose();
    super.dispose();
  }

  List<GroupStudentRow> get _pool => (_showAllScope || !widget.scopeInfo.active) ? widget.allStudents : widget.scopeInfo.pool;

  List<GroupStudentRow> get _matches {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _pool.where((s) {
      if (widget.addedIds.contains(s.id)) return false;
      final hay = '${s.name} ${s.admissionNo} ${s.className} ${s.sectionName}'.toLowerCase();
      return hay.contains(q);
    }).take(8).toList();
  }

  void _bulkAddFromPaste() {
    final tokens = _pasteText.text.split(RegExp(r'[\n,;]+')).map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final found = <GroupStudentRow>[];
    final missing = <String>[];
    for (final tok in tokens) {
      final lower = tok.toLowerCase();
      final hit = _pool.where((s) => !widget.addedIds.contains(s.id) && (s.admissionNo.toLowerCase() == lower || s.name.toLowerCase() == lower)).firstOrNull ??
          _pool.where((s) => !widget.addedIds.contains(s.id) && (s.admissionNo.toLowerCase().contains(lower) || s.name.toLowerCase().contains(lower))).firstOrNull;
      if (hit != null && !found.any((f) => f.id == hit.id)) {
        found.add(hit);
      } else if (hit == null) {
        missing.add(tok);
      }
    }
    if (found.isNotEmpty) widget.onBulkAdd(found);
    setState(() {
      _pasteText.text = missing.join('\n');
      if (missing.isEmpty) _pasteMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Add participants', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _pasteMode = !_pasteMode),
                child: Text(_pasteMode ? '🔍 Search mode' : '📋 Paste a list', style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          if (widget.scopeInfo.active) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Text(widget.scopeInfo.icon),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${widget.scopeInfo.label} · ${_pool.length} eligible', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9)), overflow: TextOverflow.ellipsis)),
                  TextButton(
                    onPressed: () => setState(() => _showAllScope = !_showAllScope),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(_showAllScope ? '↺ Re-apply scope' : 'Show entire school', style: const TextStyle(fontSize: 10.5)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (!_pasteMode) ...[
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: 'Name, admission ID, or class…',
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (_query.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              if (_matches.isEmpty)
                const Text('No match.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
              else
                Column(
                  children: [
                    for (final s in _matches)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(radius: 16, backgroundColor: avatarColorFor(s.id), child: Text(initialsOf(s.name), style: const TextStyle(fontSize: 10, color: Colors.white))),
                        title: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: Text('${s.admissionNo} · ${s.className}${s.sectionName != '-' ? ' Sec ${s.sectionName}' : ''}', style: const TextStyle(fontSize: 10.5)),
                        trailing: FilledButton.tonal(
                          onPressed: () {
                            widget.onAdd(s);
                            _query.clear();
                            setState(() {});
                          },
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: Size.zero),
                          child: const Text('Add', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                  ],
                ),
            ],
          ] else ...[
            TextField(
              controller: _pasteText,
              maxLines: 5,
              decoration: buildInputDecoration('Paste admission IDs or names — one per line, comma, or semicolon'),
            ),
            const SizedBox(height: 6),
            FilledButton(onPressed: _bulkAddFromPaste, child: const Text('⚡ Match & add')),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Result cards + AI review
// ═══════════════════════════════════════════════════════════════════════

class _ResultCard extends StatefulWidget {
  final ResultEntry row;
  final Competition competition;
  final CompetitionsRepository repository;
  final ValueChanged<ResultEntry> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onAiBusyDelta;
  const _ResultCard({required this.row, required this.competition, required this.repository, required this.onChanged, required this.onRemove, required this.onAiBusyDelta});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  late final TextEditingController _contribution = TextEditingController(text: widget.row.personalContribution);

  @override
  void dispose() {
    _contribution.dispose();
    super.dispose();
  }

  void _setPosition(String value) {
    final def = positionDefFor(value);
    widget.onChanged(widget.row.copyWith(position: value, points: def?.points ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final def = positionDefFor(row.position);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, decoration: BoxDecoration(color: def != null ? _positionColor(def.value) : const Color(0xFFF1F5F9), borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: avatarColorFor(row.studentId), child: Text(initialsOf(row.studentName), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.studentName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                          Text(
                            '${row.admissionNo.isNotEmpty ? '${row.admissionNo} · ' : ''}${row.className}${row.sectionName != '-' && row.sectionName.isNotEmpty ? ' · Sec ${row.sectionName}' : ''}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (def != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _positionColor(def.value).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(def.icon, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 3),
                            SizedBox(
                              width: 28,
                              child: TextFormField(
                                initialValue: '${row.points}',
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _positionColor(def.value)),
                                decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                onChanged: (v) => widget.onChanged(row.copyWith(points: int.tryParse(v) ?? 0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in kResultPositions)
                      ChoiceChip(
                        label: Text('${p.icon} ${p.short}', style: const TextStyle(fontSize: 11)),
                        selected: row.position == p.value,
                        selectedColor: _positionColor(p.value).withValues(alpha: 0.18),
                        onSelected: (_) => _setPosition(p.value),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(child: Text('PERSONAL CONTRIBUTION', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF64748B)))),
                    TextButton(
                      onPressed: (row.position.isEmpty || row.position == 'not_participated')
                          ? null
                          : () {
                              final hint = kSmartHints[row.position] ?? '';
                              if (hint.isEmpty) return;
                              if (_contribution.text.isEmpty) {
                                _contribution.text = hint;
                                widget.onChanged(row.copyWith(personalContribution: hint));
                              }
                            },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text('💡 Suggest', style: TextStyle(fontSize: 10.5)),
                    ),
                  ],
                ),
                TextField(
                  controller: _contribution,
                  maxLines: 2,
                  onChanged: (v) => widget.onChanged(row.copyWith(personalContribution: v)),
                  decoration: buildInputDecoration('One or two lines about what this student did…'),
                ),
                _AiPanel(
                  row: row,
                  competition: widget.competition,
                  repository: widget.repository,
                  onChanged: widget.onChanged,
                  onBusyDelta: widget.onAiBusyDelta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _positionColor(String value) {
  switch (value) {
    case '1st':
      return const Color(0xFFB45309);
    case '2nd':
      return const Color(0xFF475569);
    case '3rd':
      return const Color(0xFFC2410C);
    case 'consolation':
      return const Color(0xFF0F766E);
    case 'participation':
      return const Color(0xFF047857);
    default:
      return const Color(0xFFBE123C);
  }
}

const _kAiSections = <(String key, String icon, Color color)>[
  ('Compliment', '💬', Color(0xFFB45309)),
  ('Performance Summary', '🎯', Color(0xFF7C3AED)),
  ('Encouragement', '🚀', Color(0xFF047857)),
  ('Practical Tips', '💡', Color(0xFF0369A1)),
];

Map<String, String> _parseAiSections(String text) {
  final headings = _kAiSections.map((s) => s.$1).toList();
  final pattern = RegExp('(${headings.map((h) => h.replaceAll(' ', r'\s+')).join('|')})\\s*:', caseSensitive: false);
  final matches = pattern.allMatches(text).toList();
  final out = <String, String>{};
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final title = headings.firstWhere(
      (h) => h.toLowerCase() == (m.group(1) ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim(),
      orElse: () => m.group(1) ?? '',
    );
    final start = m.end;
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    out[title] = text.substring(start, end).trim();
  }
  return out;
}

String _rebuildAiText(Map<String, String> sections) {
  return 'Performance Review\n\n${_kAiSections.map((s) => '${s.$1}: ${sections[s.$1] ?? ''}').join('\n\n')}';
}

String _localFallbackReview(ResultEntry row, Competition competition) {
  final name = row.studentName.isEmpty ? 'the student' : row.studentName;
  final comp = competition.name.isEmpty ? 'the competition' : competition.name;
  if (row.position == 'not_participated') {
    return 'Performance Review\n\n'
        "Compliment: We appreciate $name's presence in the school community.\n\n"
        'Performance Summary: $name did not take part in $comp this time. Participation builds confidence, friendships, and resilience.\n\n'
        'Encouragement: There is always a next chance to shine.\n\n'
        'Practical Tips: Try a small role next time. Cheer for a friend. Sign up for a beginner-friendly category.';
  }
  if (row.position == 'participation' || row.position == 'consolation') {
    return 'Performance Review\n\n'
        'Compliment: $name showed wonderful spirit in $comp.\n\n'
        'Performance Summary: Effort and a positive attitude were on full display, which is exactly how growth begins.\n\n'
        'Encouragement: Keep showing up — every step forward counts.\n\n'
        'Practical Tips: Practise a little each week. Ask for feedback. Set one tiny goal before the next event.';
  }
  final posLabel = kPositionLabels[row.position] ?? row.position;
  return 'Performance Review\n\n'
      'Compliment: A wonderful achievement, $name!\n\n'
      'Performance Summary: Strong preparation and composure helped earn the $posLabel position in $comp. A small refinement around consistency will take you further still.\n\n'
      'Encouragement: Wonderful work — keep that momentum going!\n\n'
      'Practical Tips: Keep a short practice journal. Review your best moments. Mentor a peer to deepen your own learning.';
}

class _AiPanel extends StatefulWidget {
  final ResultEntry row;
  final Competition competition;
  final CompetitionsRepository repository;
  final ValueChanged<ResultEntry> onChanged;
  final ValueChanged<int> onBusyDelta;
  const _AiPanel({required this.row, required this.competition, required this.repository, required this.onChanged, required this.onBusyDelta});

  @override
  State<_AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<_AiPanel> {
  bool _busy = false;
  bool _editing = false;
  String? _error;
  late final TextEditingController _raw = TextEditingController(text: widget.row.aiResponse);

  @override
  void didUpdateWidget(covariant _AiPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.aiResponse != widget.row.aiResponse && _raw.text != widget.row.aiResponse) {
      _raw.text = widget.row.aiResponse;
    }
  }

  @override
  void dispose() {
    _raw.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final row = widget.row;
    if (row.position.isEmpty) {
      setState(() => _error = 'Pick a position first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyDelta(1);
    var text = '';
    var meta = const AiMeta();
    try {
      final results = await widget.repository.generateReviews([
        {
          'student_id': row.studentId,
          'student_name': row.studentName,
          'student_class': row.className,
          'competition_id': widget.competition.backendId,
          'competition_name': widget.competition.name,
          'competition_type': widget.competition.compType.value,
          'competition_level': widget.competition.level.value,
          'position': row.position,
          'points': row.points,
          'personal_contribution': row.personalContribution,
        },
      ]);
      if (results.isNotEmpty) {
        text = results.first.review;
        meta = AiMeta(cacheHit: results.first.cacheHit, fallback: results.first.fallback);
      }
    } catch (_) {
      // Silent — fall through to the local template below.
    }
    if (text.isEmpty) {
      text = _localFallbackReview(row, widget.competition);
      meta = const AiMeta(fallback: true);
    }
    widget.onChanged(row.copyWith(aiResponse: text, aiMeta: meta));
    if (mounted) setState(() => _busy = false);
    widget.onBusyDelta(-1);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final sections = row.aiResponse.isEmpty ? <String, String>{} : _parseAiSections(row.aiResponse);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]), borderRadius: BorderRadius.circular(6)),
                child: const Text('AI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 6),
              const Text('Generated review', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
              if (row.aiMeta.cacheHit) _badge('⚡ cached', const Color(0xFFD1FAE5), const Color(0xFF047857)),
              if (row.aiMeta.fallback) _badge('✨ AI draft', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
              const Spacer(),
              if (row.aiResponse.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _editing = !_editing),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(_editing ? '👁 Preview' : '✏ Edit', style: const TextStyle(fontSize: 10.5)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _generate,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(vertical: 8)),
              child: Text(
                _busy ? 'Generating…' : (row.aiResponse.isNotEmpty ? '✨ Regenerate' : '✨ Generate AI review'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)))),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
          if (!_busy && row.aiResponse.isNotEmpty && !_editing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: sections.isEmpty
                  ? Text(row.aiResponse, style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)))
                  : Column(
                      children: [
                        for (final s in _kAiSections)
                          if (sections.containsKey(s.$1))
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                              decoration: BoxDecoration(
                                color: s.$3.withValues(alpha: 0.06),
                                border: Border(left: BorderSide(color: s.$3, width: 3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [Text(s.$2, style: const TextStyle(fontSize: 12)), const SizedBox(width: 4), Text(s.$1.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: s.$3))]),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    initialValue: sections[s.$1],
                                    maxLines: null,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                                    onChanged: (v) {
                                      final next = {...sections, s.$1: v};
                                      widget.onChanged(row.copyWith(aiResponse: _rebuildAiText(next)));
                                    },
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
            ),
          if (!_busy && row.aiResponse.isNotEmpty && _editing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _raw,
                maxLines: 8,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                onChanged: (v) => widget.onChanged(row.copyWith(aiResponse: v)),
                decoration: buildInputDecoration(null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: fg)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
// Other outcomes (Participation / Not Participated) — trimmed version of
// web's Step 4, which filters and bulk-adds by arbitrary criteria; here
// it's "everyone still eligible but not yet added" for simplicity.
// ═══════════════════════════════════════════════════════════════════════

class _OtherOutcomesSection extends StatefulWidget {
  final List<ResultEntry> others;
  final ScopeInfo scopeInfo;
  final Set<int> addedIds;
  final void Function(List<GroupStudentRow> students, String position) onBulkMark;
  final ValueChanged<int> onRemove;
  const _OtherOutcomesSection({required this.others, required this.scopeInfo, required this.addedIds, required this.onBulkMark, required this.onRemove});

  @override
  State<_OtherOutcomesSection> createState() => _OtherOutcomesSectionState();
}

class _OtherOutcomesSectionState extends State<_OtherOutcomesSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final remaining = widget.scopeInfo.pool.where((s) => !widget.addedIds.contains(s.id)).toList();
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(child: Text('Other outcomes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                  Text('${widget.others.length} marked · ${remaining.length} remaining', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Icon(_open ? Icons.expand_less : Icons.expand_more, size: 18, color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (remaining.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => widget.onBulkMark(remaining, 'participation'),
                          child: Text('✅ Mark remaining ${remaining.length} as Participation', style: const TextStyle(fontSize: 11)),
                        ),
                        OutlinedButton(
                          onPressed: () => widget.onBulkMark(remaining, 'not_participated'),
                          child: const Text('🚫 Mark as Not Participated', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (widget.others.isNotEmpty)
                    Column(
                      children: [
                        for (final r in widget.others)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Text(positionDefFor(r.position)?.icon ?? '·'),
                                const SizedBox(width: 6),
                                Expanded(child: Text(r.studentName, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                                Text(kPositionLabels[r.position] ?? r.position, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                IconButton(onPressed: () => widget.onRemove(r.studentId), icon: const Icon(Icons.close, size: 14), visualDensity: VisualDensity.compact),
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
}

// ═══════════════════════════════════════════════════════════════════════
// Mini dashboard snapshot
// ═══════════════════════════════════════════════════════════════════════

class _MiniDashboardSnapshot extends StatelessWidget {
  final List<ResultEntry> results;
  const _MiniDashboardSnapshot({required this.results});

  @override
  Widget build(BuildContext context) {
    final total = results.length;
    final points = results.fold<int>(0, (s, r) => s + r.points);
    final reviewed = results.where((r) => r.aiResponse.isNotEmpty).length;
    final pct = total == 0 ? 0 : (reviewed / total * 100).round();
    final podiumTiers = ['1st', '2nd', '3rd'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Snapshot', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const Spacer(),
              Text('$points total points · $total entries', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final tier in podiumTiers) ...[
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _positionColor(tier).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(positionDefFor(tier)!.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Builder(builder: (context) {
                          final winners = results.where((r) => r.position == tier).toList();
                          if (winners.isEmpty) return const Text('— unassigned —', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)));
                          return Text(
                            winners.map((w) => w.studentName).take(2).join(', ') + (winners.length > 2 ? ' +${winners.length - 2}' : ''),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('AI Reviews', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const Spacer(),
              Text('$reviewed/$total · $pct%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: total == 0 ? 0 : reviewed / total, minHeight: 6, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Export controls
// ═══════════════════════════════════════════════════════════════════════

class _ExportControls extends StatefulWidget {
  final Competition competition;
  final List<ResultEntry> results;
  final CompetitionsRepository repository;
  const _ExportControls({required this.competition, required this.results, required this.repository});

  @override
  State<_ExportControls> createState() => _ExportControlsState();
}

class _ExportControlsState extends State<_ExportControls> {
  bool _saving = false;
  bool _saved = false;
  String? _error;

  Future<void> _saveToServer() async {
    final backendId = widget.competition.backendId;
    if (backendId == null) return;
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    try {
      await widget.repository.bulkCreateResults([
        for (final r in widget.results.where((r) => r.position.isNotEmpty))
          {
            'competition': backendId,
            'student': r.studentId,
            'position': r.position,
            'points': r.points,
            'personal_contribution': r.personalContribution,
            'performance_notes': '',
            'ai_generated': r.aiResponse.isNotEmpty,
            'ai_response': r.aiResponse,
          },
      ]);
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareCsv() async {
    final rows = <List<String>>[
      ['Student', 'Class', 'Position', 'Points', 'Personal Contribution', 'AI Review'],
      for (final r in widget.results)
        [
          r.studentName,
          r.className,
          kPositionLabels[r.position] ?? r.position,
          '${r.points}',
          r.personalContribution.replaceAll('\n', ' '),
          r.aiResponse.replaceAll('\n', ' '),
        ],
    ];
    final csv = rows.map((row) => row.map((c) => '"${c.replaceAll('"', '""')}"').join(',')).join('\n');
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final safeName = widget.competition.name.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    await Share.shareXFiles([XFile.fromData(bytes, name: '${safeName.isEmpty ? 'competition' : safeName}.csv', mimeType: 'text/csv')]);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.competition.isLocal || widget.competition.backendId == null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export & save', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_saving || disabled) ? null : _saveToServer,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              child: Text(_saving ? 'Saving…' : (_saved ? '✅ Saved' : '💾 Save to server')),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: _shareCsv, child: const Text('📊 Share as CSV')),
          ),
          if (disabled)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Server save is disabled while in offline-draft mode.', style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E))),
            ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)))),
        ],
      ),
    );
  }
}
