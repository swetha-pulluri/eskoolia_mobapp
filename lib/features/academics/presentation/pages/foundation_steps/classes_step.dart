import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/class_entity.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/foundation_widgets.dart';

/// Step 2 — port of ClassesPane.tsx.
class ClassesStep extends ConsumerStatefulWidget {
  final List<FoundationClass> classes;
  final List<StreamDetail> streams;
  final Future<void> Function() onRefreshClasses;
  final Future<void> Function() onRefreshStreams;
  final void Function(String message, {bool error}) showToast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ClassesStep({
    super.key,
    required this.classes,
    required this.streams,
    required this.onRefreshClasses,
    required this.onRefreshStreams,
    required this.showToast,
    required this.onBack,
    required this.onNext,
  });

  @override
  ConsumerState<ClassesStep> createState() => _ClassesStepState();
}

class _ClassesStepState extends ConsumerState<ClassesStep> {
  String _level = 'primary';
  String _name = '';
  String _capacity = '40';
  final Set<int> _selectedStreams = {};
  final Map<int, String> _streamCapacities = {};
  bool _showAddStream = false;
  final _newStreamController = TextEditingController();
  bool _addingStream = false;

  int? _editingClassId;
  bool _saving = false;
  bool _loadingDefaults = false;
  String _error = '';
  int? _deletingId;
  int? _togglingId;
  FoundationClass? _pendingDelete;
  int _page = 0;
  static const _perPage = 10;
  final GlobalKey _deleteConfirmKey = GlobalKey();

  void _scrollToDeleteConfirm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _deleteConfirmKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.1);
      }
    });
  }

  @override
  void dispose() {
    _newStreamController.dispose();
    super.dispose();
  }

  void _handleLevelChange(String level) {
    setState(() {
      _level = level;
      _name = '';
      _selectedStreams.clear();
      _streamCapacities.clear();
      _showAddStream = false;
      _newStreamController.clear();
      _capacity = '${foundationLevelDefaultCapacity[level] ?? 40}';
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingClassId = null;
      _name = '';
      _capacity = '${foundationLevelDefaultCapacity[_level] ?? 40}';
      _selectedStreams.clear();
      _streamCapacities.clear();
      _error = '';
    });
  }

  void _openEdit(FoundationClass c) {
    final level = foundationInferLevel(c.name);
    setState(() {
      _editingClassId = c.id;
      _level = level.isEmpty ? 'primary' : level;
      _name = c.name;
      _selectedStreams
        ..clear()
        ..addAll(c.streamDetails.map((s) => s.id));
      _streamCapacities
        ..clear()
        ..addEntries(c.streamDetails.map((s) => MapEntry(s.id, '${s.capacity}')));
      _error = '';
    });
  }

  Future<void> _addStream() async {
    final trimmed = _newStreamController.text.trim();
    if (trimmed.isEmpty) return;
    if (widget.streams.any((s) => s.name.toLowerCase() == trimmed.toLowerCase())) {
      widget.showToast('Stream "$trimmed" already exists.', error: true);
      return;
    }
    setState(() => _addingStream = true);
    try {
      final s = await ref.read(academicsRepositoryProvider).createStream(trimmed);
      widget.showToast('Stream "$trimmed" added.');
      _newStreamController.clear();
      setState(() {
        _showAddStream = false;
        _selectedStreams.add(s.id);
        _streamCapacities[s.id] = '35';
      });
      await widget.onRefreshStreams();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _addingStream = false);
    }
  }

  Future<void> _save() async {
    if (_name.isEmpty) {
      setState(() => _error = 'Class name is required.');
      return;
    }
    if (widget.classes.any((c) => c.id != _editingClassId && c.name.toLowerCase() == _name.toLowerCase())) {
      setState(() => _error = 'Class "$_name" already exists. Please choose a different name.');
      return;
    }
    List<({int streamId, int capacity})>? streamCapacities;
    int? capacity;
    if (_level == 'senior') {
      if (_selectedStreams.isEmpty) {
        setState(() => _error = 'Select at least one stream for Senior Secondary classes.');
        return;
      }
      final list = <({int streamId, int capacity})>[];
      for (final sid in _selectedStreams) {
        final cap = int.tryParse(_streamCapacities[sid] ?? '');
        final sName = widget.streams.where((s) => s.id == sid).firstOrNull?.name ?? 'Stream $sid';
        if (cap == null || cap < 1 || cap > 200) {
          setState(() => _error = '$sName capacity must be between 1 and 200.');
          return;
        }
        list.add((streamId: sid, capacity: cap));
      }
      streamCapacities = list;
    } else {
      final cap = int.tryParse(_capacity);
      if (cap == null || cap < 1 || cap > 200) {
        setState(() => _error = 'Capacity must be between 1 and 200 students per section.');
        return;
      }
      capacity = cap;
    }

    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final repo = ref.read(academicsRepositoryProvider);
      if (_editingClassId != null) {
        await repo.updateClass(_editingClassId!, name: _name, streamCapacities: _level == 'senior' ? streamCapacities : (streamCapacities ?? const []));
        widget.showToast('Class updated to "$_name".');
      } else {
        await repo.createClass(name: _name, capacity: capacity, streamCapacities: streamCapacities);
        widget.showToast('Class "$_name" created.');
      }
      _cancelEdit();
      await widget.onRefreshClasses();
    } catch (e) {
      var msg = e.toString().replaceFirst('Exception: ', '');
      if (RegExp(r'\b404\b|not.?found|No Class matches', caseSensitive: false).hasMatch(msg)) {
        widget.showToast('This class no longer exists. Refreshing the list…', error: true);
        _cancelEdit();
        await widget.onRefreshClasses();
        return;
      }
      if (RegExp(r'already exists|unique|duplicate', caseSensitive: false).hasMatch(msg)) {
        msg = 'Class "$_name" already exists. Please choose a different name.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadDefaults() async {
    setState(() => _loadingDefaults = true);
    final repo = ref.read(academicsRepositoryProvider);
    var created = 0;
    for (final name in foundationValidClassNames) {
      if (widget.classes.any((c) => c.name.toLowerCase() == name.toLowerCase())) continue;
      try {
        await repo.createClass(name: name);
        created++;
      } catch (_) {
        // skip duplicates/failures silently, matching the reference
      }
    }
    await widget.onRefreshClasses();
    widget.showToast(created > 0 ? '$created classes — done ✓' : 'All classes already exist — done ✓');
    if (mounted) setState(() => _loadingDefaults = false);
  }

  Future<void> _confirmDelete() async {
    final c = _pendingDelete;
    if (c == null) return;
    setState(() => _deletingId = c.id);
    try {
      await ref.read(academicsRepositoryProvider).deleteClass(c.id);
      widget.showToast('"${c.name}" deleted.');
      setState(() => _pendingDelete = null);
      await widget.onRefreshClasses();
    } catch (e) {
      final msg = e.toString();
      if (RegExp(r'\b404\b|not.?found', caseSensitive: false).hasMatch(msg)) {
        widget.showToast('This class no longer exists. Refreshing the list…', error: true);
        setState(() => _pendingDelete = null);
        await widget.onRefreshClasses();
      } else {
        widget.showToast('Failed to delete.', error: true);
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _toggleActive(FoundationClass c) async {
    setState(() => _togglingId = c.id);
    try {
      await ref.read(academicsRepositoryProvider).toggleClassActive(c.id, !c.isActive);
      widget.showToast('"${c.name}" marked ${!c.isActive ? 'active' : 'inactive'}.');
      await widget.onRefreshClasses();
    } catch (_) {
      widget.showToast('Failed to update.', error: true);
    } finally {
      if (mounted) setState(() => _togglingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _buildForm();
          final table = _buildTable();
          if (wide) {
            return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: form), const SizedBox(width: 16), Expanded(child: table)]));
          }
          return Column(children: [form, const SizedBox(height: 10), table]);
        }),
        if (_pendingDelete != null)
          FoundationConfirmDeleteDialog(
            key: _deleteConfirmKey,
            title: 'Delete Class',
            message: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(text: '"${_pendingDelete!.name}"', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: '? All sections, stream links and other related records under this class will be removed.'),
            ])),
            loading: _deletingId == _pendingDelete!.id,
            onConfirm: _confirmDelete,
            onCancel: () => setState(() => _pendingDelete = null),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(_editingClassId != null ? 'Edit Class' : 'Add Class / Grade', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
              ]),
            ),
            if (_editingClassId != null)
              TextButton(onPressed: _cancelEdit, child: const Text('✕ Cancel', style: TextStyle(fontSize: 12, color: Color(0xFF6F767E)))),
          ]),
          const SizedBox(height: 8),
          foundationFieldLabel('Academic Level', required: true),
          for (final opt in foundationLevelOptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () => _handleLevelChange(opt.$1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: _level == opt.$1 ? const Color(0xFFF5F3FF) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    FoundationRadioDot(selected: _level == opt.$1),
                    const SizedBox(width: 6),
                    Text(opt.$2, style: TextStyle(fontSize: 13, fontWeight: _level == opt.$1 ? FontWeight.w700 : FontWeight.w500, color: _level == opt.$1 ? const Color(0xFF5B4FCF) : const Color(0xFF1A1D1F))),
                    const SizedBox(width: 6),
                    Flexible(child: Text(opt.$3, style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD)))),
                  ]),
                ),
              ),
            ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: Color(0xFFE8ECEF))),
          foundationFieldLabel('Class / Grade Name', required: true),
          DropdownButtonFormField<String>(
            initialValue: _name.isEmpty ? null : _name,
            isExpanded: true,
            decoration: foundationFieldDecoration(hint: '— select class —'),
            items: (foundationNamesByLevel[_level] ?? foundationValidClassNames).map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _name = v ?? ''),
          ),
          const SizedBox(height: 3),
          Text.rich(TextSpan(style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD)), children: [
            const TextSpan(text: 'Only names valid for '),
            TextSpan(text: foundationLevelLabel(_level), style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(text: ' are shown.'),
          ])),
          if (_level == 'senior') ...[
            const SizedBox(height: 10),
            Row(children: [
              const Expanded(child: Text('STREAMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6F767E)))),
              TextButton(
                onPressed: () => setState(() {
                  _showAddStream = !_showAddStream;
                  _newStreamController.clear();
                }),
                child: Text(_showAddStream ? '× Cancel' : '+ Add Stream', style: const TextStyle(fontSize: 11, color: Color(0xFF5B4FCF))),
              ),
            ]),
            Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF0F2F5), border: Border.all(color: const Color(0xFFE8ECEF), width: 1.5), borderRadius: BorderRadius.circular(10)),
              child: widget.streams.isEmpty
                  ? const Text('No streams yet — use "+ Add Stream".', style: TextStyle(fontSize: 12, color: Color(0xFF9FA6AD), fontStyle: FontStyle.italic))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.streams.map((s) {
                        final sel = _selectedStreams.contains(s.id);
                        return InkWell(
                          onTap: () => setState(() {
                            if (sel) {
                              _selectedStreams.remove(s.id);
                            } else {
                              _selectedStreams.add(s.id);
                              _streamCapacities.putIfAbsent(s.id, () => '35');
                            }
                          }),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: sel ? const Color(0xFF5B4FCF) : Colors.white, border: Border.all(color: sel ? const Color(0xFF5B4FCF) : const Color(0xFFD2D7DC)), borderRadius: BorderRadius.circular(999)),
                            child: Text(s.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF6F767E))),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            if (_showAddStream) ...[
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _newStreamController,
                    autofocus: true,
                    maxLength: 50,
                    onSubmitted: (_) => _addStream(),
                    decoration: foundationFieldDecoration(hint: 'e.g. Science with CS').copyWith(counterText: '', focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF5B4FCF), width: 1.5))),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addingStream ? null : _addStream,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text(_addingStream ? 'Adding…' : 'Save'),
                ),
              ]),
            ],
            if (_selectedStreams.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('STREAM CAPACITIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6F767E))),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8ECEF), width: 1.5), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in widget.streams.where((s) => _selectedStreams.contains(s.id)))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE8ECEF)))),
                        child: Row(children: [
                          Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)))),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(text: _streamCapacities[s.id] ?? '35')..selection = TextSelection.collapsed(offset: (_streamCapacities[s.id] ?? '35').length),
                              onChanged: (v) => _streamCapacities[s.id] = v.replaceAll(RegExp(r'[^0-9]'), '').characters.take(3).toString(),
                              decoration: foundationFieldDecoration(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('students', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              const Text('Capacity is set per stream (1–200). Default 35.', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
            ],
            const SizedBox(height: 4),
            const Text('Tick one or more streams for this class. Applies to Grade 11 & 12 only.', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
          ] else if (_editingClassId == null) ...[
            const SizedBox(height: 10),
            foundationFieldLabel('Maximum Student Capacity'),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              SizedBox(
                width: 96,
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _capacity)..selection = TextSelection.collapsed(offset: _capacity.length),
                  onChanged: (v) => _capacity = v,
                  decoration: foundationFieldDecoration(),
                ),
              ),
              const Text('students per section · max 200', style: TextStyle(fontSize: 12, color: Color(0xFF9FA6AD))),
            ]),
          ],
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), border: Border.all(color: const Color(0xFFFCA5A5)), borderRadius: BorderRadius.circular(10)),
              child: Text(_error, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(_saving ? (_editingClassId != null ? 'Saving…' : 'Adding…') : (_editingClassId != null ? 'Update Class' : '+ Add Class')),
            ),
            if (_editingClassId == null)
              OutlinedButton(
                onPressed: _loadingDefaults ? null : _loadDefaults,
                style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFEEF0FF), foregroundColor: const Color(0xFF5B4FCF), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(_loadingDefaults ? 'Loading…' : '📋 Load All (Nursery–12)'),
              )
            else
              OutlinedButton(
                onPressed: _cancelEdit,
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Cancel'),
              ),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: widget.onBack, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('← Back')),
            OutlinedButton(onPressed: widget.onNext, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Next: Sections →')),
          ]),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final totalPages = (widget.classes.length / _perPage).ceil();
    final safePage = totalPages > 0 ? _page.clamp(0, totalPages - 1) : 0;
    final pageClasses = widget.classes.skip(safePage * _perPage).take(_perPage).toList();

    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Expanded(child: Text('Classes Defined', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(999)), child: Text('${widget.classes.length} classes', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5B4FCF)))),
          ]),
          const SizedBox(height: 8),
          if (widget.classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(children: [
                  Text('🏫', style: TextStyle(fontSize: 26)),
                  SizedBox(height: 4),
                  Text('No classes yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9FA6AD))),
                  Text('Use the form or load all defaults.', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
                ]),
              ),
            )
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 660,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: const BoxDecoration(color: Color(0xFFF0F2F5), border: Border(bottom: BorderSide(color: Color(0xFFE8ECEF)))),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Row(children: [
                        SizedBox(width: 140, child: Padding(padding: EdgeInsets.only(left: 8), child: Text('CLASS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6F767E))))),
                        SizedBox(width: 110, child: Text('LEVEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6F767E)))),
                        SizedBox(width: 140, child: Text('STREAMS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6F767E)))),
                        SizedBox(width: 105, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6F767E)))),
                        SizedBox(width: 76, child: Text('', style: TextStyle(fontSize: 10))),
                      ]),
                    ),
                    for (final c in pageClasses) _classRow(c),
                  ],
                ),
              ),
            ),
            if (totalPages > 1) ...[
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${safePage * _perPage + 1}–${(safePage * _perPage + pageClasses.length)} of ${widget.classes.length}', style: const TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(onPressed: safePage == 0 ? null : () => setState(() => _page = safePage - 1), icon: const Icon(Icons.chevron_left, size: 18), visualDensity: VisualDensity.compact),
                  Text('${safePage + 1}/$totalPages', style: const TextStyle(fontSize: 10, color: Color(0xFF6F767E))),
                  IconButton(onPressed: safePage >= totalPages - 1 ? null : () => setState(() => _page = safePage + 1), icon: const Icon(Icons.chevron_right, size: 18), visualDensity: VisualDensity.compact),
                ]),
              ]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _classRow(FoundationClass c) {
    final isEditing = _editingClassId == c.id;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: isEditing ? const Color(0xFFF5F3FF) : Colors.transparent, border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
      child: Opacity(
        opacity: c.isActive ? 1 : 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 140, child: Padding(padding: const EdgeInsets.only(left: 8), child: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))))),
            SizedBox(width: 110, child: Text(foundationLevelLabel(foundationInferLevel(c.name)), style: const TextStyle(fontSize: 12, color: Color(0xFF6F767E)))),
            SizedBox(
              width: 140,
              child: c.streamDetails.isEmpty
                  ? const Text('—', style: TextStyle(fontSize: 11, color: Color(0xFFD2D7DC)))
                  : Wrap(spacing: 4, runSpacing: 4, children: [
                      for (final s in c.streamDetails.take(3)) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEEF0FF), border: Border.all(color: const Color(0xFFC7C3F0)), borderRadius: BorderRadius.circular(999)), child: Text(s.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5B4FCF)))),
                      if (c.streamDetails.length > 3) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF0F2F5), border: Border.all(color: const Color(0xFFE8ECEF)), borderRadius: BorderRadius.circular(999)), child: Text('+${c.streamDetails.length - 3}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6F767E)))),
                    ]),
            ),
            SizedBox(
              width: 105,
              child: InkWell(
                onTap: _togglingId == c.id ? null : () => _toggleActive(c),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 30,
                    height: 18,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: c.isActive ? const Color(0xFF5B4FCF) : const Color(0xFFD2D7DC), borderRadius: BorderRadius.circular(999)),
                    child: AnimatedAlign(duration: const Duration(milliseconds: 150), alignment: c.isActive ? Alignment.centerRight : Alignment.centerLeft, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                  ),
                  const SizedBox(width: 5),
                  Text(c.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.isActive ? const Color(0xFF15803D) : const Color(0xFF9FA6AD))),
                ]),
              ),
            ),
            SizedBox(
              width: 84,
              child: Row(children: [
                IconButton(onPressed: () => _openEdit(c), icon: const Icon(Icons.edit_outlined, size: 15), color: const Color(0xFF6F767E), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32), tooltip: 'Edit class'),
                IconButton(
                  onPressed: _deletingId == c.id
                      ? null
                      : () {
                          setState(() => _pendingDelete = c);
                          _scrollToDeleteConfirm();
                        },
                  icon: _deletingId == c.id ? const Text('…') : const Icon(Icons.delete_outline, size: 15),
                  color: const Color(0xFF9FA6AD),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Delete class',
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
