import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_data.dart';
import '../providers/student_providers.dart';
import '../widgets/student_archive_reason_dialog.dart';
import '../widgets/student_pager_footer.dart';
import '../widgets/student_subpage_header.dart';

/// Unassigned Students — mirrors frontend
/// components/students/StudentUnassignedPanel.tsx: students with no
/// current_class/current_section, with search, per-row Edit/Assign/Delete,
/// and bulk "Assign to Class"/"Delete Selected". The `unassigned=true`
/// query param already maps cleanly onto the real backend list endpoint.
class StudentUnassignedPage extends ConsumerStatefulWidget {
  const StudentUnassignedPage({super.key});

  @override
  ConsumerState<StudentUnassignedPage> createState() => _StudentUnassignedPageState();
}

class _StudentUnassignedPageState extends ConsumerState<StudentUnassignedPage> {
  final _searchController = TextEditingController();

  List<SchoolClass> _classes = [];
  List<StudentData> _students = [];
  int _totalCount = 0;
  int _page = 1;
  static const _pageSize = 10;
  bool _loading = true;
  String? _error;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await ref.read(studentRepositoryProvider).fetchClasses();
      if (!mounted) return;
      setState(() => _classes = classes);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(studentRepositoryProvider).fetchStudentsFiltered(
            search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
            unassigned: true,
            page: _page,
            pageSize: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _students = page.results;
        _totalCount = page.count;
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

  void _search() {
    setState(() {
      _page = 1;
      _selectedIds.clear();
    });
    _load();
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981)),
    );
  }

  Future<(int classId, int sectionId)?> _pickClassSection() async {
    int? classId;
    int? sectionId;
    return showDialog<(int, int)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final sections = _classes.where((c) => c.id == classId).firstOrNull?.sections ?? const [];
          return AlertDialog(
            title: const Text('Assign to class'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDropdown<int>(
                  value: classId,
                  hint: const Text('Select class', style: TextStyle(fontSize: 12)),
                  items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setDialogState(() {
                    classId = v;
                    sectionId = null;
                  }),
                ),
                const SizedBox(height: 10),
                AppDropdown<int>(
                  value: sectionId,
                  hint: const Text('Select section', style: TextStyle(fontSize: 12)),
                  items: sections.map((s) => DropdownMenuItem(value: s.id, child: Text('Section ${s.name}'))).toList(),
                  onChanged: classId == null ? null : (v) => setDialogState(() => sectionId = v),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (classId != null && sectionId != null)
                    ? () => Navigator.of(context).pop((classId!, sectionId!))
                    : null,
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _assignOne(StudentData s) async {
    final picked = await _pickClassSection();
    if (picked == null) return;
    try {
      await ref.read(studentRepositoryProvider).assignClassSection([s.id], classId: picked.$1, sectionId: picked.$2);
      if (!mounted) return;
      _load();
      _toast('${s.fullName} assigned to class.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _bulkAssign() async {
    if (_selectedIds.isEmpty) return;
    final picked = await _pickClassSection();
    if (picked == null) return;
    try {
      await ref.read(studentRepositoryProvider).assignClassSection(
            _selectedIds.toList(),
            classId: picked.$1,
            sectionId: picked.$2,
          );
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _load();
      _toast('Students assigned to class.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _deleteOne(StudentData s) async {
    final reason = await showStudentArchiveReasonDialog(context, count: 1);
    if (reason == null) return;
    try {
      await ref.read(studentRepositoryProvider).archiveStudents([s.id], reason: reason);
      if (!mounted) return;
      _load();
      _toast('${s.fullName} deleted.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final reason = await showStudentArchiveReasonDialog(context, count: _selectedIds.length);
    if (reason == null) return;
    try {
      await ref.read(studentRepositoryProvider).archiveStudents(_selectedIds.toList(), reason: reason);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _load();
      _toast('Students deleted.');
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
                titlePlain: 'Unassigned ',
                titleAccent: 'Students',
                accentColor: const Color(0xFF16A34A),
                subtitle: 'Students with no current class or section assigned.',
                actions: [
                  OutlinedButton(
                    onPressed: () => context.push('/students/multi-subject-assignment'),
                    child: const Text('Multi Subject Assignment'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/students/deleted'),
                    child: const Text('Delete Student Record'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Search by name or admission no…',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDFE0EB))),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Records Found: $_totalCount', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const Spacer(),
                        if (_selectedIds.isNotEmpty) ...[
                          TextButton(onPressed: _bulkAssign, child: const Text('Bulk Assign to Class', style: TextStyle(color: Color(0xFF1D4ED8)))),
                          TextButton(onPressed: _deleteSelected, child: const Text('Delete Selected', style: TextStyle(color: Color(0xFFDC2626)))),
                        ],
                      ],
                    ),
                    const Divider(),
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
                    else if (_students.isEmpty)
                      const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No Students Found', style: TextStyle(color: Color(0xFF9CA0AE)))))
                    else ...[
                      for (final s in _students) _row(s),
                      const SizedBox(height: 8),
                      StudentPagerFooter(
                        page: _page,
                        pageSize: _pageSize,
                        totalCount: _totalCount,
                        onPageChanged: (p) {
                          setState(() => _page = p);
                          _load();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(StudentData s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFD), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Checkbox(
            value: _selectedIds.contains(s.id),
            onChanged: (v) => setState(() {
              if (v == true) {
                _selectedIds.add(s.id);
              } else {
                _selectedIds.remove(s.id);
              }
            }),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${s.admissionNo} · ${s.guardianName ?? 'No guardian'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE)),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Edit student',
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final saved = await context.push<bool>('/students/enroll', extra: s);
                if (saved == true) _load();
              },
            ),
          ),
          Tooltip(
            message: 'Assign class',
            child: IconButton(
              icon: const Icon(Icons.school_outlined, size: 18, color: Color(0xFF0F766E)),
              visualDensity: VisualDensity.compact,
              onPressed: () => _assignOne(s),
            ),
          ),
          Tooltip(
            message: 'Delete',
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
              visualDensity: VisualDensity.compact,
              onPressed: () => _deleteOne(s),
            ),
          ),
        ],
      ),
    );
  }
}
