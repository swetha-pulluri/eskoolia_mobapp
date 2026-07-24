import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_dropdown.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_data.dart';
import '../../domain/models/student_record_audit.dart';
import '../providers/student_providers.dart';
import '../widgets/student_archive_reason_dialog.dart';
import '../widgets/student_pager_footer.dart';
import '../widgets/student_subpage_header.dart';

/// Deleted / Restore Students — mirrors frontend
/// components/students/StudentDeleteRecordPanel.tsx: a "Delete Records"
/// table (soft-delete / restore / superuser-only permanent-delete) plus an
/// "Audit Log" tab, both backed by real endpoints that map cleanly onto this
/// screen (`deleted_only`, `restore`, `soft-delete`, `permanent-delete`,
/// `record-audits` all already exist server-side — see student_repository.dart).
class StudentDeletedPage extends ConsumerStatefulWidget {
  const StudentDeletedPage({super.key});

  @override
  ConsumerState<StudentDeletedPage> createState() => _StudentDeletedPageState();
}

class _StudentDeletedPageState extends ConsumerState<StudentDeletedPage> {
  int _tab = 0; // 0 = Records, 1 = Audit Log

  final _searchController = TextEditingController();
  int? _classId;
  int? _sectionId;
  bool _deletedOnly = true;

  List<SchoolClass> _classes = [];
  bool _loadingClasses = true;

  List<StudentData> _records = [];
  int _totalCount = 0;
  int _page = 1;
  int _pageSize = 25;
  bool _loading = true;
  String? _error;

  final Set<int> _selectedIds = {};

  List<StudentRecordAudit> _audits = [];
  bool _loadingAudits = false;
  String? _auditError;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadRecords();
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
      setState(() {
        _classes = classes;
        _loadingClasses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingClasses = false);
    }
  }

  List<SectionData> get _sectionsForClass {
    if (_classId == null) return const [];
    final cls = _classes.where((c) => c.id == _classId).firstOrNull;
    return cls?.sections ?? const [];
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(studentRepositoryProvider).fetchStudentsFiltered(
            classId: _classId,
            sectionId: _sectionId,
            search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
            deletedOnly: _deletedOnly,
            page: _page,
            pageSize: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _records = page.results;
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

  Future<void> _loadAudits() async {
    setState(() {
      _loadingAudits = true;
      _auditError = null;
    });
    try {
      final audits = await ref.read(studentRepositoryProvider).fetchRecordAudits(
            classId: _classId,
            sectionId: _sectionId,
            search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _audits = audits;
        _loadingAudits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAudits = false;
        _auditError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _page = 1;
      _selectedIds.clear();
    });
    _loadRecords();
    if (_tab == 1) _loadAudits();
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    final reason = await showStudentArchiveReasonDialog(context, count: ids.length);
    if (reason == null) return;
    try {
      await ref.read(studentRepositoryProvider).archiveStudents(ids, reason: reason);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _loadRecords();
      _toast('${ids.length} record${ids.length == 1 ? '' : 's'} deleted.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _restoreSelected() async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    try {
      await ref.read(studentRepositoryProvider).restoreStudents(ids);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _loadRecords();
      _toast('${ids.length} record${ids.length == 1 ? '' : 's'} restored.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _restoreOne(StudentData s) async {
    try {
      await ref.read(studentRepositoryProvider).restoreStudents([s.id]);
      if (!mounted) return;
      _loadRecords();
      _toast('${s.fullName} restored.');
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
      _loadRecords();
      _toast('${s.fullName} deleted.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _permanentDelete(StudentData s) async {
    final confirmed = await _showPermanentDeleteDialog(s);
    if (confirmed != true) return;
    try {
      await ref.read(studentRepositoryProvider).permanentDeleteStudent(s.id);
      if (!mounted) return;
      _loadRecords();
      _toast('${s.fullName} permanently deleted.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<bool?> _showPermanentDeleteDialog(StudentData s) {
    final controller = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final matches = controller.text.trim() == s.fullName;
          return AlertDialog(
            title: const Text('Permanently delete this record?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This cannot be undone. Type the student\'s full name to confirm.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(hintText: 'Type full name here', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: matches ? () => Navigator.of(context).pop(true) : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                child: const Text('Permanently delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuperuser = ref.watch(authNotifierProvider).maybeWhen(
          authenticated: (user) => user.isSuperuser,
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _tab == 0 ? _loadRecords() : _loadAudits(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              StudentSubpageHeader(
                titlePlain: 'Delete Student ',
                titleAccent: 'Record',
                accentColor: const Color(0xFFDC2626),
                subtitle: 'Soft-delete, restore, and (for admins) permanently remove student records.',
                actions: [
                  OutlinedButton(
                    onPressed: () => context.go('/students'),
                    child: const Text('Student List'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/students/multi-subject-assignment'),
                    child: const Text('Multi Subject Assignment'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFilterBox(),
              const SizedBox(height: 12),
              _buildTabRow(),
              const SizedBox(height: 8),
              if (_tab == 0) _buildRecordsBody(isSuperuser) else _buildAuditBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Search by name or admission no…',
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDFE0EB))),
            ),
          ),
          const SizedBox(height: 10),
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
                  onChanged: _loadingClasses
                      ? null
                      : (v) => setState(() {
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
              Checkbox(
                value: _deletedOnly,
                onChanged: (v) => setState(() => _deletedOnly = v ?? true),
                visualDensity: VisualDensity.compact,
              ),
              const Text('Deleted only', style: TextStyle(fontSize: 13)),
              const Spacer(),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow() {
    return Row(
      children: [
        _tabButton('Delete Records', 0, const Color(0xFF1D4ED8)),
        const SizedBox(width: 8),
        _tabButton('Audit Log', 1, const Color(0xFF1D4ED8)),
      ],
    );
  }

  Widget _tabButton(String label, int index, Color activeColor) {
    final isActive = _tab == index;
    return InkWell(
      onTap: () {
        setState(() => _tab = index);
        if (index == 1 && _audits.isEmpty && !_loadingAudits) _loadAudits();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          border: Border.all(color: isActive ? activeColor : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildRecordsBody(bool isSuperuser) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Records — $_totalCount', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 10),
              DropdownButton<int>(
                value: _pageSize,
                underline: const SizedBox.shrink(),
                isDense: true,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                items: const [25, 50, 100]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n / page')))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _pageSize = v;
                    _page = 1;
                  });
                  _loadRecords();
                },
              ),
              const Spacer(),
              if (_selectedIds.isNotEmpty) ...[
                TextButton(onPressed: _deleteSelected, child: const Text('Delete Selected', style: TextStyle(color: Color(0xFFB45309)))),
                TextButton(onPressed: _restoreSelected, child: const Text('Restore Selected', style: TextStyle(color: Color(0xFF0284C7)))),
                TextButton(onPressed: () => setState(() => _selectedIds.clear()), child: const Text('Clear', style: TextStyle(color: Color(0xFF64748B)))),
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
                OutlinedButton(onPressed: _loadRecords, child: const Text('Retry')),
              ]),
            )
          else if (_records.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No records found.', style: TextStyle(color: Color(0xFF9CA0AE)))))
          else ...[
            for (final s in _records) _recordRow(s, isSuperuser),
            const SizedBox(height: 8),
            StudentPagerFooter(
              page: _page,
              pageSize: _pageSize,
              totalCount: _totalCount,
              onPageChanged: (p) {
                setState(() => _page = p);
                _loadRecords();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _recordRow(StudentData s, bool isSuperuser) {
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
                  '${s.admissionNo} · ${s.className}${s.sectionName.isNotEmpty ? '/${s.sectionName}' : ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE)),
                ),
              ],
            ),
          ),
          if (s.isArchived)
            _rowIconButton(Icons.restore, const Color(0xFF0284C7), 'Restore', () => _restoreOne(s))
          else
            _rowIconButton(Icons.delete_outline, const Color(0xFFB45309), 'Delete', () => _deleteOne(s)),
          if (isSuperuser)
            _rowIconButton(Icons.delete_forever, const Color(0xFFDC2626), 'Permanently delete', () => _permanentDelete(s)),
        ],
      ),
    );
  }

  Widget _rowIconButton(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildAuditBody() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(12),
      child: _loadingAudits
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()))
          : _auditError != null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Text(_auditError!, style: const TextStyle(color: Color(0xFFB91C1C))),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _loadAudits, child: const Text('Retry')),
                  ]),
                )
              : _audits.isEmpty
                  ? const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No audit entries found.', style: TextStyle(color: Color(0xFF9CA0AE)))))
                  : Column(children: _audits.map(_auditRow).toList()),
    );
  }

  Widget _auditRow(StudentRecordAudit a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${a.studentName} · ${a.studentAdmissionNo}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Text(DateFormat('dd MMM, HH:mm').format(a.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
            ],
          ),
          const SizedBox(height: 2),
          Text('${a.actionLabel} · by ${a.performedByName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          if (a.note != null && a.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(a.note!, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
          ],
        ],
      ),
    );
  }
}
