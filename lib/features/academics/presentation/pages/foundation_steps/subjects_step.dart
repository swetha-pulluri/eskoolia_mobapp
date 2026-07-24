import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/class_entity.dart';
import '../../../domain/entities/subject_entry.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/foundation_widgets.dart';

const _typeChip = {
  'core': (Color(0xFFDBEAFE), Color(0xFF1D4ED8), 'Core'),
  'co_curricular': (Color(0xFFD1FAE5), Color(0xFF065F46), 'Co-curricular'),
  'optional': (Color(0xFFEDE9FE), Color(0xFF5B21B6), 'Optional'),
};

const _pillPalette = [
  (Color(0xFFFEF3C7), Color(0xFF92400E)),
  (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
  (Color(0xFFFCE7F3), Color(0xFF9D174D)),
  (Color(0xFFD1FAE5), Color(0xFF065F46)),
  (Color(0xFFEDE9FE), Color(0xFF5B21B6)),
  (Color(0xFFFEE2E2), Color(0xFF991B1B)),
  (Color(0xFFE0F2FE), Color(0xFF0369A1)),
  (Color(0xFFFDF4FF), Color(0xFF86198F)),
];

(Color, Color) _pillColor(String code) {
  var h = 0;
  for (final c in code.codeUnits) {
    h = (h * 31 + c) & 0xffff;
  }
  return _pillPalette[h % 8];
}

String? _validateSubjectName(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return 'Subject name cannot be empty.';
  if (v.length < 2) return 'Enter a valid subject name.';
  if (v.length > 50) return 'Maximum 50 characters allowed.';
  if (!RegExp(r'^[a-zA-Z0-9 &\-()]+$').hasMatch(v)) return 'Special characters are not allowed.';
  if (!RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Enter a valid subject name.';
  if (RegExp(r' {2,}').hasMatch(v)) return 'Enter a valid subject name.';
  if (RegExp(r'(.)\1{3,}', caseSensitive: false).hasMatch(v)) return 'Too many repeated characters in a row.';
  return null;
}

/// Step 4 — port of SubjectsPane.tsx.
class SubjectsStep extends ConsumerStatefulWidget {
  final List<FoundationClass> classes;
  final List<ClassSubjectEntry> entries;
  final List<String> globalSubjectNames;
  final Future<void> Function() onRefresh;
  final void Function(String message, {bool error}) showToast;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const SubjectsStep({
    super.key,
    required this.classes,
    required this.entries,
    required this.globalSubjectNames,
    required this.onRefresh,
    required this.showToast,
    required this.onBack,
    required this.onComplete,
  });

  @override
  ConsumerState<SubjectsStep> createState() => _SubjectsStepState();
}

class _SubjectsStepState extends ConsumerState<SubjectsStep> {
  int? _selCls;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String _type = 'core';
  final Set<int> _alsoAdd = {};
  bool _saving = false;
  bool _loadingDefaults = false;
  bool _resetting = false;
  String? _formErr;
  bool _dropdownOpen = false;

  int? _editingId;
  final _editNameController = TextEditingController();
  final _editCodeController = TextEditingController();
  String _editType = 'core';
  bool _editSaving = false;

  int? _togglingId;
  int? _deletingId;
  ClassSubjectEntry? _pendingDelete;
  bool _pendingReset = false;

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
  void initState() {
    super.initState();
    if (widget.classes.isNotEmpty) _selCls = widget.classes.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _editNameController.dispose();
    _editCodeController.dispose();
    super.dispose();
  }

  FoundationClass? get _selClass => widget.classes.where((c) => c.id == _selCls).firstOrNull;
  List<ClassSubjectEntry> get _classEntries => widget.entries.where((e) => e.schoolClassId == _selCls).toList();

  Future<void> _handleAdd() async {
    final name = _nameController.text.trim();
    final err = _validateSubjectName(name);
    if (name.isEmpty) {
      setState(() => _formErr = 'Subject name is required.');
      return;
    }
    if (err != null) {
      setState(() => _formErr = err);
      return;
    }
    if (_selCls == null) {
      setState(() => _formErr = 'Select a class first.');
      return;
    }
    if (_classEntries.any((e) => e.name.toLowerCase() == name.toLowerCase())) {
      setState(() => _formErr = 'A subject named "$name" already exists in this class.');
      return;
    }
    setState(() {
      _saving = true;
      _formErr = null;
    });
    try {
      final classIds = [_selCls!, ..._alsoAdd];
      final res = await ref.read(academicsRepositoryProvider).createSubjectEntry(classIds: classIds, name: name, code: _codeController.text.trim(), subjectType: _type);
      await widget.onRefresh();
      if (res.created > 0) {
        final skipped = res.errors.length;
        widget.showToast('Added "$name" to ${res.created} class(es)${skipped > 0 ? ' ($skipped skipped)' : ''}');
        _nameController.clear();
        _codeController.clear();
        setState(() => _alsoAdd.clear());
      } else {
        widget.showToast(res.errors.firstOrNull?.message ?? 'Already assigned.', error: true);
      }
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadDefaults() async {
    if (_selCls == null) {
      widget.showToast('Select a class first.', error: true);
      return;
    }
    setState(() => _loadingDefaults = true);
    final repo = ref.read(academicsRepositoryProvider);
    var added = 0;
    for (final sub in foundationDefaultSubjects) {
      if (_classEntries.any((e) => e.code == sub.$2)) continue;
      try {
        final res = await repo.createSubjectEntry(classIds: [_selCls!], name: sub.$1, code: sub.$2, subjectType: sub.$3, periodsPerWeek: sub.$4);
        if (res.data.isNotEmpty) added++;
      } catch (_) {
        // skip failures, matching the reference
      }
    }
    await widget.onRefresh();
    widget.showToast(added > 0 ? '$added default subject(s) loaded.' : 'All defaults already added.');
    if (mounted) setState(() => _loadingDefaults = false);
  }

  void _startEdit(ClassSubjectEntry e) {
    setState(() {
      _editingId = e.id;
      _editNameController.text = e.name;
      _editCodeController.text = e.code;
      _editType = e.subjectType;
    });
  }

  Future<void> _saveEdit(int id) async {
    if (_editNameController.text.trim().isEmpty) {
      widget.showToast('Subject name is required.', error: true);
      return;
    }
    setState(() => _editSaving = true);
    try {
      final entry = widget.entries.firstWhere((e) => e.id == id);
      await ref.read(academicsRepositoryProvider).updateSubjectEntry(id, name: _editNameController.text.trim(), code: _editCodeController.text.trim().toUpperCase(), subjectType: _editType, periodsPerWeek: entry.periodsPerWeek);
      widget.showToast('Subject updated.');
      setState(() => _editingId = null);
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _editSaving = false);
    }
  }

  Future<void> _toggleActive(ClassSubjectEntry e) async {
    setState(() => _togglingId = e.id);
    try {
      final updated = await ref.read(academicsRepositoryProvider).toggleSubjectEntryActive(e.id, !e.activeStatus);
      widget.showToast(updated.activeStatus ? 'Subject activated.' : 'Subject deactivated.');
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _togglingId = null);
    }
  }

  Future<void> _confirmDelete() async {
    final e = _pendingDelete;
    if (e == null) return;
    setState(() => _deletingId = e.id);
    try {
      await ref.read(academicsRepositoryProvider).deleteSubjectEntry(e.id);
      widget.showToast('Subject removed.');
      setState(() => _pendingDelete = null);
      await widget.onRefresh();
    } catch (_) {
      widget.showToast('This subject no longer exists.', error: true);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _doReset() async {
    if (_selCls == null) return;
    setState(() => _resetting = true);
    try {
      await ref.read(academicsRepositoryProvider).resetClassSubjects(_selCls!);
      widget.showToast('All subjects removed from ${_selClass?.name}.');
      setState(() => _pendingReset = false);
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalEntries = widget.entries.length;
    final countsByClass = <int, int>{};
    for (final e in widget.entries) {
      countsByClass[e.schoolClassId] = (countsByClass[e.schoolClassId] ?? 0) + 1;
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FoundationCard(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  const Text('SELECT CLASS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9FA6AD))),
                  ...widget.classes.map((c) {
                    final sel = _selCls == c.id;
                    return InkWell(
                      onTap: () => setState(() {
                        _selCls = sel ? null : c.id;
                        _alsoAdd.clear();
                        _formErr = null;
                        _page = 0;
                      }),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: sel ? const Color(0xFF5B4FCF) : Colors.white, border: Border.all(color: sel ? const Color(0xFF5B4FCF) : const Color(0xFFE8ECEF)), borderRadius: BorderRadius.circular(999)),
                        child: Text('${c.name}${(countsByClass[c.id] ?? 0) > 0 ? ' (${countsByClass[c.id]})' : ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF6F767E))),
                      ),
                    );
                  }),
                  OutlinedButton(
                    onPressed: (_loadingDefaults || _selCls == null) ? null : _loadDefaults,
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text(_loadingDefaults ? 'Loading...' : 'Load Defaults', style: const TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: totalEntries == 0 ? null : widget.onComplete,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFE8ECEF), disabledForegroundColor: const Color(0xFF9FA6AD), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Complete Setup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final form = _buildForm();
              final catalog = _buildCatalog();
              if (wide) return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 340, child: form), const SizedBox(width: 16), Expanded(child: catalog)]));
              return Column(children: [form, const SizedBox(height: 10), catalog]);
            }),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: widget.onBack, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Back', style: TextStyle(fontSize: 12))),
          ],
        ),
        if (_pendingDelete != null)
          FoundationConfirmDeleteDialog(
            key: _deleteConfirmKey,
            title: 'Remove Subject',
            message: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Remove '),
              TextSpan(text: '"${_pendingDelete!.name}"', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' from this class? Any teacher assignments and related links for this subject will also be removed.'),
            ])),
            confirmLabel: 'Remove',
            loading: _deletingId == _pendingDelete!.id,
            onConfirm: _confirmDelete,
            onCancel: () => setState(() => _pendingDelete = null),
          ),
        if (_pendingReset)
          FoundationConfirmDeleteDialog(
            title: 'Reset Class Subjects',
            message: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Remove '),
              const TextSpan(text: 'all subjects', style: TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' from '),
              TextSpan(text: _selClass?.name ?? 'this class', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: '? This cannot be undone and any teacher assignments linked to these subjects will also be removed.'),
            ])),
            confirmLabel: 'Reset',
            loading: _resetting,
            onConfirm: _doReset,
            onCancel: () => setState(() => _pendingReset = false),
          ),
      ],
    );
  }

  Widget _buildForm() {
    final filteredNames = _nameController.text.trim().isEmpty
        ? widget.globalSubjectNames
        : widget.globalSubjectNames.where((n) => n.toLowerCase().contains(_nameController.text.trim().toLowerCase())).toList();
    final invalid = _nameController.text.isNotEmpty && _validateSubjectName(_nameController.text) != null;

    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(TextSpan(style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)), children: [
            const TextSpan(text: 'Add Subject'),
            if (_selClass != null) TextSpan(text: ' — ${_selClass!.name}'),
          ])),
          if (_selClass != null)
            Text('Adds to ${_selClass!.name}${_alsoAdd.isNotEmpty ? ' + ${_alsoAdd.length} more class${_alsoAdd.length > 1 ? 'es' : ''}' : ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
          const SizedBox(height: 6),
          if (_formErr != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(8)),
              child: Text(_formErr!, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
            ),
          foundationFieldLabel('Subject Name', required: true),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() => _dropdownOpen = true),
            onTap: () => setState(() => _dropdownOpen = true),
            onSubmitted: (_) => _handleAdd(),
            decoration: foundationFieldDecoration(hint: 'e.g. Mathematics').copyWith(
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9FA6AD)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: invalid ? const Color(0xFFF87171) : const Color(0xFFE8ECEF), width: 1.5)),
            ),
          ),
          if (invalid) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_validateSubjectName(_nameController.text) ?? '', style: const TextStyle(fontSize: 11, color: Colors.red))),
          if (_dropdownOpen && filteredNames.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
              child: ListView(
                shrinkWrap: true,
                children: filteredNames
                    .map((n) => InkWell(
                          onTap: () => setState(() {
                            _nameController.text = n;
                            _dropdownOpen = false;
                          }),
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text(n, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D1F)))),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 6),
          Text.rich(TextSpan(style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6F767E)), children: const [TextSpan(text: 'Code '), TextSpan(text: '(optional)', style: TextStyle(fontWeight: FontWeight.normal, color: Color(0xFF9FA6AD)))])),
          const SizedBox(height: 3),
          TextField(controller: _codeController, maxLength: 20, textCapitalization: TextCapitalization.characters, decoration: foundationFieldDecoration(hint: 'e.g. MATH').copyWith(counterText: '')),
          const SizedBox(height: 6),
          foundationFieldLabel('Type'),
          DropdownButtonFormField<String>(
            initialValue: _type,
            isExpanded: true,
            decoration: foundationFieldDecoration(),
            items: subjectTypeOptions.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _type = v ?? 'core'),
          ),
          if (widget.classes.length > 1) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF4F4F4)),
            const SizedBox(height: 6),
            Row(children: [
              const Expanded(child: Text('ALSO ADD TO:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF9FA6AD)))),
              TextButton(onPressed: () => setState(() => _alsoAdd..clear()..addAll(widget.classes.where((c) => c.id != _selCls).map((c) => c.id))), child: const Text('Select All', style: TextStyle(fontSize: 10, color: Color(0xFF5B4FCF)))),
              TextButton(onPressed: () => setState(() => _alsoAdd.clear()), child: const Text('Clear', style: TextStyle(fontSize: 10, color: Color(0xFF9FA6AD)))),
            ]),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.classes.map((c) {
                final isCurrent = c.id == _selCls;
                final checked = _alsoAdd.contains(c.id);
                return InkWell(
                  onTap: isCurrent ? null : () => setState(() => checked ? _alsoAdd.remove(c.id) : _alsoAdd.add(c.id)),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFF4F4F4) : (checked ? const Color(0xFF5B4FCF) : Colors.white),
                      border: Border.all(color: isCurrent ? const Color(0xFFE8ECEF) : (checked ? const Color(0xFF5B4FCF) : const Color(0xFFE8ECEF))),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(c.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isCurrent ? const Color(0xFFC9CDD2) : (checked ? Colors.white : const Color(0xFF6F767E)))),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            OutlinedButton(onPressed: widget.onBack, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Back', style: TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: (_saving || _selCls == null || _validateSubjectName(_nameController.text) != null) ? null : _handleAdd,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(_saving ? 'Adding...' : '+ Add Subject', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCatalog() {
    final entries = _classEntries;
    final totalPages = (entries.length / _perPage).ceil();
    final safePage = totalPages > 0 ? _page.clamp(0, totalPages - 1) : 0;
    final pageEntries = entries.skip(safePage * _perPage).take(_perPage).toList();

    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Expanded(child: Text('Subject Catalog', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)))),
            if (entries.isNotEmpty && _selClass != null)
              OutlinedButton.icon(
                onPressed: _resetting ? null : () => setState(() => _pendingReset = true),
                icon: const Icon(Icons.delete_outline, size: 12),
                label: Text(_resetting ? 'Resetting...' : 'Reset Class', style: const TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade600, side: BorderSide(color: Colors.red.shade200), minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
          ]),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(children: [
                  const Icon(Icons.menu_book_outlined, size: 24, color: Color(0xFF9FA6AD)),
                  const SizedBox(height: 6),
                  Text(_selClass != null ? '0 subjects for ${_selClass!.name} yet' : 'Select a class to view subjects', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6F767E))),
                  const Text('Use the form on the left to add subjects.', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
                ]),
              ),
            )
          else ...[
            for (final e in pageEntries) _entryRow(e),
            if (totalPages > 1) ...[
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${safePage * _perPage + 1}–${safePage * _perPage + pageEntries.length} of ${entries.length}', style: const TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(onPressed: safePage == 0 ? null : () => setState(() => _page = safePage - 1), icon: const Icon(Icons.chevron_left, size: 18), visualDensity: VisualDensity.compact),
                  Text('${safePage + 1} / $totalPages', style: const TextStyle(fontSize: 10, color: Color(0xFF6F767E))),
                  IconButton(onPressed: safePage >= totalPages - 1 ? null : () => setState(() => _page = safePage + 1), icon: const Icon(Icons.chevron_right, size: 18), visualDensity: VisualDensity.compact),
                ]),
              ]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _entryRow(ClassSubjectEntry e) {
    if (_editingId == e.id) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF5F4FF), border: Border.all(color: const Color(0xFF5B4FCF)), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              SizedBox(width: 140, child: TextField(controller: _editNameController, style: const TextStyle(fontSize: 13), decoration: const InputDecoration(isDense: true, hintText: 'Subject name', filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()))),
              SizedBox(width: 70, child: TextField(controller: _editCodeController, maxLength: 20, textCapitalization: TextCapitalization.characters, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, hintText: 'Code', filled: true, fillColor: Colors.white, counterText: '', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()))),
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<String>(
                  initialValue: _editType,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                  items: subjectTypeOptions.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _editType = v ?? 'core'),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: _editSaving ? null : () => setState(() => _editingId = null), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), minimumSize: const Size(0, 26), padding: const EdgeInsets.symmetric(horizontal: 10)), child: const Text('Cancel', style: TextStyle(fontSize: 11))),
              const SizedBox(width: 6),
              ElevatedButton(onPressed: _editSaving ? null : () => _saveEdit(e.id), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, minimumSize: const Size(0, 26), padding: const EdgeInsets.symmetric(horizontal: 10)), child: Text(_editSaving ? 'Saving...' : 'Save', style: const TextStyle(fontSize: 11))),
            ]),
          ],
        ),
      );
    }

    final chip = _typeChip[e.subjectType] ?? (const Color(0xFFF4F4F4), const Color(0xFF6F767E), e.subjectType);
    final pill = _pillColor(e.code);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF4F4F4)), borderRadius: BorderRadius.circular(8)),
      child: Opacity(
        opacity: e.activeStatus ? 1 : 0.6,
        child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: pill.$1, borderRadius: BorderRadius.circular(6)), child: Text(e.code, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pill.$2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D1F), decoration: e.activeStatus ? null : TextDecoration.lineThrough), overflow: TextOverflow.ellipsis),
                Wrap(spacing: 4, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: chip.$1, borderRadius: BorderRadius.circular(4)), child: Text(chip.$3, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: chip.$2))),
                  if (!e.activeStatus) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)), child: const Text('Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)))),
                ]),
              ],
            ),
          ),
          IconButton(onPressed: () => _startEdit(e), icon: const Icon(Icons.edit_outlined, size: 14), color: const Color(0xFF6F767E), tooltip: 'Edit subject', visualDensity: VisualDensity.compact),
          IconButton(
            onPressed: _togglingId == e.id ? null : () => _toggleActive(e),
            icon: _togglingId == e.id ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(e.activeStatus ? Icons.remove : Icons.add, size: 14),
            color: e.activeStatus ? const Color(0xFF6F767E) : const Color(0xFF16A34A),
            tooltip: e.activeStatus ? 'Deactivate' : 'Activate',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: _deletingId == e.id
                ? null
                : () {
                    setState(() => _pendingDelete = e);
                    _scrollToDeleteConfirm();
                  },
            icon: _deletingId == e.id ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.close, size: 14),
            color: const Color(0xFF9FA6AD),
            tooltip: 'Remove subject',
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    );
  }
}
