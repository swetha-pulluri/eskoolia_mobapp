// Staff Assignment — port of components/academics/StaffAssignmentPanels.tsx
// (rendered at frontend route app/(dashboard)/academics/staff-workspace/page.tsx).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../student/domain/models/academic_year.dart';
import '../../../domain/entities/class_entity.dart';
import '../../../domain/entities/section_entity.dart';
import '../../../domain/entities/staff_assignment_entities.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/staff_assignment_dialogs.dart';
import '../../widgets/staff_assignment_widgets.dart';
import 'staff_audit_log_tab.dart';
import 'staff_workload_tab.dart';

enum _StaffTab { assignments, workload, audit }

const List<String> _levelFilters = ['All', 'Pre-Primary', 'Primary', 'Middle', 'Secondary', 'Senior Secondary'];

class _StaffToast {
  final String id;
  final String type; // success | error | warning
  final String message;
  const _StaffToast({required this.id, required this.type, required this.message});
}

class StaffAssignmentPage extends ConsumerStatefulWidget {
  const StaffAssignmentPage({super.key});

  @override
  ConsumerState<StaffAssignmentPage> createState() => _StaffAssignmentPageState();
}

class _StaffAssignmentPageState extends ConsumerState<StaffAssignmentPage> {
  _StaffTab _activeTab = _StaffTab.assignments;
  String _levelFilter = 'All';

  List<AcademicYear> _academicYears = [];
  int? _selectedYearId;
  List<FoundationClass> _classes = [];
  List<FoundationSection> _sections = [];
  List<StaffTeacher> _teachers = [];
  List<StaffSubjectRow> _subjectRows = [];
  List<CTAssignment> _ctAssignments = [];
  StaffKpi? _kpi;

  bool _loadingInit = true;
  final Set<int> _savingCTSects = {};
  final Set<int> _savingSubjKeys = {};

  int _toastSeq = 0;
  final List<_StaffToast> _toasts = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  void _showToast(String message, {String type = 'success'}) {
    final id = '${_toastSeq++}';
    setState(() => _toasts.add(_StaffToast(id: id, type: type, message: message)));
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) setState(() => _toasts.removeWhere((t) => t.id == id));
    });
  }

  void _removeToast(String id) => setState(() => _toasts.removeWhere((t) => t.id == id));

  Future<void> _loadInitial() async {
    try {
      final repo = ref.read(academicsRepositoryProvider);
      final yearsFuture = repo.fetchAcademicYears();
      final classesFuture = repo.fetchClasses();
      final teachersFuture = repo.fetchStaffTeachers();
      final years = await yearsFuture;
      final classes = (await classesFuture)..sort((a, b) => a.numericOrder.compareTo(b.numericOrder));
      final teachers = await teachersFuture;
      final sections = classes.expand((c) => c.sections).toList();

      if (!mounted) return;
      setState(() {
        _academicYears = years;
        _classes = classes;
        _sections = sections;
        _teachers = teachers;
      });

      final current = years.where((y) => y.isCurrent).firstOrNull ?? years.firstOrNull;
      if (current != null) {
        setState(() => _selectedYearId = current.id);
        await Future.wait([_fetchCT(current.id), _fetchSubjectRows(current.id), _fetchKpi(current.id)]);
      }
    } catch (_) {
      _showToast('Failed to load data. Please refresh.', type: 'error');
    } finally {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  Future<void> _fetchCT(int yearId) async {
    try {
      final res = await ref.read(academicsRepositoryProvider).fetchClassTeacherAssignments(academicYearId: yearId);
      if (mounted) setState(() => _ctAssignments = res);
    } catch (_) {
      _showToast('Failed to load class teacher assignments.', type: 'error');
    }
  }

  Future<void> _fetchSubjectRows(int yearId) async {
    try {
      final res = await ref.read(academicsRepositoryProvider).fetchStaffSubjectRows(academicYearId: yearId);
      if (mounted) setState(() => _subjectRows = res);
    } catch (_) {
      _showToast('Failed to load subject assignments. Please retry.', type: 'error');
    }
  }

  Future<void> _fetchKpi(int yearId) async {
    try {
      final res = await ref.read(academicsRepositoryProvider).fetchStaffKpi(academicYearId: yearId);
      if (mounted) setState(() => _kpi = res);
    } catch (_) {
      _showToast('Failed to load assignment summary.', type: 'error');
    }
  }

  Future<void> _onYearChange(int yearId) async {
    setState(() => _selectedYearId = yearId);
    await Future.wait([_fetchCT(yearId), _fetchSubjectRows(yearId), _fetchKpi(yearId)]);
  }

  Future<void> _refreshAll() async {
    final yearId = _selectedYearId;
    if (yearId == null) {
      // No year ever got selected — either nothing has loaded yet, or the
      // initial load failed outright (years/classes/teachers all empty).
      // Re-run the full initial load instead of silently doing nothing,
      // which is what made "Refresh" appear broken after a load failure.
      await _loadInitial();
      return;
    }
    await Future.wait([_fetchCT(yearId), _fetchSubjectRows(yearId), _fetchKpi(yearId)]);
  }

  Future<void> _handleCTConfirmLock(int sectionId, int teacherId) async {
    final yearId = _selectedYearId;
    if (yearId == null) return;
    setState(() => _savingCTSects.add(sectionId));
    try {
      final section = _sections.where((s) => s.id == sectionId).firstOrNull;
      final res = await ref.read(academicsRepositoryProvider).assignClassTeacher(
            sectionId: sectionId,
            teacherId: teacherId,
            classId: section?.classId ?? 0,
            academicYearId: yearId,
          );
      if (!res.success) {
        _showToast(res.message.isNotEmpty ? res.message : 'Failed to assign.', type: 'error');
        return;
      }
      if (res.id != null) await ref.read(academicsRepositoryProvider).lockClassTeacher(res.id!);
      _showToast('Class teacher confirmed and locked.');
      await Future.wait([_fetchCT(yearId), _fetchKpi(yearId)]);
    } catch (err) {
      _showToast(err.toString().replaceFirst('Exception: ', ''), type: 'error');
    } finally {
      if (mounted) setState(() => _savingCTSects.remove(sectionId));
    }
  }

  void _handleCTEditRequest(int ctId, String currentTeacherName) {
    showStaffCTChangeDialog(
      context: context,
      currentTeacherName: currentTeacherName,
      teachers: _teachers,
      onConfirm: (newTeacherId, reason) => _handleCTModalConfirm(ctId, newTeacherId, reason),
    );
  }

  Future<void> _handleCTModalConfirm(int ctId, int newTeacherId, String reason) async {
    final yearId = _selectedYearId;
    if (yearId == null) return;
    try {
      final res = await ref.read(academicsRepositoryProvider).unlockClassTeacher(ctId: ctId, newTeacherId: newTeacherId, reason: reason);
      if (!res.success) {
        _showToast(res.message.isNotEmpty ? res.message : 'Failed.', type: 'error');
        return;
      }
      await ref.read(academicsRepositoryProvider).lockClassTeacher(ctId);
      _showToast('Class teacher updated and locked.');
      if (mounted) Navigator.of(context).pop();
      await Future.wait([_fetchCT(yearId), _fetchKpi(yearId)]);
    } catch (err) {
      _showToast(err.toString().replaceFirst('Exception: ', ''), type: 'error');
    }
  }

  Future<void> _handleSubjectSave(int rowId, int teacherId) async {
    setState(() => _savingSubjKeys.add(rowId));
    try {
      final res = await ref.read(academicsRepositoryProvider).assignSubjectTeacher(rowId: rowId, teacherId: teacherId);
      if (!res.success) {
        _showToast(res.message.isNotEmpty ? res.message : 'Failed to save.', type: 'error');
        return;
      }
      _showToast('Subject teacher saved.');
      final yearId = _selectedYearId;
      if (yearId != null) await _fetchSubjectRows(yearId);
    } catch (err) {
      _showToast(err.toString().replaceFirst('Exception: ', ''), type: 'error');
    } finally {
      if (mounted) setState(() => _savingSubjKeys.remove(rowId));
    }
  }

  void _openBulkAssignDialog() {
    showStaffBulkAssignDialog(
      context: context,
      teachers: _teachers,
      classes: _classes,
      sections: _sections,
      onConfirm: _handleBulkAssign,
    );
  }

  Future<void> _handleBulkAssign(int classId, int? sectionId, int teacherId, bool bulkClass) async {
    final yearId = _selectedYearId;
    if (yearId == null) return;
    try {
      final targets = bulkClass ? _sections.where((s) => s.classId == classId).toList() : _sections.where((s) => s.id == sectionId).toList();
      for (final sec in targets) {
        await ref.read(academicsRepositoryProvider).assignClassTeacher(sectionId: sec.id, teacherId: teacherId, classId: classId, academicYearId: yearId);
      }
      _showToast('Class teacher assigned to ${targets.length} section(s).');
      if (mounted) Navigator.of(context).pop();
      await Future.wait([_fetchCT(yearId), _fetchKpi(yearId)]);
    } catch (err) {
      _showToast(err.toString().replaceFirst('Exception: ', ''), type: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClasses = _levelFilter == 'All' ? _classes : _classes.where((c) => staffClassLevel(c.name) == _levelFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB), // var(--page)
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFFF8F8FC), border: Border.all(color: const Color(0xFFDFDFEA)), borderRadius: BorderRadius.circular(16)),
                    child: _loadingInit
                        ? const Padding(padding: EdgeInsets.symmetric(vertical: 96), child: Center(child: CircularProgressIndicator(color: staffBrand)))
                        : _buildContent(filteredClasses),
                  ),
                ),
              ),
            ),
          ]),
        ),
        Positioned(top: 16, right: 16, child: _buildToasts()),
      ]),
    );
  }

  Widget _buildToasts() {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _toasts.map((t) {
          final (bg, border, fg, icon) = t.type == 'success'
              ? (const Color(0xFFF0FDF4), const Color(0xFFBBF7D0), const Color(0xFF166534), Icons.check_circle)
              : t.type == 'error'
                  ? (const Color(0xFFFEF2F2), const Color(0xFFFECACA), const Color(0xFF991B1B), Icons.cancel)
                  : (const Color(0xFFFFFBEB), const Color(0xFFFDE68A), const Color(0xFF92400E), Icons.warning_amber_rounded);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4))]),
            child: Row(children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 12),
              Expanded(child: Text(t.message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg))),
              InkWell(onTap: () => _removeToast(t.id), child: Icon(Icons.close, size: 14, color: fg.withValues(alpha: 0.6))),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(List<FoundationClass> filteredClasses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: staffLine), borderRadius: BorderRadius.circular(16)),
          child: _buildHeader(),
        ),
        const SizedBox(height: 20),
        StaffKpiCards(kpi: _kpi),
        const SizedBox(height: 20),
        _buildTabStrip(),
        const SizedBox(height: 16),
        if (_activeTab == _StaffTab.assignments) ...[
          Wrap(spacing: 6, runSpacing: 6, children: _levelFilters.map(_levelPill).toList()),
          const SizedBox(height: 16),
          if (filteredClasses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: staffLine), borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('No classes found. Configure classes in Core Setup first.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))),
            )
          else
            for (var i = 0; i < filteredClasses.length; i++)
              StaffClassAccordion(
                key: ValueKey(filteredClasses[i].id),
                cls: filteredClasses[i],
                badgeColors: staffClassBadgeColors[i % staffClassBadgeColors.length],
                sections: _sections,
                teachers: _teachers,
                subjectRows: _subjectRows.where((r) => r.classId == filteredClasses[i].id).toList(),
                ctAssignments: _ctAssignments.where((ct) => ct.classId == filteredClasses[i].id).toList(),
                onCTConfirmLock: _handleCTConfirmLock,
                onCTEditRequest: _handleCTEditRequest,
                onSubjectSave: _handleSubjectSave,
                savingCTSects: _savingCTSects,
                savingSubjKeys: _savingSubjKeys,
              ),
        ] else if (_activeTab == _StaffTab.workload)
          StaffWorkloadTab(academicYearId: _selectedYearId)
        else
          const StaffAuditLogTab(),
      ],
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('STAFF RECORDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6F767E), letterSpacing: 1)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Staff ', style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFF1A1D1F))),
            TextSpan(text: 'Assignment', style: GoogleFonts.playfairDisplay(fontSize: 36, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: staffTitleAssignmentPurple)),
          ])),
          const SizedBox(height: 6),
          const Text('Assign class teachers and subject teachers to every section', style: TextStyle(fontSize: 13, color: Color(0xFF6F767E))),
        ]),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (_academicYears.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12), color: Colors.white),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYearId,
                  items: _academicYears.map((y) => DropdownMenuItem(value: y.id, child: Text('${y.name}${y.isCurrent ? ' (Current)' : ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937))))).toList(),
                  onChanged: (v) {
                    if (v != null) _onYearChange(v);
                  },
                ),
              ),
            ),
          ElevatedButton(
            onPressed: _openBulkAssignDialog,
            style: ElevatedButton.styleFrom(backgroundColor: staffBrand, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt, size: 14), SizedBox(width: 8), Text('Bulk Assign', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
          ),
          OutlinedButton(
            onPressed: _refreshAll,
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4B5563), side: const BorderSide(color: Color(0xFFE5E7EB)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.refresh, size: 13), SizedBox(width: 6), Text('Refresh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))]),
          ),
        ]),
      ],
    );
  }

  Widget _buildTabStrip() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _tabButton(_StaffTab.assignments, 'Class Assignments'),
          _tabButton(_StaffTab.workload, 'Workload'),
          _tabButton(_StaffTab.audit, 'Audit Log'),
        ]),
      ),
    );
  }

  Widget _tabButton(_StaffTab tab, String label) {
    final active = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1))] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? staffBrand : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _levelPill(String lvl) {
    final active = _levelFilter == lvl;
    return InkWell(
      onTap: () => setState(() => _levelFilter = lvl),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? staffBrand : Colors.white,
          border: Border.all(color: active ? staffBrand : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(lvl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF4B5563))),
      ),
    );
  }
}
