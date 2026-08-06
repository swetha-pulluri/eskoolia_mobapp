import 'dart:math' as math;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/attendance_daily_summary_entity.dart';
import '../../domain/entities/attendance_import_result_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/hr_repository.dart';
import '../providers/hr_provider.dart';
import '../widgets/attendance_absent_dialog.dart';
import '../widgets/hr_attendance_theme.dart';
import '../widgets/hr_layout.dart';
import '../widgets/monthly_attendance_report.dart';

const _brand = Color(0xFF6C3CE1);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF6B6B80);
const _line = Color(0xFFE6E6EC);

/// A literal port of the real, deployed `HrStaffAttendancePage`
/// (`app/(dashboard)/hr/attendance/page.tsx` on `origin/demo` — the actual
/// live HR backend, repeatedly confirmed this session; an earlier pass
/// checked only the stale `main` branch and wrongly concluded several real
/// fields/endpoints didn't exist). All of `attendance_type`/`note`/
/// `arrival_time`/`sign_in_time`/`sign_out_time`/`lunch` are real
/// `StaffAttendance` model fields, and `bulk-store`/`report`/
/// `daily-summary`/`monthly-report` (ViewSet `@action`s) plus
/// `download-sample`/`export`/`import` (standalone `APIView`s in
/// `apps/hr/attendance_endpoints.py`, registered ahead of the router so
/// they win over the ViewSet's own same-path `export` action) are all real.
class StaffAttendancePage extends ConsumerStatefulWidget {
  const StaffAttendancePage({super.key});

  @override
  ConsumerState<StaffAttendancePage> createState() => _StaffAttendancePageState();
}

class _StaffAttendancePageState extends ConsumerState<StaffAttendancePage> {
  final Map<int, StaffAttendanceEntity> _marks = {};
  final Map<int, StaffAttendanceEntity> _originalMarks = {};
  final Set<int> _dirty = {};
  final Set<int> _openDepts = {};
  final Set<int> _savingDepts = {};
  final Map<int, Set<int>> _selectedByDept = {};
  bool _exporting = false;
  bool _downloadingSample = false;
  String? _error;
  String? _success;
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  String _deptFilter = 'all';
  String? _seededForDate;

  String _nowHHMM() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Set<int> _selectedFor(int deptId) => _selectedByDept.putIfAbsent(deptId, () => <int>{});

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _seedMarks(String date, List<StaffAttendanceEntity> fetched) {
    if (_seededForDate == date) return;
    _seededForDate = date;
    _marks.clear();
    _originalMarks.clear();
    _dirty.clear();
    for (final a in fetched) {
      _marks[a.staffId] = a;
      _originalMarks[a.staffId] = a;
    }
  }

  StaffAttendanceEntity? _markFor(int staffId) => _marks[staffId];

  /// Applies a partial patch to a staff member's mark, matching web's own
  /// `updateMark(deptId, staffId, patch)` semantics — other fields (e.g. an
  /// existing sign-in time) are preserved, not reset.
  void _updateMark(int staffId, String date, StaffAttendanceEntity Function(StaffAttendanceEntity current) patch) {
    setState(() {
      final current = _marks[staffId] ?? StaffAttendanceEntity(staffId: staffId, attendanceDate: date);
      _marks[staffId] = patch(current);
      _dirty.add(staffId);
    });
  }

  Future<void> _setMark(int staffId, String date, String type, {String? note}) async {
    if (type == 'A' && note == null) {
      final staff = ref.read(allActiveStaffProvider).valueOrNull?.results.where((s) => s.id == staffId).firstOrNull;
      final reason = await AttendanceAbsentDialog.show(context, staffName: staff?.fullName ?? 'this staff member');
      if (reason == null) return; // dismissed without deciding — leave mark unchanged
      note = reason;
    }
    _updateMark(staffId, date, (m) => m.copyWith(attendanceType: type, note: note ?? m.note));
  }

  Future<void> _toggleAbsent(StaffEntity s, String date) async {
    final current = _markFor(s.id);
    final isAbsent = current?.attendanceType == 'A';
    if (isAbsent) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove absent mark?'),
          content: Text('${s.fullName.isEmpty ? s.staffNo : s.fullName} will be moved back to the unmarked list. You can sign them in afterwards.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep absent')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, remove')),
          ],
        ),
      );
      if (ok != true) return;
      _updateMark(s.id, date, (m) => m.copyWith(attendanceType: 'P', note: ''));
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark staff absent?'),
          content: Text("Confirm marking ${s.fullName.isEmpty ? s.staffNo : s.fullName} as absent for today. You'll be asked to add a reason next."),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC2264E)), onPressed: () => Navigator.of(context).pop(true), child: const Text('Mark absent')),
          ],
        ),
      );
      if (ok != true) return;
      await _setMark(s.id, date, 'A');
    }
  }

  void _signIn(int staffId, String date) {
    final now = _nowHHMM();
    _updateMark(staffId, date, (m) => m.copyWith(attendanceType: 'P', signInTime: m.signInTime ?? now, arrivalTime: m.arrivalTime ?? now));
  }

  void _signOut(int staffId, String date) {
    _updateMark(staffId, date, (m) => m.copyWith(signOutTime: _nowHHMM()));
  }

  void _toggleLunch(int staffId, String date) {
    _updateMark(staffId, date, (m) => m.copyWith(lunch: !m.lunch));
  }

  Future<void> _addOrEditNote(StaffEntity s, String date) async {
    final current = _markFor(s.id)?.note ?? '';
    final result = await showDialog<String>(context: context, builder: (context) => _AddNoteDialog(staffName: s.fullName.isEmpty ? s.staffNo : s.fullName, initialNote: ''));
    if (result == null || result.trim().isEmpty) return;
    final combined = current.isEmpty ? result.trim() : '$current|||${result.trim()}';
    _updateMark(s.id, date, (m) => m.copyWith(note: combined));
  }

  Future<void> _viewNotes(StaffEntity s, String date) async {
    final note = _markFor(s.id)?.note ?? '';
    final updated = await showDialog<String>(context: context, builder: (context) => _ViewNotesDialog(staffName: s.fullName.isEmpty ? s.staffNo : s.fullName, note: note));
    if (updated != null) _updateMark(s.id, date, (m) => m.copyWith(note: updated));
  }

  /// Discards unsaved local edits for this department's staff, reverting
  /// each back to its last-saved (`_originalMarks`) state — matches web's
  /// `onClick={() => loadDepartment(department.id)}` (a refetch that
  /// overwrites any in-memory unsaved changes with the real saved data).
  void _resetDepartment(List<StaffEntity> deptStaff) {
    setState(() {
      for (final s in deptStaff) {
        final original = _originalMarks[s.id];
        if (original != null) {
          _marks[s.id] = original;
        } else {
          _marks.remove(s.id);
        }
        _dirty.remove(s.id);
      }
      _success = null;
      _error = null;
    });
  }

  Future<void> _saveDepartment(int deptId, List<StaffEntity> deptStaff, String date) async {
    final rows = deptStaff.where((s) => _dirty.contains(s.id) && _marks.containsKey(s.id)).map((s) => _marks[s.id]!).toList();
    if (rows.isEmpty) {
      setState(() => _error = 'Mark at least one staff member first');
      return;
    }
    setState(() {
      _savingDepts.add(deptId);
      _error = null;
    });
    try {
      final count = await ref.read(hrRepositoryProvider).bulkSaveAttendance(rows);
      if (!mounted) return;
      setState(() {
        _success = 'Attendance saved for $count staff';
        for (final r in rows) {
          _dirty.remove(r.staffId);
          _originalMarks[r.staffId] = r;
        }
      });
      invalidateAttendanceData(ref);
    } catch (e) {
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Failed to save attendance');
    } finally {
      if (mounted) setState(() => _savingDepts.remove(deptId));
    }
  }

  void _markAllVisible(String code, List<DepartmentEntity> departments, Map<int, List<StaffEntity>> staffByDept, String date) {
    var count = 0;
    final q = _searchCtrl.text.trim().toLowerCase();
    for (final d in departments) {
      if (!_openDepts.contains(d.id)) continue;
      for (final s in staffByDept[d.id] ?? const <StaffEntity>[]) {
        final matchesSearch = q.isEmpty || s.fullName.toLowerCase().contains(q) || s.staffNo.toLowerCase().contains(q);
        final currentType = _markFor(s.id)?.attendanceType ?? 'P';
        final matchesStatus = _statusFilter == 'all' || currentType == _statusFilter;
        if (matchesSearch && matchesStatus && currentType != code) {
          _updateMark(s.id, date, (m) => m.copyWith(attendanceType: code));
          count++;
        }
      }
    }
    setState(() => _success = count > 0 ? 'Marked $count staff as $code' : null);
    if (count == 0) setState(() => _error = 'No visible staff to update. Make sure a department is open.');
  }

  Future<void> _downloadSample() async {
    setState(() => _downloadingSample = true);
    try {
      final bytes = await ref.read(hrRepositoryProvider).downloadSampleAttendance();
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(bytes), name: 'staff_attendance_sheet.xlsx', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')]);
    } catch (e) {
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Failed to download sample');
    } finally {
      if (mounted) setState(() => _downloadingSample = false);
    }
  }

  Future<void> _export(String date) async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref.read(hrRepositoryProvider).exportAttendance(
            date: date,
            department: _deptFilter == 'all' ? null : _deptFilter,
            attendanceType: _statusFilter == 'all' ? null : _statusFilter,
          );
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(bytes), name: 'staff_attendance_$date.xlsx', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')]);
    } catch (e) {
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Failed to export');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openImportDialog(String date) async {
    final imported = await showDialog<bool>(context: context, builder: (context) => _ImportAttendanceDialog(initialDate: date));
    if (imported == true) invalidateAttendanceData(ref);
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(attendanceDateProvider);
    final staffAsync = ref.watch(allActiveStaffProvider);
    final departmentsAsync = ref.watch(allDepartmentsProvider);
    final attendanceAsync = ref.watch(attendanceForDateProvider);
    final dailySummaryAsync = ref.watch(dailySummaryProvider);

    final allStaff = staffAsync.valueOrNull?.results ?? const <StaffEntity>[];
    final departments = departmentsAsync.valueOrNull?.results ?? const <DepartmentEntity>[];

    ref.listen(attendanceForDateProvider, (prev, next) {
      final fetched = next.valueOrNull?.results;
      if (fetched != null) setState(() => _seedMarks(date, fetched));
    });
    if (attendanceAsync.hasValue && _seededForDate != date) {
      _seedMarks(date, attendanceAsync.value!.results);
    }

    final staffByDept = <int, List<StaffEntity>>{};
    for (final s in allStaff) {
      if (s.departmentId == null) continue;
      (staffByDept[s.departmentId!] ??= []).add(s);
    }

    if (_openDepts.isEmpty && departments.isNotEmpty) {
      _openDepts.add(departments.first.id);
    }

    final filteredDepartments = _deptFilter == 'all' ? departments : departments.where((d) => d.name == _deptFilter).toList();

    return HrLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(allStaff, date),
            const SizedBox(height: 16),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFD97706)))),
            if (_success != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_success!, style: const TextStyle(color: Color(0xFF16A34A)))),
            _buildKpiRow(dailySummaryAsync.valueOrNull, allStaff.length),
            const SizedBox(height: 16),
            _buildDateStrip(date),
            const SizedBox(height: 10),
            _buildFilterRow(departments),
            const SizedBox(height: 14),
            if (staffAsync.isLoading || departmentsAsync.isLoading || attendanceAsync.isLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
            else if (filteredDepartments.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No departments found', style: TextStyle(color: _muted))))
            else
              Column(children: [for (final d in filteredDepartments) _buildDeptCard(d, staffByDept[d.id] ?? const [], date)]),
            const SizedBox(height: 24),
            MonthlyAttendanceReport(departments: departments, staff: allStaff),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<StaffEntity> allStaff, String date) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _ink),
            children: [TextSpan(text: 'Staff '), TextSpan(text: 'Attendance', style: TextStyle(color: _brand, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400))],
          ),
        ),
        const SizedBox(height: 2),
        const Text('Track and manage daily staff attendance by department', style: TextStyle(fontSize: 13, color: _muted)),
      ],
    );
    final buttons = Wrap(spacing: 8, runSpacing: 8, children: [
      OutlinedButton.icon(onPressed: _downloadingSample ? null : _downloadSample, icon: const Icon(Icons.download, size: 15), label: const Text('Download Sample')),
      OutlinedButton.icon(onPressed: () => _openImportDialog(date), icon: const Icon(Icons.upload_outlined, size: 15), label: const Text('Import')),
      OutlinedButton.icon(onPressed: _exporting ? null : () => _export(date), icon: const Icon(Icons.ios_share, size: 15), label: const Text('Export')),
    ]);
    // `Wrap` only wraps its children when it is itself given a bounded
    // width. Nested directly as a non-flex child of a `Row` (the previous
    // layout) it receives an unbounded main-axis constraint, so it never
    // wraps and instead lays every button out on one line — on a narrow
    // phone the combined width of the title (squeezed by `Expanded` down to
    // its minimum) and the three buttons exceeds the screen, producing a
    // real `RenderFlex` overflow. Below ~640px stack the title above a
    // full-width button `Wrap` instead of placing them side by side.
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 640) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 12), buttons]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: title), buttons]);
    });
  }

  /// Real source is `daily-summary` (school-scoped active-staff total +
  /// server-saved counts) — NOT `allStaff.length` (that was the cause of a
  /// real reported mismatch vs the web, e.g. showing 0/14 instead of 0/11).
  /// Local unsaved edits (`_marks` vs `_originalMarks` for `_dirty` staff)
  /// are applied as a live delta on top, matching web's own
  /// `basePresent + deltaPresent` optimistic-KPI approach.
  Widget _buildKpiRow(AttendanceDailySummaryEntity? summary, int totalStaffFallback) {
    final totalStaff = (summary?.totalStaff ?? 0) > 0 ? summary!.totalStaff : totalStaffFallback;
    var present = summary?.present ?? 0;
    var absent = summary?.absent ?? 0;
    var lateArrivals = summary?.lateArrivals ?? 0;
    for (final staffId in _dirty) {
      final now = _marks[staffId];
      final orig = _originalMarks[staffId];
      final nowType = now?.attendanceType;
      final origType = orig?.attendanceType;
      if (nowType != origType) {
        if (nowType == 'A') {
          absent++;
        } else if (nowType == 'P') {
          present++;
        }
        if (origType == 'A') {
          absent--;
        } else if (origType == 'P') {
          present--;
        }
      }
      final nowLate = now?.arrivalTime != null;
      final origLate = orig?.arrivalTime != null;
      if (nowLate != origLate) lateArrivals += nowLate ? 1 : -1;
    }
    present = present.clamp(0, 1 << 30);
    absent = absent.clamp(0, 1 << 30);
    lateArrivals = lateArrivals.clamp(0, 1 << 30);
    final pct = totalStaff > 0 ? ((present / totalStaff) * 100).round() : 0;
    return LayoutBuilder(builder: (context, constraints) {
      final perRow = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 560 ? 2 : 1);
      final cardWidth = (constraints.maxWidth - (perRow - 1) * 12) / perRow;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: cardWidth,
          child: AttendanceKpiCard(
            label: 'Present Today',
            value: '$present/$totalStaff',
            sub: '$pct% attendance today',
            badge: 'PR',
            badgeBg: const Color(0xFFECFDF5),
            badgeColor: const Color(0xFF16A34A),
            trend: '+0%',
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: AttendanceKpiCard(
            label: 'Absent Today',
            value: '$absent',
            sub: absent == 0 ? 'No absences marked.' : 'Reasons are recorded per staff member.',
            badge: 'AB',
            badgeBg: const Color(0xFFFFF1F2),
            badgeColor: const Color(0xFFE11D48),
            trend: 'Same as yesterday',
            trendColor: const Color(0xFF9CA0AE),
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: AttendanceKpiCard(
            label: 'Late Arrivals',
            value: '$lateArrivals',
            sub: lateArrivals == 0 ? 'No late entries' : '$lateArrivals staff arrived late',
            badge: 'LT',
            badgeBg: const Color(0xFFFFFBEB),
            badgeColor: const Color(0xFFD97706),
          ),
        ),
        SizedBox(width: cardWidth, child: const AttendanceKpiCard(label: 'RTE Compliance Risk', value: '0', sub: 'Shows staff below 75% cumulative attendance. Calculated as present days / working days.', badge: 'RT', badgeBg: Color(0xFFF5F3FF), badgeColor: Color(0xFF7C3AED))),
      ]);
    });
  }

  /// Real month <select> options for the whole calendar year containing
  /// [selectedDate] — matches web's `monthOptions()` (`HrGlobalControls.tsx`).
  List<MapEntry<String, String>> _monthOptions(DateTime selectedDate) {
    const monthsAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final year = selectedDate.year;
    return List.generate(12, (m) {
      final value = '$year-${(m + 1).toString().padLeft(2, '0')}';
      return MapEntry(value, '${monthsAbbr[m]} $year');
    });
  }

  DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Real week <select> options within one calendar month — matches web's
  /// `weekOptionsForMonth()` (`HrGlobalControls.tsx`).
  List<MapEntry<String, String>> _weekOptionsForMonth(String monthValue) {
    final parts = monthValue.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final out = <MapEntry<String, String>>[];
    var cursor = _mondayOf(firstDay);
    var idx = 1;
    while ((cursor.isBefore(lastDay) || _iso(cursor) == _iso(lastDay)) && idx <= 7) {
      final weekStart = cursor;
      final weekEnd = cursor.add(const Duration(days: 6));
      final inMonthStart = weekStart.month == month ? weekStart : firstDay;
      final inMonthEnd = weekEnd.month == month ? weekEnd : lastDay;
      out.add(MapEntry(_iso(weekStart), 'Week $idx (${inMonthStart.day}-${inMonthEnd.day})'));
      cursor = cursor.add(const Duration(days: 7));
      idx++;
    }
    return out;
  }

  Widget _weekNavButton(String label, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3A3A4A),
          side: const BorderSide(color: _line),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _smallDropdown({required String value, required List<MapEntry<String, String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(8), color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => e.key == value) ? value : null,
          isDense: true,
          style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A2E)),
          items: items.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Row 1 of `HrGlobalControls.tsx`: "Week of … :" label, month/week
  /// pickers, prev/next, Today, the 7 day chips, and the Auto-saving
  /// indicator — all on one horizontally-scrolling bar, matching web
  /// exactly (previously this only had the day chips + prev/next/Today,
  /// missing the label/month/week pickers and the Auto-saving indicator
  /// entirely).
  Widget _buildDateStrip(String date) {
    final selected = DateTime.parse(date);
    final monday = _mondayOf(selected);
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final todayStr = _todayIso();

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthsAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final first = days.first;
    final last = days.last;
    final stripLabel = 'Week of ${first.day} ${monthsAbbr[first.month - 1]} – ${last.day} ${monthsAbbr[last.month - 1]}';

    final selectedMonth = '${selected.year}-${selected.month.toString().padLeft(2, '0')}';
    final months = _monthOptions(selected);
    final weeks = _weekOptionsForMonth(selectedMonth);
    final selectedWeekStart = _iso(monday);
    final weekValue = weeks.any((w) => w.key == selectedWeekStart) ? selectedWeekStart : (weeks.isNotEmpty ? weeks.first.key : date);

    void goToDate(String iso) => ref.read(attendanceDateProvider.notifier).state = iso;

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${stripLabel.toUpperCase()}:', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), letterSpacing: 0.5)),
            const SizedBox(width: 6),
            _smallDropdown(
              value: selectedMonth,
              items: months,
              onChanged: (v) {
                if (v == null) return;
                final parts = v.split('-');
                goToDate(_iso(DateTime(int.parse(parts[0]), int.parse(parts[1]), 1)));
              },
            ),
            const SizedBox(width: 4),
            _weekNavButton('←', () => goToDate(_iso(monday.subtract(const Duration(days: 7))))),
            const SizedBox(width: 4),
            _smallDropdown(
              value: weekValue,
              items: weeks,
              onChanged: (v) {
                if (v != null) goToDate(v);
              },
            ),
            const SizedBox(width: 4),
            _weekNavButton('→', () => goToDate(_iso(monday.add(const Duration(days: 7))))),
            const SizedBox(width: 8),
            SizedBox(
              height: 30,
              child: TextButton(
                onPressed: date == todayStr ? null : () => goToDate(todayStr),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE4F6ED),
                  foregroundColor: const Color(0xFF0A8C5A),
                  disabledBackgroundColor: const Color(0xFFE4F6ED),
                  disabledForegroundColor: const Color(0xFF0A8C5A),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFBDE9D0))),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                child: const Text('Today'),
              ),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < 7; i++)
              Builder(builder: (context) {
                // Matches web's `chipState`/`chipClass`
                // (`HrGlobalControls.tsx`) exactly — 3 date states
                // (today / already-passed "done" / future) crossed
                // with selected/not, 5 distinct looks total. Previously
                // only distinguished selected vs. today, so every past
                // date looked identical to a future one.
                final dISO = _iso(days[i]);
                final isSelected = dISO == date;
                final isToday = dISO == todayStr;
                final isDone = !isToday && dISO.compareTo(todayStr) < 0;

                Color bg;
                Color textColor;
                Border? border;
                if (isSelected && isToday) {
                  bg = _brand;
                  textColor = Colors.white;
                } else if (isSelected) {
                  bg = const Color(0xFFFFF4D6);
                  textColor = const Color(0xFF9A5C00);
                } else if (isToday) {
                  bg = Colors.white;
                  textColor = _brand;
                  border = Border.all(color: _brand, width: 2);
                } else if (isDone) {
                  bg = const Color(0xFFF6F4FF);
                  textColor = _brand;
                  border = Border.all(color: _brand.withValues(alpha: 0.2));
                } else {
                  bg = Colors.white;
                  textColor = _muted;
                  border = Border.all(color: const Color(0xFFE6E6EC));
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () => goToDate(dISO),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 46, minHeight: 38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: bg, border: border, borderRadius: BorderRadius.circular(10)),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(dayNames[i], style: TextStyle(fontSize: 9, fontWeight: isToday ? FontWeight.w600 : FontWeight.normal, color: textColor)),
                        const SizedBox(height: 2),
                        Text('${days[i].day}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        if (isToday)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFDDF5EA), borderRadius: BorderRadius.circular(3)),
                            child: Text('TODAY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF0A8C5A))),
                          ),
                      ]),
                    ),
                  ),
                );
              }),
            const SizedBox(width: 12),
            const Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF0A8C5A), shape: BoxShape.circle))),
              SizedBox(width: 6),
              Text('Auto-saving', style: TextStyle(fontSize: 11, color: Color(0xFF8B8B9E))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(List<DepartmentEntity> departments) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search staff by name or ID…', border: OutlineInputBorder(), isDense: true),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All staff')),
              DropdownMenuItem(value: 'P', child: Text('Present')),
              DropdownMenuItem(value: 'A', child: Text('Absent')),
              DropdownMenuItem(value: 'L', child: Text('Leave')),
              DropdownMenuItem(value: 'F', child: Text('Half Day')),
              DropdownMenuItem(value: 'H', child: Text('Holiday')),
            ],
            onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _deptFilter,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Departments')),
              for (final d in departments) DropdownMenuItem(value: d.name, child: Text(d.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _deptFilter = v ?? 'all'),
          ),
        ),
        const Text('Mark all visible:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _muted)),
        _markAllBtn('P', const Color(0xFF0A8C5A), const Color(0xFFE4F6ED)),
        _markAllBtn('A', const Color(0xFFC2264E), const Color(0xFFFCE8EE)),
        _markAllBtn('L', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      ],
    );
  }

  Widget _markAllBtn(String code, Color fg, Color bg) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(backgroundColor: bg, foregroundColor: fg, side: BorderSide(color: fg.withValues(alpha: 0.3)), minimumSize: const Size(38, 34)),
      onPressed: () {
        final date = ref.read(attendanceDateProvider);
        final allStaff = ref.read(allActiveStaffProvider).valueOrNull?.results ?? const <StaffEntity>[];
        final departments = ref.read(allDepartmentsProvider).valueOrNull?.results ?? const <DepartmentEntity>[];
        final staffByDept = <int, List<StaffEntity>>{};
        for (final s in allStaff) {
          if (s.departmentId != null) (staffByDept[s.departmentId!] ??= []).add(s);
        }
        _markAllVisible(code, departments, staffByDept, date);
      },
      child: Text(code),
    );
  }

  Widget _buildDeptCard(DepartmentEntity dept, List<StaffEntity> deptStaff, String date) {
    final open = _openDepts.contains(dept.id);
    final present = deptStaff.where((s) {
      final m = _markFor(s.id);
      if (m == null) return false;
      if (m.attendanceType == 'A') return false;
      return m.attendanceType == 'P' || m.signInTime != null;
    }).length;
    final absent = deptStaff.where((s) => _markFor(s.id)?.attendanceType == 'A').length;
    final signedInCount = deptStaff.where((s) {
      final m = _markFor(s.id);
      return m != null && m.signInTime != null && m.signOutTime == null && m.attendanceType != 'A';
    }).length;
    final pct = deptStaff.isEmpty ? 0.0 : (present / deptStaff.length) * 100;
    final q = _searchCtrl.text.trim().toLowerCase();
    final visibleStaff = deptStaff.where((s) {
      final matchesSearch = q.isEmpty || s.fullName.toLowerCase().contains(q) || s.staffNo.toLowerCase().contains(q);
      final currentType = _markFor(s.id)?.attendanceType ?? 'P';
      final matchesStatus = _statusFilter == 'all' || currentType == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
    final selected = _selectedFor(dept.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (open) {
                _openDepts.remove(dept.id);
              } else {
                _openDepts.add(dept.id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                AnimatedRotation(turns: open ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.keyboard_arrow_down)),
                const SizedBox(width: 10),
                // A long department name here is unbounded (a plain `Text`
                // as a non-flex `Row` child takes its full intrinsic width),
                // which combined with the badges `Expanded` and the trailing
                // ring/label can push the row past the screen width and
                // trigger a real overflow. `Flexible` lets it shrink and
                // ellipsize instead.
                Flexible(child: Text(dept.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink))),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(spacing: 6, runSpacing: 6, children: [
                    _pillBadge('${deptStaff.length} staff', const Color(0xFFFAFAFD), _ink, border: _line),
                    if (deptStaff.isNotEmpty) _pillBadge('$present present', const Color(0xFFE4F6ED), const Color(0xFF0A8C5A)),
                    if (absent > 0) _pillBadge('$absent absent', const Color(0xFFFCE8EE), const Color(0xFFC2264E)),
                  ]),
                ),
                if (deptStaff.isEmpty)
                  const Text('No staff assigned', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF9CA0AE)))
                else
                  AttendanceRing(pct: pct),
              ]),
            ),
          ),
          if (open)
            Column(children: [
              const Divider(height: 1),
              if (selected.isNotEmpty) _buildBulkActionBar(dept.id, deptStaff, date),
              if (visibleStaff.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No staff match the current filters.', style: TextStyle(color: _muted)))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 900),
                    child: Column(children: [
                      _staffTableHeader(dept.id, visibleStaff),
                      for (final s in visibleStaff) _buildStaffRow(dept.id, s, date),
                    ]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0A8C5A), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('$present present', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3A3A4A))),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFC2264E), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('$absent absent', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3A3A4A))),
                    ]),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFE4F6ED), foregroundColor: const Color(0xFF0A8C5A), side: const BorderSide(color: Color(0x330A8C5A))),
                      onPressed: () {
                        for (final s in deptStaff) {
                          if (_markFor(s.id)?.attendanceType != 'A') {
                            final now = _nowHHMM();
                            _updateMark(s.id, date, (m) => m.copyWith(attendanceType: 'P', signInTime: m.signInTime ?? now, arrivalTime: m.arrivalTime ?? now));
                          }
                        }
                      },
                      child: const Text('✓ All Marked'),
                    ),
                    if (signedInCount > 0)
                      OutlinedButton(
                        onPressed: () {
                          for (final s in deptStaff) {
                            final m = _markFor(s.id);
                            if (m != null && m.signInTime != null && m.signOutTime == null && m.attendanceType != 'A') _signOut(s.id, date);
                          }
                        },
                        child: Text('Sign Out All ($signedInCount)'),
                      ),
                    const Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF0A8C5A), shape: BoxShape.circle))),
                      SizedBox(width: 4),
                      Text('Auto-saving', style: TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
                    ]),
                    OutlinedButton(onPressed: () => _resetDepartment(deptStaff), child: const Text('Reset')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _brand),
                      onPressed: _savingDepts.contains(dept.id) ? null : () => _saveDepartment(dept.id, deptStaff, date),
                      child: Text(_savingDepts.contains(dept.id) ? 'Saving…' : 'Save Attendance'),
                    ),
                  ],
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _pillBadge(String text, Color bg, Color fg, {Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: border != null ? Border.all(color: border) : null),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
    );
  }

  Widget _buildBulkActionBar(int deptId, List<StaffEntity> deptStaff, String date) {
    final selected = _selectedFor(deptId);
    return Container(
      color: const Color(0xFF0B0B14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CircleAvatar(radius: 10, backgroundColor: _brand, child: Text('${selected.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
          const Text('selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0A8C5A)),
            onPressed: () {
              for (final id in selected) {
                _signIn(id, date);
              }
            },
            child: const Text('Sign in & mark present'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC2264E)),
            onPressed: () {
              for (final id in selected) {
                _updateMark(id, date, (m) => m.copyWith(attendanceType: 'A'));
              }
            },
            child: const Text('Mark absent'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x4DFFFFFF))),
            onPressed: () {
              for (final id in selected) {
                final m = _markFor(id);
                if (m != null && m.signInTime != null && m.signOutTime == null) _signOut(id, date);
              }
            },
            child: const Text('Sign out'),
          ),
          IconButton(onPressed: () => setState(() => selected.clear()), icon: const Icon(Icons.close, color: Colors.white70, size: 18)),
        ],
      ),
    );
  }

  Widget _staffTableHeader(int deptId, List<StaffEntity> visibleStaff) {
    final selected = _selectedFor(deptId);
    final allSelected = visibleStaff.isNotEmpty && visibleStaff.every((s) => selected.contains(s.id));
    TextStyle head = const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: Color(0xFF9CA0AE));
    return Container(
      color: const Color(0xFFFAFAFD),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        SizedBox(width: 28, child: Checkbox(value: allSelected, onChanged: (v) => setState(() {
              if (v == true) {
                selected.addAll(visibleStaff.map((s) => s.id));
              } else {
                selected.clear();
              }
            }))),
        SizedBox(width: 170, child: Text('STAFF', style: head)),
        SizedBox(width: 70, child: Text('STAFF NO', textAlign: TextAlign.center, style: head)),
        SizedBox(width: 70, child: Text('ABSENT', textAlign: TextAlign.center, style: head)),
        SizedBox(width: 90, child: Text('ARRIVAL', style: head)),
        SizedBox(width: 90, child: Text('SIGN IN', style: head)),
        SizedBox(width: 90, child: Text('SIGN OUT', style: head)),
        SizedBox(width: 60, child: Text('LUNCH', textAlign: TextAlign.center, style: head)),
        SizedBox(width: 60, child: Text('NOTES', textAlign: TextAlign.center, style: head)),
        SizedBox(width: 100, child: Text('ACTIONS', style: head)),
      ]),
    );
  }

  Widget _buildStaffRow(int deptId, StaffEntity s, String date) {
    final mark = _markFor(s.id);
    final isAbsent = mark?.attendanceType == 'A';
    final hasActiveSignIn = mark?.signInTime != null && mark?.signOutTime == null && !isAbsent;
    final signedIn = mark?.signInTime != null;
    final selected = _selectedFor(deptId);
    final isSelected = selected.contains(s.id);
    final notes = (mark?.note.isEmpty ?? true) ? const <String>[] : mark!.note.split('|||');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // `color` and `decoration` can't both be set on a `Container` (a real,
      // always-on crash the moment a row's checkbox is selected — Flutter
      // throws "Cannot provide both a color and a decoration" outright).
      // Fold the selection tint into the same `BoxDecoration` as the border.
      decoration: BoxDecoration(color: isSelected ? const Color(0xFFF4F2FF) : null, border: const Border(top: BorderSide(color: Color(0xFFF4F4F8)))),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Checkbox(
            value: isSelected,
            onChanged: (v) => setState(() {
              if (v == true) {
                selected.add(s.id);
              } else {
                selected.remove(s.id);
              }
            }),
          ),
        ),
        SizedBox(
          width: 170,
          child: Row(children: [
            CircleAvatar(radius: 14, backgroundColor: const Color(0xFFE0DBFD), child: Text(_initials(s), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _brand))),
            const SizedBox(width: 8),
            Expanded(child: Text(s.fullName.isEmpty ? s.staffNo : s.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: _ink))),
          ]),
        ),
        SizedBox(width: 70, child: Text(s.staffNo.isEmpty ? '—' : s.staffNo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF5A5E70)))),
        SizedBox(
          width: 70,
          child: Center(
            child: Switch(
              value: isAbsent,
              onChanged: hasActiveSignIn ? null : (_) => _toggleAbsent(s, date),
              activeThumbColor: const Color(0xFFC2264E),
            ),
          ),
        ),
        SizedBox(width: 90, child: _timeBadgeOrDash(mark?.arrivalTime)),
        SizedBox(
          width: 90,
          child: mark?.signInTime != null
              ? _timeBadge(mark!.signInTime!, highlight: hasActiveSignIn)
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white, minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 10)),
                  onPressed: isAbsent ? null : () => _signIn(s.id, date),
                  child: const Text('Sign in', style: TextStyle(fontSize: 11)),
                ),
        ),
        SizedBox(
          width: 90,
          child: mark?.signOutTime != null
              ? _timeBadge(mark!.signOutTime!)
              : signedIn
                  ? OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 10)),
                      onPressed: () => _signOut(s.id, date),
                      child: const Text('Sign out', style: TextStyle(fontSize: 11)),
                    )
                  : const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE))),
        ),
        SizedBox(width: 60, child: Center(child: Switch(value: mark?.lunch ?? false, onChanged: signedIn ? (_) => _toggleLunch(s.id, date) : null))),
        SizedBox(
          width: 60,
          child: Center(
            child: notes.isEmpty
                ? const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)))
                : CircleAvatar(radius: 9, backgroundColor: _brand, child: Text('${notes.length}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
        ),
        SizedBox(
          width: 100,
          child: Row(children: [
            if (notes.isNotEmpty) IconButton(iconSize: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 28), onPressed: () => _viewNotes(s, date), icon: const Icon(Icons.remove_red_eye_outlined)),
            IconButton(iconSize: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 28), onPressed: () => _addOrEditNote(s, date), icon: const Icon(Icons.note_add_outlined)),
          ]),
        ),
      ]),
    );
  }

  String _initials(StaffEntity s) {
    final parts = s.fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return s.staffNo.isEmpty ? '?' : s.staffNo.substring(0, s.staffNo.length.clamp(0, 2)).toUpperCase();
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  Widget _timeBadgeOrDash(String? time) => time != null ? _timeBadge(time) : const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)));

  Widget _timeBadge(String time, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: highlight ? const Color(0xFFE4F6ED) : const Color(0xFFF4F4F8), borderRadius: BorderRadius.circular(8)),
      child: Text(time.length >= 5 ? time.substring(0, 5) : time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: highlight ? const Color(0xFF0A8C5A) : const Color(0xFF3A3A4A))),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  final String staffName;
  final String initialNote;
  const _AddNoteDialog({required this.staffName, this.initialNote = ''});

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  late final _ctrl = TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialNote.isNotEmpty;
    return AlertDialog(
      // `scrollable: true` — only the dialog's *width* was capped for
      // narrow phones before; on a short viewport (soft keyboard open,
      // small-height landscape) title + staff name + the 4-line growing
      // TextField + actions could still exceed the available height with
      // nothing to absorb the overflow. This turns that into a scrollbar
      // instead of a hard `RenderFlex` overflow.
      scrollable: true,
      title: Text(isEditing ? 'Edit Note' : 'Add Note'),
      content: ConstrainedBox(
        // A hardcoded desktop width overflows a 320-360dp phone screen once
        // the dialog's own insets are subtracted; cap it to whichever is
        // smaller.
        constraints: BoxConstraints(maxWidth: math.min(340, MediaQuery.sizeOf(context).width - 32)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.staffName, style: const TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 10),
          TextField(controller: _ctrl, maxLength: 250, maxLines: 4, autofocus: true, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Enter a note for this staff member…', border: OutlineInputBorder())),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _ctrl.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: Text(isEditing ? 'Update Note' : 'Save Note'),
        ),
      ],
    );
  }
}

class _ViewNotesDialog extends StatefulWidget {
  final String staffName;
  final String note;
  const _ViewNotesDialog({required this.staffName, required this.note});

  @override
  State<_ViewNotesDialog> createState() => _ViewNotesDialogState();
}

class _ViewNotesDialogState extends State<_ViewNotesDialog> {
  final List<String> _notes = [];
  int? _editingIndex;
  final _editCtrl = TextEditingController();
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    if (widget.note.isNotEmpty) _notes.addAll(widget.note.split('|||'));
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // See `_AddNoteDialog`'s identical fix — the header + notes list +
      // an in-place edit `TextField` combination has no scroll fallback of
      // its own on a short viewport otherwise.
      scrollable: true,
      title: const Text('Notes'),
      content: ConstrainedBox(
        // A hardcoded desktop width overflows a 320-360dp phone screen once
        // the dialog's own insets are subtracted; cap it to whichever is
        // smaller.
        constraints: BoxConstraints(maxWidth: math.min(380, MediaQuery.sizeOf(context).width - 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.staffName, style: const TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 10),
            if (_notes.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('No notes added yet.', style: TextStyle(color: _muted))))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _notes.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (_editingIndex == i) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(10)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          TextField(controller: _editCtrl, maxLines: 3, autofocus: true),
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            TextButton(onPressed: () => setState(() => _editingIndex = null), child: const Text('Cancel')),
                            FilledButton(
                              onPressed: () => setState(() {
                                if (_editCtrl.text.trim().isNotEmpty) {
                                  _notes[i] = _editCtrl.text.trim();
                                  _changed = true;
                                }
                                _editingIndex = null;
                              }),
                              child: const Text('Save'),
                            ),
                          ]),
                        ]),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(10)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('#${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _brand)),
                        const SizedBox(height: 4),
                        Text(_notes[i], style: const TextStyle(fontSize: 12.5)),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          IconButton(iconSize: 16, onPressed: () => setState(() {
                                _editingIndex = i;
                                _editCtrl.text = _notes[i];
                              }), icon: const Icon(Icons.edit_outlined)),
                          IconButton(
                            iconSize: 16,
                            onPressed: () => setState(() {
                              _notes.removeAt(i);
                              _changed = true;
                            }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(context).pop(_changed ? _notes.join('|||') : null), child: const Text('Close')),
      ],
    );
  }
}

/// Mobile-adapted port of `StaffAttendanceImportDialog.tsx` — date + file
/// picker (no drag-and-drop, not meaningful on mobile) uploading to the
/// real `POST /api/v1/hr/staff-attendance/import/`.
class _ImportAttendanceDialog extends ConsumerStatefulWidget {
  final String initialDate;
  const _ImportAttendanceDialog({required this.initialDate});

  @override
  ConsumerState<_ImportAttendanceDialog> createState() => _ImportAttendanceDialogState();
}

class _ImportAttendanceDialogState extends ConsumerState<_ImportAttendanceDialog> {
  late String _date = widget.initialDate;
  PickedAttachment? _file;
  bool _uploading = false;
  String? _error;
  AttendanceImportResultEntity? _result;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls', 'csv'], withData: true);
    final picked = result?.files.firstOrNull;
    if (picked?.bytes == null) return;
    setState(() => _file = PickedAttachment(name: picked!.name, bytes: picked.bytes!, size: picked.size));
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final result = await ref.read(hrRepositoryProvider).importAttendance(attendanceDate: _date, file: file);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e is HrApiException ? e.message : 'Failed to import');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: const Text('Import Attendance'),
      content: ConstrainedBox(
        // A hardcoded desktop width overflows a 320-360dp phone screen once
        // the dialog's own insets are subtracted; cap it to whichever is
        // smaller.
        constraints: BoxConstraints(maxWidth: math.min(380, MediaQuery.sizeOf(context).width - 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result != null) ...[
              Text('Imported ${result.imported}, failed ${result.failed}', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView(shrinkWrap: true, children: [for (final e in result.errors) Text('• $e', style: const TextStyle(fontSize: 12, color: Color(0xFFC2264E)))]),
                ),
              ],
            ] else ...[
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(_date) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setState(() => _date = picked.toIso8601String().split('T').first);
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Attendance Date', border: OutlineInputBorder(), isDense: true), child: Text(_date)),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file, size: 16), label: Text(_file?.name ?? 'Choose file (.xlsx, .csv)')),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFD97706), fontSize: 12))),
            ],
          ],
        ),
      ),
      actions: [
        if (result != null)
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Done'))
        else ...[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: (_file == null || _uploading) ? null : _upload, child: Text(_uploading ? 'Uploading…' : 'Upload')),
        ],
      ],
    );
  }
}
