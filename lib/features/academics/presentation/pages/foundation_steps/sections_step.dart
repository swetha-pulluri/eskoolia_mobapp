import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/class_entity.dart';
import '../../../domain/entities/section_entity.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/foundation_widgets.dart';

/// Step 3 — port of SectionsPane.tsx.
class SectionsStep extends ConsumerStatefulWidget {
  final List<FoundationClass> classes;
  final Future<void> Function() onRefresh;
  final void Function(String message, {bool error}) showToast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SectionsStep({super.key, required this.classes, required this.onRefresh, required this.showToast, required this.onBack, required this.onNext});

  @override
  ConsumerState<SectionsStep> createState() => _SectionsStepState();
}

class _SectionsStepState extends ConsumerState<SectionsStep> {
  final Set<int> _selectedClsIds = {};
  int _count = 3;
  String _pattern = 'alpha';
  int _capacity = 40;
  String? _appliedPattern;
  bool _creating = false;

  bool _selectMode = false;
  final Set<int> _selectedSecIds = {};
  int? _renamingId;
  final _renameController = TextEditingController();
  int? _deletingId;
  FoundationSection? _pendingDelete;
  bool _pendingBulkDelete = false;
  bool _bulkDeleting = false;
  final Set<int> _pendingDeleteIds = {};
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
    _renameController.dispose();
    super.dispose();
  }

  List<String> get _preview => (foundationSectionPatterns[_pattern] ?? const []).take(_count.clamp(1, 10)).toList();

  List<FoundationClass> get _visibleClasses => widget.classes.where((c) => c.sections.any((s) => !_pendingDeleteIds.contains(s.id))).toList();

  Future<void> _createSections() async {
    if (_selectedClsIds.isEmpty) {
      widget.showToast('Select at least one class.', error: true);
      return;
    }
    final newNames = _preview;
    final oldNamesSet = <String>{};
    for (final cid in _selectedClsIds) {
      final cls = widget.classes.where((c) => c.id == cid).firstOrNull;
      if (cls == null) continue;
      for (final s in cls.sections) {
        if (!newNames.map((n) => n.toLowerCase()).contains(s.name.toLowerCase())) oldNamesSet.add(s.name);
      }
    }
    setState(() => _creating = true);
    try {
      final res = await ref.read(academicsRepositoryProvider).replaceSections(classIds: _selectedClsIds.toList(), oldNames: oldNamesSet.toList(), newNames: newNames, capacity: _capacity);
      await widget.onRefresh();
      if (res.created > 0 && res.deleted > 0) {
        widget.showToast('${res.created} section${res.created != 1 ? 's' : ''} created, ${res.deleted} old section${res.deleted != 1 ? 's' : ''} removed ✓');
      } else if (res.created > 0) {
        widget.showToast('${res.created} section${res.created != 1 ? 's' : ''} created ✓');
      } else if (res.deleted > 0) {
        widget.showToast('${res.deleted} old section${res.deleted != 1 ? 's' : ''} removed ✓');
      } else {
        widget.showToast('Sections already match — nothing changed.', error: true);
      }
      setState(() => _appliedPattern = _pattern);
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _saveRename(FoundationSection sec) async {
    final name = _renameController.text;
    try {
      await ref.read(academicsRepositoryProvider).renameSection(sec.id, name);
      widget.showToast('Section renamed.');
      setState(() => _renamingId = null);
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _confirmDeleteSection() async {
    final sec = _pendingDelete;
    if (sec == null) return;
    setState(() {
      _deletingId = sec.id;
      _pendingDeleteIds.add(sec.id);
    });
    try {
      await ref.read(academicsRepositoryProvider).deleteSection(sec.id);
      widget.showToast('Section "${sec.name}" deleted.');
      setState(() => _pendingDelete = null);
      await widget.onRefresh();
    } catch (e) {
      final msg = e.toString();
      if (RegExp(r'\b404\b|not.?found', caseSensitive: false).hasMatch(msg)) {
        widget.showToast('This section no longer exists. Refreshing the list…', error: true);
        setState(() => _pendingDelete = null);
        await widget.onRefresh();
      } else {
        widget.showToast('Failed to delete section.', error: true);
        setState(() => _pendingDeleteIds.remove(sec.id));
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _confirmBulkDelete() async {
    setState(() => _bulkDeleting = true);
    try {
      final ids = _selectedSecIds.toList();
      setState(() => _pendingDeleteIds.addAll(ids));
      final deleted = await ref.read(academicsRepositoryProvider).bulkDeleteSections(ids);
      widget.showToast('$deleted section${deleted != 1 ? 's' : ''} deleted ✓');
      setState(() {
        _pendingBulkDelete = false;
        _selectedSecIds.clear();
        _selectMode = false;
      });
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _bulkDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSectionsCount = widget.classes.fold<int>(0, (s, c) => s + c.sections.where((s) => !_pendingDeleteIds.contains(s.id)).length);
    return Stack(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final left = _buildCreateCard();
          final right = _buildListCard(allSectionsCount);
          if (wide) return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)]));
          return Column(children: [left, const SizedBox(height: 10), right]);
        }),
        if (_pendingDelete != null)
          FoundationConfirmDeleteDialog(
            key: _deleteConfirmKey,
            title: 'Delete Section',
            message: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Are you sure you want to delete section '),
              TextSpan(text: '"${_pendingDelete!.name}"', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: '? Any students currently assigned to this section will be unlinked.'),
            ])),
            loading: _deletingId == _pendingDelete!.id,
            onConfirm: _confirmDeleteSection,
            onCancel: () => setState(() => _pendingDelete = null),
          ),
        if (_pendingBulkDelete)
          FoundationConfirmDeleteDialog(
            title: 'Delete Sections',
            message: const Text('Are you sure you want to delete the selected sections? Students linked to these sections will be unassigned.'),
            loading: _bulkDeleting,
            onConfirm: _confirmBulkDelete,
            onCancel: () => setState(() => _pendingBulkDelete = false),
          ),
      ],
    );
  }

  Widget _buildCreateCard() {
    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Create Sections', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
          const Text('Select one or more classes and define their sections', style: TextStyle(fontSize: 11, color: Color(0xFF6F767E))),
          const SizedBox(height: 8),
          Text.rich(TextSpan(style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6F767E)), children: [
            const TextSpan(text: 'Apply to Classes '),
            const TextSpan(text: '(click to select/deselect)', style: TextStyle(fontWeight: FontWeight.normal, color: Color(0xFF9FA6AD))),
          ])),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF0F2F5), border: Border.all(color: const Color(0xFFE8ECEF), width: 1.5), borderRadius: BorderRadius.circular(10)),
            child: widget.classes.isEmpty
                ? const Text('No classes — go back to Step 2', style: TextStyle(fontSize: 12, color: Color(0xFF9FA6AD), fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.classes.map((c) {
                      final sel = _selectedClsIds.contains(c.id);
                      return InkWell(
                        onTap: () => setState(() => sel ? _selectedClsIds.remove(c.id) : _selectedClsIds.add(c.id)),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: sel ? const Color(0xFF5B4FCF) : Colors.white, border: Border.all(color: sel ? const Color(0xFF5B4FCF) : const Color(0xFFD2D7DC)), borderRadius: BorderRadius.circular(999)),
                          child: Text(c.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF6F767E))),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                foundationFieldLabel('No. of Sections'),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: '$_count')..selection = TextSelection.collapsed(offset: '$_count'.length),
                  onChanged: (v) => setState(() => _count = (int.tryParse(v) ?? 1).clamp(1, 10)),
                  decoration: foundationFieldDecoration(),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                foundationFieldLabel('Name Pattern'),
                DropdownButtonFormField<String>(
                  initialValue: _pattern,
                  isExpanded: true,
                  decoration: foundationFieldDecoration(),
                  items: const [DropdownMenuItem(value: 'alpha', child: Text('A, B, C…')), DropdownMenuItem(value: 'num', child: Text('1, 2, 3…')), DropdownMenuItem(value: 'roman', child: Text('I, II, III…'))],
                  onChanged: (v) => setState(() => _pattern = v ?? 'alpha'),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          foundationFieldLabel('Capacity per Section'),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
            SizedBox(
              width: 96,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: '$_capacity')..selection = TextSelection.collapsed(offset: '$_capacity'.length),
                onChanged: (v) => setState(() => _capacity = (int.tryParse(v) ?? 1).clamp(1, 200)),
                decoration: foundationFieldDecoration(),
              ),
            ),
            const Text('students · default 40 · max 200', style: TextStyle(fontSize: 12, color: Color(0xFF9FA6AD))),
          ]),
          if (_appliedPattern != null && _appliedPattern != _pattern && _selectedClsIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFFF8EC), border: Border.all(color: const Color(0xFFFFD166)), borderRadius: BorderRadius.circular(8)),
              child: Text.rich(TextSpan(style: const TextStyle(fontSize: 11, color: Color(0xFF7A5C00)), children: [
                const TextSpan(text: '⚠ Pattern changed from '),
                TextSpan(text: foundationSectionPatternLabels[_appliedPattern], style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: ' to '),
                TextSpan(text: foundationSectionPatternLabels[_pattern], style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: '. Clicking '),
                const TextSpan(text: 'Create Sections', style: TextStyle(fontStyle: FontStyle.italic)),
                const TextSpan(text: ' will remove the old sections and create new ones for the selected classes.'),
              ])),
            ),
          const SizedBox(height: 6),
          Row(children: [
            const Text('Preview: ', style: TextStyle(fontSize: 12, color: Color(0xFF6F767E))),
            Expanded(
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final n in _preview) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEEF0FF), border: Border.all(color: const Color(0xFFC7C3F0)), borderRadius: BorderRadius.circular(999)), child: Text(n, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5B4FCF)))),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: widget.onBack, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('← Back')),
            ElevatedButton(
              onPressed: (_creating || _selectedClsIds.isEmpty) ? null : _createSections,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(_creating ? 'Creating…' : '+ Create Sections'),
            ),
            OutlinedButton(
              onPressed: () => setState(() => _selectedClsIds.addAll(widget.classes.map((c) => c.id))),
              style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFEEF0FF), foregroundColor: const Color(0xFF5B4FCF), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Select All Classes'),
            ),
            OutlinedButton(onPressed: widget.onNext, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Next: Subjects →')),
          ]),
        ],
      ),
    );
  }

  Widget _buildListCard(int allSectionsCount) {
    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text('Sections Created', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
              if (_selectMode)
                Wrap(children: [
                  TextButton(onPressed: () => setState(() => _selectedSecIds.addAll(_visibleClasses.expand((c) => c.sections).where((s) => !_pendingDeleteIds.contains(s.id)).map((s) => s.id))), child: const Text('Select All', style: TextStyle(fontSize: 11, color: Color(0xFF6F767E)))),
                  TextButton(onPressed: () => setState(() { _selectMode = false; _selectedSecIds.clear(); }), child: const Text('Cancel Selection', style: TextStyle(fontSize: 11, color: Color(0xFF6F767E)))),
                ])
              else
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                  const Text('Click ✏ to rename · ✕ to delete', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
                  if (allSectionsCount > 0) TextButton(onPressed: () => setState(() => _selectMode = true), child: const Text('Select', style: TextStyle(fontSize: 11, color: Color(0xFF5B4FCF)))),
                ]),
            ],
          ),
          if (_selectMode && _selectedSecIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFEEF0FF), border: Border.all(color: const Color(0xFFC7C4F0)), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Expanded(child: Text('${_selectedSecIds.length} section${_selectedSecIds.length != 1 ? 's' : ''} selected', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5B4FCF)))),
                TextButton(
                  onPressed: () => setState(() => _pendingBulkDelete = true),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, minimumSize: const Size(0, 26), padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Delete Selected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          const SizedBox(height: 6),
          if (allSectionsCount == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(children: [
                  Text('📂', style: TextStyle(fontSize: 26)),
                  SizedBox(height: 4),
                  Text('No sections yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6F767E))),
                  Text('Select classes and click Create Sections.', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
                ]),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final c in _visibleClasses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF6F767E))),
                            const SizedBox(height: 4),
                            Wrap(spacing: 8, runSpacing: 8, children: c.sections.where((s) => !_pendingDeleteIds.contains(s.id)).map((s) => _sectionChip(s)).toList()),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionChip(FoundationSection sec) {
    if (_renamingId == sec.id) {
      return SizedBox(
        width: 90,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 50,
            child: TextField(
              controller: _renameController,
              autofocus: true,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B4FCF)))),
              onSubmitted: (_) => _saveRename(sec),
            ),
          ),
          IconButton(onPressed: () => _saveRename(sec), icon: const Icon(Icons.check, size: 14), color: const Color(0xFF5B4FCF), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          IconButton(onPressed: () => setState(() => _renamingId = null), icon: const Icon(Icons.close, size: 14), color: const Color(0xFF9FA6AD), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
      );
    }

    if (_selectMode) {
      final sel = _selectedSecIds.contains(sec.id);
      return InkWell(
        onTap: () => setState(() => sel ? _selectedSecIds.remove(sec.id) : _selectedSecIds.add(sec.id)),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: sel ? const Color(0xFFEEF0FF) : const Color(0xFFF0F2F5), border: Border.all(color: sel ? const Color(0xFF5B4FCF) : const Color(0xFFE8ECEF)), borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 14, height: 14, alignment: Alignment.center, decoration: BoxDecoration(color: sel ? const Color(0xFF5B4FCF) : Colors.white, border: Border.all(color: sel ? const Color(0xFF5B4FCF) : const Color(0xFFD2D7DC)), borderRadius: BorderRadius.circular(3)), child: sel ? const Icon(Icons.check, size: 10, color: Colors.white) : null),
            const SizedBox(width: 6),
            Text(sec.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
            const SizedBox(width: 3),
            Text('(${sec.studentCount}/${sec.capacity})', style: const TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), border: Border.all(color: const Color(0xFFE8ECEF)), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(sec.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
        const SizedBox(width: 4),
        Text('(${sec.studentCount}/${sec.capacity})', style: const TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
        const SizedBox(width: 4),
        InkWell(onTap: () => setState(() { _renamingId = sec.id; _renameController.text = sec.name; }), child: const Padding(padding: EdgeInsets.all(2), child: Text('✏', style: TextStyle(fontSize: 10)))),
        InkWell(
          onTap: _deletingId == sec.id
              ? null
              : () {
                  setState(() => _pendingDelete = sec);
                  _scrollToDeleteConfirm();
                },
          child: Padding(padding: const EdgeInsets.all(2), child: Text(_deletingId == sec.id ? '…' : '✕', style: const TextStyle(fontSize: 10, color: Color(0xFF9FA6AD)))),
        ),
      ]),
    );
  }
}
