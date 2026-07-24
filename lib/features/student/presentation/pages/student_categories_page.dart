import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/student_category_detail.dart';
import '../providers/student_providers.dart';
import '../widgets/student_subpage_header.dart';

/// Student Categories management — mirrors frontend
/// components/students/StudentCategoryManagerPanel.tsx: summary cards,
/// search/status filters, a table with per-row Edit/Delete, and bulk
/// Activate/Deactivate/Delete.
///
/// Disclosed gaps (backend confirmed NOT to support these — see research
/// notes in student_category_repository_impl.dart / datasource): no
/// `check-code` duplicate-check, no per-category `deactivate` action (delete
/// itself blocks with a plain error if students are still assigned), no
/// `export`, no AI-description-suggestion. None of those are faked here —
/// the corresponding frontend affordances are simply omitted rather than
/// wired to invented responses.
class StudentCategoriesPage extends ConsumerStatefulWidget {
  const StudentCategoriesPage({super.key});

  @override
  ConsumerState<StudentCategoriesPage> createState() => _StudentCategoriesPageState();
}

class _StudentCategoriesPageState extends ConsumerState<StudentCategoriesPage> {
  final _searchController = TextEditingController();
  String? _statusFilter; // null=all, 'active', 'inactive'

  List<StudentCategoryDetail> _categories = [];
  StudentCategorySummary? _summary;
  bool _loading = true;
  String? _error;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(studentCategoryRepositoryProvider);
      final results = await Future.wait([
        repo.fetchCategories(
          search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          status: _statusFilter,
        ),
        repo.fetchSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<StudentCategoryDetail>;
        _summary = results[1] as StudentCategorySummary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981)),
    );
  }

  Future<void> _openEditor({StudentCategoryDetail? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryEditorDialog(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _delete(StudentCategoryDetail c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${c.name}"?'),
        content: Text(
          c.studentsCount > 0
              ? 'This category has ${c.studentsCount} student(s) assigned. Deleting may be blocked by the server until they are reassigned.'
              : 'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(studentCategoryRepositoryProvider).deleteCategory(c.id);
      if (!mounted) return;
      _load();
      _toast('Category deleted.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _bulkSetStatus(String status) async {
    if (_selectedIds.isEmpty) return;
    try {
      await ref.read(studentCategoryRepositoryProvider).bulkSetStatus(_selectedIds.toList(), status: status);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _load();
      _toast('Categories updated.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedIds.length} categories?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(studentCategoryRepositoryProvider).bulkDelete(_selectedIds.toList());
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _load();
      _toast('Categories deleted.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              StudentSubpageHeader(
                titlePlain: 'Student ',
                titleAccent: 'Categories',
                accentColor: const Color(0xFF6C3CE1),
                subtitle: 'General/OBC/SC/ST/EWS and other admission categories.',
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Category'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_summary != null) _buildSummaryCards(_summary!),
              const SizedBox(height: 12),
              _buildFilterRow(),
              const SizedBox(height: 12),
              _buildTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(StudentCategorySummary s) {
    return Row(
      children: [
        Expanded(child: _summaryCard('Total Categories', '${s.totalCount}')),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('Active', '${s.activeCount}')),
      ],
    );
  }

  Widget _summaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE9EDF5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Search categories…',
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDFE0EB))),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _statusChip('All', null),
              _statusChip('Active', 'active'),
              _statusChip('Inactive', 'inactive'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String? value) {
    final isActive = _statusFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _statusFilter = value);
        _load();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4338CA) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('${_selectedIds.length} selected', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(onPressed: () => _bulkSetStatus('active'), child: const Text('Activate')),
                  TextButton(onPressed: () => _bulkSetStatus('inactive'), child: const Text('Deactivate')),
                  TextButton(
                    onPressed: _bulkDelete,
                    child: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                  ),
                ],
              ),
            ),
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ]),
            )
          else if (_categories.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No categories found.', style: TextStyle(color: Color(0xFF9CA0AE)))))
          else
            for (final c in _categories) _categoryRow(c),
        ],
      ),
    );
  }

  Widget _categoryRow(StudentCategoryDetail c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFD), borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _selectedIds.contains(c.id),
            onChanged: (v) => setState(() {
              if (v == true) {
                _selectedIds.add(c.id);
              } else {
                _selectedIds.remove(c.id);
              }
            }),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.isActive ? const Color(0xFFECFDF3) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        c.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.isActive ? const Color(0xFF047857) : const Color(0xFF4B5563)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.code.isEmpty ? 'No code' : c.code} · ${c.studentsCount} student${c.studentsCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE)),
                ),
                if (c.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(c.description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4338CA)),
            visualDensity: VisualDensity.compact,
            onPressed: () => _openEditor(existing: c),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
            visualDensity: VisualDensity.compact,
            onPressed: () => _delete(c),
          ),
        ],
      ),
    );
  }
}

class _CategoryEditorDialog extends ConsumerStatefulWidget {
  final StudentCategoryDetail? existing;
  const _CategoryEditorDialog({this.existing});

  @override
  ConsumerState<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends ConsumerState<_CategoryEditorDialog> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _codeController = TextEditingController(text: widget.existing?.code ?? '');
  late final _descriptionController = TextEditingController(text: widget.existing?.description ?? '');
  late bool _active = widget.existing?.isActive ?? true;
  bool _saving = false;
  String? _error;

  bool get isEditMode => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(studentCategoryRepositoryProvider);
      final taken = await repo.isNameTaken(name, excludeId: widget.existing?.id);
      if (taken) {
        setState(() {
          _saving = false;
          _error = 'A category with this name already exists.';
        });
        return;
      }
      if (isEditMode) {
        await repo.updateCategory(
          widget.existing!.id,
          name: name,
          description: _descriptionController.text.trim(),
          code: _codeController.text.trim(),
          status: _active ? 'active' : 'inactive',
        );
      } else {
        await repo.createCategory(
          name: name,
          description: _descriptionController.text.trim(),
          code: _codeController.text.trim(),
          status: _active ? 'active' : 'inactive',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditMode ? 'Edit Category' : 'New Category', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Short code', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              Row(
                children: [
                  const Text('Active', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Switch(value: _active, onChanged: (v) => setState(() => _active = v)),
                ],
              ),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white),
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEditMode ? 'Save' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
