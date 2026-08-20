import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/designation_entity.dart';
import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/hr_repository.dart';
import '../providers/hr_provider.dart';
import '../widgets/hr_layout.dart';

const _brand = Color(0xFF6D4AFF);
const _strong = Color(0xFF4F35CC);
const _soft = Color(0xFFEEEAFF);
const _ink = Color(0xFF15172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE8E8EE);

/// A literal port of the real, deployed `HrDirectoryPage`
/// (`app/(dashboard)/hr/directory/page.tsx` on `origin/demo` — the branch
/// actually running the real "Staff list & Onboarding" page; `main`'s own
/// dormant `HrStaffDirectoryPanel` is NOT what's really deployed here).
///
/// Fields the real page references that exist on NEITHER backend I could
/// find (`hra`/`da`/`travel_allowance`/`medical_allowance`/
/// `special_allowance`/`is_present`/`classes_subjects`) are shown as "—",
/// matching the real page's own fallback for missing data — not fabricated.
/// "Onboard Staff" opens this app's own 5-tab Add/Edit form (verified
/// against the real, working `/api/v1/hr/staff/` API) rather than the real
/// page's 10-step `/hr/onboard` wizard, whose entire backend (drafts,
/// document upload, blank/filled PDF forms, master-data lookups) does not
/// exist on the currently-running server — building it would mean 100%
/// non-functional UI, so it was intentionally not built this pass.
class StaffDirectoryPage extends ConsumerStatefulWidget {
  const StaffDirectoryPage({super.key});

  @override
  ConsumerState<StaffDirectoryPage> createState() => _StaffDirectoryPageState();
}

class _StaffDirectoryPageState extends ConsumerState<StaffDirectoryPage> {
  final _searchCtrl = TextEditingController();
  bool _filterOpen = false;
  int? _openDeptId; // null key = -1 for "Unassigned"
  bool _expandAll = false;
  final Set<int> _selected = {};
  String? _error;
  String? _success;
  bool _bulkBusy = false;
  /// Matches the real `HrDirectoryPage`'s own "Employment" `<select>` exactly
  /// — it has no `value`/`onChange` there either (Full-time/Part-time/
  /// Contract don't correspond to any real `Staff` field; the closest real
  /// column, `contract_type`, only has Permanent/Contract). Kept local-only
  /// and purely visual, matching the real page's own non-functional state,
  /// rather than inventing a mapping to real data that doesn't exist.
  String _employmentDisplay = 'All types';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runSearch() {
    ref.read(staffSearchProvider.notifier).state = _searchCtrl.text.trim();
    ref.read(staffPageProvider.notifier).state = 1;
  }

  void _toggleDept(int key) {
    setState(() {
      _expandAll = false;
      _openDeptId = _openDeptId == key ? null : key;
    });
  }

  void _collapseAll() => setState(() {
        _expandAll = false;
        _openDeptId = null;
      });

  void _expandAllTap() => setState(() {
        _expandAll = true;
        _openDeptId = null;
      });

  void _toggleSelect(int id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      });

  /// Direct file download — matches web's own `<a download>` CSV export
  /// exactly, via the app-wide `saveBytesForDownload` helper (the same
  /// convention already used for School Tenancy's exports): zero-dialog
  /// Blob+anchor-click download on web, no share-to-other-apps sheet.
  Future<void> _exportCsv(List<StaffEntity> rows) async {
    try {
      String quote(String v) => '"${v.replaceAll('"', '""')}"';
      final headers = ['Staff ID', 'First Name', 'Last Name', 'Department', 'Designation', 'Joining Date', 'Status', 'Mobile', 'Email'];
      final departments = ref.read(allDepartmentsProvider).valueOrNull?.results ?? const <DepartmentEntity>[];
      final designations = ref.read(designationsProvider).valueOrNull?.results ?? const <DesignationEntity>[];
      String deptName(int? id) => departments.where((d) => d.id == id).map((d) => d.name).firstOrNull ?? '';
      String desigName(int? id) => designations.where((d) => d.id == id).map((d) => d.name).firstOrNull ?? '';
      final lines = rows.map((s) => [
            quote(s.staffNo),
            quote(s.firstName),
            quote(s.lastName),
            quote(deptName(s.departmentId)),
            quote(desigName(s.designationId)),
            quote(s.joinDate),
            quote(s.status),
            quote(s.phone),
            quote(s.email),
          ].join(','));
      final csv = [headers.join(','), ...lines].join('\n');
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final filename = 'staff_directory_${DateTime.now().toIso8601String().split('T').first}.csv';
      await saveBytesForDownload(bytes: bytes, filename: filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff directory exported.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _bulkDeactivate(List<StaffEntity> selectedStaff) async {
    setState(() => _bulkBusy = true);
    try {
      final repo = ref.read(hrRepositoryProvider);
      for (final s in selectedStaff) {
        await repo.updateStaffStatus(s.id, 'inactive');
      }
      if (!mounted) return;
      setState(() {
        _success = '${selectedStaff.length} staff member${selectedStaff.length != 1 ? 's' : ''} deactivated.';
        _selected.clear();
      });
      invalidateStaffDirectory(ref);
    } catch (e) {
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Unable to update some staff records.');
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _bulkDelete(List<StaffEntity> selectedStaff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected staff'),
        content: Text('Delete ${selectedStaff.length} selected staff member${selectedStaff.length != 1 ? 's' : ''}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE0463A)), onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _bulkBusy = true);
    try {
      final repo = ref.read(hrRepositoryProvider);
      for (final s in selectedStaff) {
        await repo.deleteStaff(s.id);
      }
      if (!mounted) return;
      setState(() {
        _success = '${selectedStaff.length} staff member${selectedStaff.length != 1 ? 's' : ''} deleted.';
        _selected.clear();
      });
      invalidateStaffDirectory(ref);
    } catch (e) {
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Unable to delete some staff records.');
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  void _showProfileDrawer(StaffEntity s, String deptName, String desigName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close staff profile',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: Material(
              child: SizedBox(
                // Was a hardcoded `width: 360` — wider than a 320-360dp
                // phone screen, so it wouldn't fit on real narrow devices.
                // Cap to the actual screen width so the drawer never asks
                // for more room than exists.
                width: math.min(MediaQuery.sizeOf(context).width, 360.0),
                height: double.infinity,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(radius: 28, backgroundColor: _brand, child: Text(_initials(s), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.fullName.isEmpty ? s.staffNo : s.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                              Text('$desigName · $deptName', style: const TextStyle(fontSize: 12, color: _muted)),
                              Text(s.staffNo, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ]),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                        ]),
                        const Divider(height: 32),
                        _drawerSection('Contact', [
                          _drawerInfo('Mobile', s.phone.isEmpty ? '—' : s.phone),
                          _drawerInfo('Official Email', s.officialEmail.isNotEmpty ? s.officialEmail : (s.email.isNotEmpty ? s.email : '—')),
                          if (s.personalEmail.isNotEmpty) _drawerInfo('Personal Email', s.personalEmail),
                          _drawerInfo('WhatsApp', s.whatsapp.isEmpty ? '—' : s.whatsapp),
                        ]),
                        // "Type"/"Reports to" are always "—" here — matching a real, confirmed
                        // limitation in the live web's own drawer: it reads `staff.employment_type`/
                        // `staff.reporting_manager_name` as flat Staff fields, but neither exists on
                        // the real `StaffSerializer` (verified read-only) — those values only ever
                        // live in the onboarding wizard's `custom_field` blob, which this drawer
                        // never reads. Preserved as-is rather than silently "fixed" beyond web.
                        _drawerSection('Employment', [
                          _drawerInfo('Joining', s.joinDate.isEmpty ? '—' : s.joinDate),
                          _drawerInfo('Type', '—'),
                          _drawerInfo('Status', s.status),
                          _drawerInfo('Reports to', '—'),
                        ]),
                        _drawerSection('Compensation', [
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(color: _soft, border: Border.all(color: const Color(0xFFDDD6FE)), borderRadius: BorderRadius.circular(12)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('GROSS MONTHLY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _muted, letterSpacing: 1)),
                              Text('₹${s.basicSalary}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _brand)),
                            ]),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drawerSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _muted, letterSpacing: 1)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _drawerInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        Flexible(child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink))),
      ]),
    );
  }

  static String _initials(StaffEntity s) {
    final full = s.fullName;
    final parts = full.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0].toUpperCase();
    final second = parts.length > 1 ? parts[1][0].toUpperCase() : '';
    return '$first$second';
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffDirectoryProvider);
    final departmentsAsync = ref.watch(allDepartmentsProvider);
    final designationsAsync = ref.watch(designationsProvider);
    final todayAttendanceAsync = ref.watch(todayAttendanceProvider);
    // Matches the real `Department` model's own `Meta.ordering = ["name"]` —
    // sorted explicitly here rather than trusting the backend response order,
    // since an `annotate(staff_count=...)` on the backend queryset can
    // silently disrupt that default ordering.
    final departments = [...departmentsAsync.valueOrNull?.results ?? const <DepartmentEntity>[]]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final designations = designationsAsync.valueOrNull?.results ?? const <DesignationEntity>[];
    final loading = staffAsync.isLoading;
    final departmentFilter = ref.watch(staffDepartmentFilterProvider);
    final statusFilter = ref.watch(staffStatusFilterProvider);
    final presentTodayFilter = ref.watch(staffPresentTodayFilterProvider);

    final presentStaffIds = <int>{
      for (final a in todayAttendanceAsync.valueOrNull?.results ?? const <StaffAttendanceEntity>[])
        if (a.attendanceType == 'P') a.staffId,
    };
    final allStaff = staffAsync.valueOrNull?.results ?? const <StaffEntity>[];
    final staffList = presentTodayFilter == 'any'
        ? allStaff
        : allStaff.where((s) => presentTodayFilter == 'present' ? presentStaffIds.contains(s.id) : !presentStaffIds.contains(s.id)).toList();

    final grouped = <({int key, String name, List<StaffEntity> staff})>[];
    for (final d in departments) {
      final items = staffList.where((s) => s.departmentId == d.id).toList();
      grouped.add((key: d.id, name: d.name, staff: items));
    }
    final unassigned = staffList.where((s) => s.departmentId == null).toList();
    if (unassigned.isNotEmpty) grouped.add((key: -1, name: 'Unassigned', staff: unassigned));

    final totalStaff = staffList.length;
    final totalActive = staffList.where((s) => s.status == 'active').length;
    final selectedStaff = staffList.where((s) => _selected.contains(s.id)).toList();

    return HrLayout(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(loading, staffList),
                const SizedBox(height: 12),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFD97706)))),
                if (_success != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_success!, style: const TextStyle(color: Color(0xFF16A34A)))),
                _buildSmartFilter(departments, departmentFilter, statusFilter, presentTodayFilter),
                const SizedBox(height: 12),
                _buildSearchRow(staffList),
                const SizedBox(height: 12),
                _buildAllStaffCard(grouped, designations, loading, totalStaff, totalActive, staffList, presentStaffIds),
              ],
            ),
          ),
          if (selectedStaff.isNotEmpty) _buildBulkBar(selectedStaff),
        ],
      ),
    );
  }

  // Was a Row(Expanded(title column) + Wrap(action buttons)) — a Row's
  // non-flex children (the button Wrap) are laid out with an unbounded
  // main-axis constraint, so they never actually wrap/shrink to make room;
  // confirmed via widget test to hard-overflow the RenderFlex at every
  // tested width from 320dp up to 412dp. Stacking the actions below the
  // title (both still full-width Column children) lets the Wrap receive a
  // real bounded width from its Column ancestor, so it can wrap the two
  // buttons onto their own line(s) and never overflow.
  Widget _buildHero(bool loading, List<StaffEntity> staffList) {
    // Own card — same white/gray-bordered style already used by
    // `_buildSmartFilter`/`_buildSearchRow`/`_buildAllStaffCard` below —
    // instead of floating text directly on the page background.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('STAFF RECORDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _muted)),
          const SizedBox(height: 4),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _ink),
              children: [TextSpan(text: 'Staff '), TextSpan(text: 'list & Onboarding', style: TextStyle(color: _brand, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400))],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Department parent accordions with staff child rows, fast filters, and profile details in a side panel.', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: staffList.isEmpty ? null : () => _exportCsv(staffList), child: const Text('Export CSV')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brand),
              onPressed: () => context.push('/hr/onboard'),
              child: const Text('Onboard Staff'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSmartFilter(List<DepartmentEntity> departments, int? departmentFilter, String statusFilter, String presentTodayFilter) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _filterOpen = !_filterOpen),
            child: Container(
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: _strong, width: 4))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                AnimatedRotation(turns: _filterOpen ? 0.5 : -0.25, duration: const Duration(milliseconds: 200), child: const Icon(Icons.keyboard_arrow_down, color: _brand)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Smart Filter & Bulk Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink)),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(spacing: 6, children: [
                        _chip(departmentFilter == null && statusFilter == 'all' && presentTodayFilter == 'any' ? 'No filters active' : 'Filters active'),
                        _chip('Grouped by department', tone: _soft, fg: _brand),
                      ]),
                    ),
                  ]),
                ),
                Text(_filterOpen ? 'Collapse' : 'Expand to filter', style: const TextStyle(fontSize: 12, color: _muted)),
              ]),
            ),
          ),
          if (_filterOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int?>(
                    initialValue: departmentFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All departments')),
                      for (final d in departments) DropdownMenuItem<int?>(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      ref.read(staffDepartmentFilterProvider.notifier).state = v;
                      ref.read(staffPageProvider.notifier).state = 1;
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: statusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (v) {
                      if (v != null) ref.read(staffStatusFilterProvider.notifier).state = v;
                      ref.read(staffPageProvider.notifier).state = 1;
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: _employmentDisplay,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Employment', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'All types', child: Text('All types')),
                      DropdownMenuItem(value: 'Full-time', child: Text('Full-time')),
                      DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
                      DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                    ],
                    // Intentionally does not filter anything — matches the
                    // real web's own unwired Employment select exactly.
                    onChanged: (v) => setState(() => _employmentDisplay = v ?? _employmentDisplay),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: presentTodayFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Present today', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'any', child: Text('Any')),
                      DropdownMenuItem(value: 'present', child: Text('Present')),
                      DropdownMenuItem(value: 'absent', child: Text('Absent')),
                    ],
                    onChanged: (v) {
                      if (v != null) ref.read(staffPresentTodayFilterProvider.notifier).state = v;
                    },
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(List<StaffEntity> staffList) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18, color: _brand), hintText: 'Search by name, ID, designation, phone…', border: InputBorder.none, isDense: true),
              onSubmitted: (_) => _runSearch(),
            ),
          ),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: _brand), onPressed: _runSearch, child: const Text('Search')),
          InkWell(
            onTap: () => setState(() {
              if (_selected.length == staffList.length) {
                _selected.clear();
              } else {
                _selected
                  ..clear()
                  ..addAll(staffList.map((s) => s.id));
              }
            }),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(
                value: staffList.isNotEmpty && _selected.length == staffList.length,
                onChanged: (_) => setState(() {
                  if (_selected.length == staffList.length) {
                    _selected.clear();
                  } else {
                    _selected
                      ..clear()
                      ..addAll(staffList.map((s) => s.id));
                  }
                }),
              ),
              const Text('Select all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5B5E72))),
            ]),
          ),
          TextButton.icon(onPressed: staffList.isEmpty ? null : () => _exportCsv(staffList), icon: const Icon(Icons.download, size: 14), label: const Text('Export')),
        ],
      ),
    );
  }

  Widget _buildAllStaffCard(
    List<({int key, String name, List<StaffEntity> staff})> grouped,
    List<DesignationEntity> designations,
    bool loading,
    int totalStaff,
    int totalActive,
    List<StaffEntity> staffList,
    Set<int> presentStaffIds,
  ) {
    final totalPresent = staffList.where((s) => presentStaffIds.contains(s.id)).length;
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            // Was a Row(Expanded(title) + 2 OutlinedButtons) — same
            // unbounded-non-flex-child issue as the hero row above: the two
            // buttons alone are wider than a 320-412dp row, confirmed via
            // widget test to overflow at every tested width. Stack the
            // title above a Wrap of the two buttons so they can wrap to
            // their own line and never overflow.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('All Staff', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink)),
                  Text('View opens a side hover panel. The table remains full width for large schools.', style: TextStyle(fontSize: 12, color: _muted)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton(onPressed: _collapseAll, child: const Text('Collapse all')),
                  OutlinedButton(onPressed: _expandAllTap, child: const Text('Expand all')),
                ]),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFFAFAFB),
            padding: const EdgeInsets.all(10),
            child: loading
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('Loading staff…', style: TextStyle(color: _muted))))
                : grouped.isEmpty
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No staff found.', style: TextStyle(color: _muted))))
                    : Column(children: [for (final g in grouped) _buildDeptAccordion(g, designations, presentStaffIds)]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('$totalStaff staff · $totalActive active · $totalPresent present today', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptAccordion(({int key, String name, List<StaffEntity> staff}) g, List<DesignationEntity> designations, Set<int> presentStaffIds) {
    final open = _expandAll || _openDeptId == g.key;
    final activeCount = g.staff.where((s) => s.status == 'active').length;
    final roleCount = g.staff.map((s) => s.designationId).where((d) => d != null).toSet().length;
    final presentCount = g.staff.where((s) => presentStaffIds.contains(s.id)).length;
    final presentPct = g.staff.isEmpty ? 0.0 : presentCount / g.staff.length * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleDept(g.key),
            child: Container(
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: _strong, width: 4))),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                AnimatedRotation(turns: open ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Department name is real, unbounded-length data (unlike
                    // the fixed English chip labels below it) — cap to one
                    // line with ellipsis so a long name can't push the fixed
                    // "Add staff" button/ring past the row's edge.
                    Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(spacing: 6, children: [
                        _chip('${g.staff.length} staff'),
                        _chip('$activeCount active', tone: const Color(0xFFECFDF5), fg: const Color(0xFF059669)),
                        _chip('$roleCount roles', tone: _soft, fg: _brand),
                        _chip('$presentCount present today', tone: const Color(0xFFEFF6FF), fg: const Color(0xFF2563EB)),
                      ]),
                    ),
                  ]),
                ),
                if (g.key != -1) ...[
                  // Compact padding/tap-target — the default OutlinedButton
                  // padding pushed this row's non-flex total (icon + button
                  // + ring) past a 320dp row's available width, confirmed
                  // via widget test (18px hard overflow with a real long
                  // department name). Same label/icon/color, just tighter.
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => context.push('/hr/onboard?department=${g.key}'),
                    icon: const Icon(Icons.add, size: 13),
                    label: const Text('Add staff', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  _PresentTodayRing(pct: presentPct),
                ],
              ]),
            ),
          ),
          if (open) _buildStaffTable(g.staff, designations),
        ],
      ),
    );
  }

  Widget _buildStaffTable(List<StaffEntity> staff, List<DesignationEntity> designations) {
    String desigName(int? id) => id == null ? '—' : (designations.where((d) => d.id == id).map((d) => d.name).firstOrNull ?? '—');

    if (staff.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No staff in this department yet.', style: TextStyle(color: _muted, fontSize: 13))));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 18,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFFBFCFE)),
        columns: const [
          DataColumn(label: SizedBox()),
          DataColumn(label: Text('STAFF')),
          DataColumn(label: Text('STAFF ID')),
          DataColumn(label: Text('DESIGNATION')),
          DataColumn(label: Text('JOINING')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('SALARY')),
          DataColumn(label: Text('ACTIONS')),
        ],
        rows: [
          for (final s in staff)
            DataRow(
              selected: _selected.contains(s.id),
              cells: [
                DataCell(Checkbox(value: _selected.contains(s.id), onChanged: (_) => _toggleSelect(s.id))),
                DataCell(SizedBox(
                  width: 180,
                  child: Row(children: [
                    CircleAvatar(radius: 15, backgroundColor: _brand, child: Text(_initials(s), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(s.fullName.isEmpty ? s.staffNo : s.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
                        Text('${desigName(s.designationId)}${s.phone.isNotEmpty ? ' · ${s.phone}' : ''}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _muted)),
                      ]),
                    ),
                  ]),
                )),
                DataCell(Text(s.staffNo.isEmpty ? '—' : s.staffNo)),
                DataCell(Text(desigName(s.designationId))),
                DataCell(Text(s.joinDate.isEmpty ? '—' : s.joinDate)),
                DataCell(_statusPill(s.status)),
                DataCell(Text('₹${s.basicSalary}', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.visibility_outlined, size: 17), tooltip: 'View', onPressed: () => _showProfileDrawer(s, _deptNameFor(s.departmentId), desigName(s.designationId))),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF0EA5E9)), tooltip: 'Edit', onPressed: () => context.push('/hr/onboard?edit=${s.id}')),
                  IconButton(icon: const Icon(Icons.description_outlined, size: 17), tooltip: 'Documents', onPressed: () => context.push('/hr/onboard?edit=${s.id}&step=9')),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_horiz, size: 17),
                    onSelected: (action) {
                      if (action == 'toggle_status') _toggleActive(s);
                      if (action == 'delete') _deleteOne(s);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'toggle_status', child: Text(s.status == 'active' ? 'Deactivate' : 'Activate')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Color(0xFFE0463A)))),
                    ],
                  ),
                ])),
              ],
            ),
        ],
      ),
    );
  }

  String _deptNameFor(int? id) {
    final departments = ref.read(allDepartmentsProvider).valueOrNull?.results ?? const <DepartmentEntity>[];
    return id == null ? 'Unassigned' : (departments.where((d) => d.id == id).map((d) => d.name).firstOrNull ?? '—');
  }

  Future<void> _toggleActive(StaffEntity s) async {
    final nextStatus = s.status == 'active' ? 'inactive' : 'active';
    try {
      await ref.read(hrRepositoryProvider).updateStaffStatus(s.id, nextStatus);
      if (!mounted) return;
      setState(() => _success = nextStatus == 'active' ? 'Staff has been activated.' : 'Staff has been deactivated.');
      invalidateStaffDirectory(ref);
    } catch (e) {
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Unable to update staff status.');
    }
  }

  Future<void> _deleteOne(StaffEntity s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete staff member'),
        content: const Text('Are you sure you want to delete this staff member?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE0463A)), onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(hrRepositoryProvider).deleteStaff(s.id);
      if (!mounted) return;
      setState(() => _success = 'Staff has been deleted successfully.');
      invalidateStaffDirectory(ref);
    } catch (e) {
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Unable to delete staff.');
    }
  }

  Widget _statusPill(String status) {
    final map = <String, (Color, Color)>{
      'active': (const Color(0xFFECFDF5), const Color(0xFF059669)),
      'inactive': (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
      'terminated': (const Color(0xFFFFF1F2), const Color(0xFFE11D48)),
    };
    final (bg, fg) = map[status] ?? (const Color(0xFFF1F5F9), const Color(0xFF64748B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _chip(String label, {Color tone = const Color(0xFFF4F4F8), Color fg = const Color(0xFF5B5E72)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildBulkBar(List<StaffEntity> selectedStaff) {
    // The floating pill's Row(mainAxisSize.min) of label + up to 4 action
    // buttons has no wrap/scroll protection — on a 320dp screen "N selected"
    // + Deactivate/Delete/Export/Clear can together exceed the available
    // width and throw a RenderFlex overflow. Constrain to the screen width
    // and let the pill scroll horizontally instead, so it always fits.
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 32),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${selectedStaff.length} selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(width: 10),
                if (_bulkBusy)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                else ...[
                  _bulkBtn('Deactivate', () => _bulkDeactivate(selectedStaff)),
                  _bulkBtn('Delete', () => _bulkDelete(selectedStaff)),
                  _bulkBtn('Export', () => _exportCsv(selectedStaff)),
                  TextButton(onPressed: () => setState(() => _selected.clear()), child: const Text('Clear', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700))),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bulkBtn(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), minimumSize: const Size(0, 28)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Matches the real `HrDirectoryPage`'s own per-department donut exactly —
/// a single-color brand-purple `conic-gradient(var(--brand) pct*3.6deg,
/// #E8E8EE 0deg)` ring with a white inner circle and brand-purple percentage
/// text. Deliberately NOT the multi-threshold-colored `AttendanceRing` used
/// by the separate Attendance module — the real Directory page's ring never
/// changes color by percentage.
class _PresentTodayRing extends StatelessWidget {
  final double pct;
  const _PresentTodayRing({required this.pct});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: const Size(36, 36), painter: _DonutPainter(pct: pct)),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('${pct.round()}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _brand)),
        ),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double pct;
  const _DonutPainter({required this.pct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final trackPaint = Paint()..color = const Color(0xFFE8E8EE);
    canvas.drawCircle(center, radius, trackPaint);
    if (pct <= 0) return;
    final sweep = (pct.clamp(0, 100) / 100) * 2 * math.pi;
    final fgPaint = Paint()..color = _brand;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, true, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.pct != pct;
}
