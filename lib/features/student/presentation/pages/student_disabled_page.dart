import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_data.dart';
import '../providers/student_providers.dart';
import '../widgets/student_pager_footer.dart';
import '../widgets/student_subpage_header.dart';

/// Disabled Students — mirrors frontend
/// components/students/StudentDisabledPanel.tsx: students with
/// `is_disabled=true`, filterable by class/section/name/admission no, with
/// a per-row "Enable" action and a "Bulk Enable" action.
///
/// Backend gap (documented, not worked around by inventing an endpoint):
/// `StudentViewSet.get_queryset()` doesn't implement an `is_disabled` query
/// filter (only `search`/`is_active`/`class`/`section`/`deleted_only`/
/// `unassigned`/`academic_year` are recognised server-side) — the frontend
/// itself sends `is_disabled=true` but the backend silently ignores it and
/// returns all non-deleted students. Until that filter is added server-side
/// (TODO for the backend team), this screen fetches a large page of
/// non-deleted students and applies the `is_disabled` filter client-side,
/// then paginates locally over the filtered set.
class StudentDisabledPage extends ConsumerStatefulWidget {
  const StudentDisabledPage({super.key});

  @override
  ConsumerState<StudentDisabledPage> createState() => _StudentDisabledPageState();
}

class _StudentDisabledPageState extends ConsumerState<StudentDisabledPage> {
  final _searchController = TextEditingController();
  int? _classId;
  int? _sectionId;

  List<SchoolClass> _classes = [];
  List<StudentData> _allDisabled = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  static const _pageSize = 10;
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

  List<SectionData> get _sectionsForClass =>
      _classes.where((c) => c.id == _classId).firstOrNull?.sections ?? const [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(studentRepositoryProvider).fetchStudentsFiltered(
            classId: _classId,
            sectionId: _sectionId,
            search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
            page: 1,
            pageSize: 500,
          );
      if (!mounted) return;
      setState(() {
        _allDisabled = page.results.where((s) => s.isDisabled).toList();
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

  List<StudentData> get _pageResults {
    final start = (_page - 1) * _pageSize;
    if (start >= _allDisabled.length) return const [];
    return _allDisabled.sublist(start, (start + _pageSize).clamp(0, _allDisabled.length));
  }

  void _applyFilters() {
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

  Future<void> _enableOne(StudentData s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable this student?'),
        content: Text('${s.fullName} will be re-enabled and marked active.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Enable')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(studentRepositoryProvider).enableStudents([s.id]);
      if (!mounted) return;
      _load();
      _toast('${s.fullName} enabled.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _bulkEnable() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enable ${_selectedIds.length} students?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Enable')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(studentRepositoryProvider).enableStudents(_selectedIds.toList());
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _load();
      _toast('Students enabled.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageResults = _pageResults;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              StudentSubpageHeader(
                titlePlain: 'Disabled ',
                titleAccent: 'Students',
                accentColor: const Color(0xFF0284C7),
                subtitle: 'Students marked disabled — re-enable individually or in bulk.',
                actions: [
                  OutlinedButton(onPressed: () => context.go('/students'), child: const Text('Student List')),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdown<int>(
                            value: _classId,
                            hint: const Text('All classes', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All classes')),
                              ..._classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (v) => setState(() {
                              _classId = v;
                              _sectionId = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppDropdown<int>(
                            value: _sectionId,
                            hint: const Text('All sections', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All sections')),
                              ..._sectionsForClass.map((s) => DropdownMenuItem(value: s.id, child: Text('Section ${s.name}'))),
                            ],
                            onChanged: _classId == null ? null : (v) => setState(() => _sectionId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) => _applyFilters(),
                            decoration: InputDecoration(
                              hintText: 'Search by name or admission no…',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDFE0EB))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _applyFilters, child: const Text('Search')),
                      ],
                    ),
                  ],
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
                        Text('Disabled Students — ${_allDisabled.length}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const Spacer(),
                        if (_selectedIds.isNotEmpty)
                          TextButton(
                            onPressed: _bulkEnable,
                            child: Text('Bulk Enable (${_selectedIds.length})', style: const TextStyle(color: Color(0xFF0284C7))),
                          ),
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
                    else if (_allDisabled.isEmpty)
                      const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No Disabled Students Found', style: TextStyle(color: Color(0xFF9CA0AE)))))
                    else ...[
                      for (final s in pageResults) _row(s),
                      const SizedBox(height: 8),
                      StudentPagerFooter(
                        page: _page,
                        pageSize: _pageSize,
                        totalCount: _allDisabled.length,
                        onPageChanged: (p) => setState(() => _page = p),
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
                  '${s.admissionNo} · ${s.className}${s.sectionName.isNotEmpty ? '/${s.sectionName}' : ''} · ${s.guardianName ?? 'No guardian'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE)),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Enable student',
            child: IconButton(
              icon: const Icon(Icons.toggle_on_outlined, size: 20, color: Color(0xFF0284C7)),
              visualDensity: VisualDensity.compact,
              onPressed: () => _enableOne(s),
            ),
          ),
        ],
      ),
    );
  }
}
