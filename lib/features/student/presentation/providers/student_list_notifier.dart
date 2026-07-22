import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/student_data.dart';
import '../../domain/repositories/student_repository.dart';
import 'student_list_state.dart';

const int _sectionPageSize = 10;

class StudentListNotifier extends StateNotifier<StudentListState> {
  final StudentRepository _repository;

  /// Per-class running tally of *distinct* students seen so far across all
  /// of that class's sections — accumulated as the user browses (see
  /// `_accumulateClassStats`). The real backend has no per-class aggregate
  /// endpoint, so — exactly like the reference frontend's own
  /// `classSectionStudents`-derived card stats — these badges only become
  /// accurate for classes/sections that have actually been opened.
  final Map<int, Set<int>> _seenStudentIdsByClass = {};

  StudentListNotifier(this._repository) : super(StudentListState.initial()) {
    _loadStats();
    _loadClasses();
    _loadAcademicYears();
  }

  String _cleanMessage(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _loadStats() async {
    state = state.copyWith(loadingStats: true);
    try {
      final stats = await _repository.fetchStats();
      if (!mounted) return;
      state = state.copyWith(loadingStats: false, stats: stats);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loadingStats: false, flashError: _cleanMessage(e));
    }
  }

  Future<void> _loadAcademicYears() async {
    try {
      final years = await _repository.fetchAcademicYears();
      if (!mounted) return;
      state = state.copyWith(
        academicYears: years,
        academicYearIdDraft: years.where((y) => y.isCurrent).firstOrNull?.id,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(flashError: _cleanMessage(e));
    }
  }

  Future<void> _loadClasses() async {
    state = state.copyWith(loadingClasses: true, classesError: null);
    try {
      final classes = await _repository.fetchClasses();
      if (!mounted) return;
      state = state.copyWith(loadingClasses: false, classes: classes);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loadingClasses: false, classesError: _cleanMessage(e));
    }
  }

  void refresh() {
    _loadStats();
    _loadClasses();
  }

  void toggleFiltersPanel() {
    state = state.copyWith(filtersPanelExpanded: !state.filtersPanelExpanded);
  }

  void toggleBrowsePanel() {
    state = state.copyWith(browsePanelExpanded: !state.browsePanelExpanded);
  }

  void updateSearchDraft(String value) {
    state = state.copyWith(searchDraft: value);
  }

  void updateAcademicYearDraft(int? id) {
    state = state.copyWith(academicYearIdDraft: id);
  }

  /// Mirrors the frontend's `setClassFilter(...); setSectionFilter("")` pair —
  /// changing the class always clears the (now-stale) section selection.
  void updateClassFilterDraft(int? classId) {
    state = state.copyWith(classIdFilterDraft: classId, sectionIdFilterDraft: null);
  }

  void updateSectionFilterDraft(int? sectionId) {
    state = state.copyWith(sectionIdFilterDraft: sectionId);
  }

  void updateStatusDraft(StudentStatusFilter filter) {
    state = state.copyWith(statusDraft: filter);
  }

  void toggleSpecialNeedsDraft() {
    state = state.copyWith(specialNeedsDraft: !state.specialNeedsDraft);
  }

  void toggleHasAllergyDraft() {
    state = state.copyWith(hasAllergyDraft: !state.hasAllergyDraft);
  }

  void toggleOnMedicationDraft() {
    state = state.copyWith(onMedicationDraft: !state.onMedicationDraft);
  }

  void applyPreset({
    StudentStatusFilter? status,
    bool? specialNeeds,
    bool? hasAllergy,
    bool? onMedication,
  }) {
    state = state.copyWith(
      statusDraft: status ?? StudentStatusFilter.all,
      specialNeedsDraft: specialNeeds ?? false,
      hasAllergyDraft: hasAllergy ?? false,
      onMedicationDraft: onMedication ?? false,
    );
    applyFilters();
  }

  void resetFilters() {
    state = state.copyWith(
      searchDraft: '',
      classIdFilterDraft: null,
      sectionIdFilterDraft: null,
      statusDraft: StudentStatusFilter.all,
      specialNeedsDraft: false,
      hasAllergyDraft: false,
      onMedicationDraft: false,
      filtersApplied: false,
      appliedSearch: '',
      appliedClassId: null,
      appliedSectionId: null,
      appliedStatus: StudentStatusFilter.all,
      appliedSpecialNeeds: false,
      appliedHasAllergy: false,
      appliedOnMedication: false,
    );
    if (state.activeSectionId != null) _loadSection(page: 1);
  }

  /// Frontend gate: filter values only take effect on Apply — mirrors
  /// StudentListPanel.tsx's `filterApplied` state.
  void applyFilters() {
    state = state.copyWith(
      filtersApplied: true,
      appliedSearch: state.searchDraft,
      appliedClassId: state.classIdFilterDraft,
      appliedSectionId: state.sectionIdFilterDraft,
      appliedStatus: state.statusDraft,
      appliedSpecialNeeds: state.specialNeedsDraft,
      appliedHasAllergy: state.hasAllergyDraft,
      appliedOnMedication: state.onMedicationDraft,
    );
    if (state.activeSectionId != null) _loadSection(page: 1);
  }

  void toggleClass(int classId) {
    if (state.expandedClassId == classId) {
      state = state.copyWith(expandedClassId: null, activeSectionId: null, sectionStudents: []);
      return;
    }
    final schoolClass = state.classes.where((c) => c.id == classId).firstOrNull;
    final firstSection = schoolClass?.sections.firstOrNull;
    state = state.copyWith(
      expandedClassId: classId,
      activeSectionId: firstSection?.id,
      selectedIds: {},
    );
    if (firstSection != null) _loadSection(page: 1);
  }

  void selectSectionTab(int sectionId) {
    state = state.copyWith(activeSectionId: sectionId, selectedIds: {});
    _loadSection(page: 1);
  }

  Future<void> _loadSection({required int page}) async {
    final sectionId = state.activeSectionId;
    if (sectionId == null) return;
    state = state.copyWith(sectionLoading: true, sectionError: null, sectionPage: page);
    try {
      final result = await _repository.fetchStudentsBySection(
        sectionId: sectionId,
        search: state.appliedSearch,
        filter: state.appliedStatus,
        specialNeedsOnly: state.appliedSpecialNeeds,
        hasAllergyOnly: state.appliedHasAllergy,
        onMedicationOnly: state.appliedOnMedication,
        page: page,
        pageSize: _sectionPageSize,
      );
      if (!mounted || state.activeSectionId != sectionId) return;
      state = state.copyWith(
        sectionLoading: false,
        sectionStudents: result.results,
        sectionTotalCount: result.count,
      );
      final classId = state.expandedClassId;
      if (classId != null) _accumulateClassStats(classId, result.results);
    } catch (e) {
      if (!mounted || state.activeSectionId != sectionId) return;
      state = state.copyWith(
        sectionLoading: false,
        sectionError: _cleanMessage(e),
        sectionStudents: [],
        sectionTotalCount: 0,
      );
    }
  }

  /// Folds newly-fetched rows into that class's running active/docs-pending
  /// tally, counting each student id at most once even if the same section
  /// page is re-fetched (e.g. paging back and forth). See the field doc on
  /// `_seenStudentIdsByClass` for why this is progressive, not exact.
  void _accumulateClassStats(int classId, List<StudentData> students) {
    final seen = _seenStudentIdsByClass.putIfAbsent(classId, () => {});
    var activeDelta = 0;
    var docsPendingDelta = 0;
    for (final student in students) {
      if (seen.add(student.id)) {
        if (student.isActive) activeDelta++;
        if (student.docsPendingCount > 0) docsPendingDelta++;
      }
    }
    if (activeDelta == 0 && docsPendingDelta == 0) return;
    final index = state.classes.indexWhere((c) => c.id == classId);
    if (index == -1) return;
    final current = state.classes[index];
    final updated = [...state.classes];
    updated[index] = current.copyWith(
      activeCount: current.activeCount + activeDelta,
      docsPendingCount: current.docsPendingCount + docsPendingDelta,
    );
    state = state.copyWith(classes: updated);
  }

  void goToSectionPage(int page) => _loadSection(page: page);

  void toggleSelectRow(int studentId, bool selected) {
    final next = {...state.selectedIds};
    if (selected) {
      next.add(studentId);
    } else {
      next.remove(studentId);
    }
    state = state.copyWith(selectedIds: next);
  }

  void toggleSelectAllOnPage(bool selected) {
    final next = {...state.selectedIds};
    if (selected) {
      next.addAll(state.sectionStudents.map((s) => s.id));
    } else {
      next.removeAll(state.sectionStudents.map((s) => s.id));
    }
    state = state.copyWith(selectedIds: next);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  /// Used by both the bulk action bar (selected ids) and a single row's
  /// status pill / row action (one id) — same underlying call either way.
  Future<void> setStatusForIds(List<int> ids, {required bool isActive}) async {
    if (ids.isEmpty) return;
    state = state.copyWith(mutatingIds: {...state.mutatingIds, ...ids});
    try {
      await _repository.setStudentsStatus(ids, isActive: isActive);
      if (!mounted) return;
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference(ids.toSet()),
        selectedIds: state.selectedIds.difference(ids.toSet()),
        flashSuccess: isActive
            ? '${ids.length} student${ids.length == 1 ? '' : 's'} activated.'
            : '${ids.length} student${ids.length == 1 ? '' : 's'} deactivated.',
        flashError: null,
      );
      await _loadSection(page: state.sectionPage);
      _loadStats();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference(ids.toSet()),
        flashError: _cleanMessage(e),
        flashSuccess: null,
      );
    }
  }

  Future<void> setSelectedActive(bool isActive) =>
      setStatusForIds(state.selectedIds.toList(), isActive: isActive);

  /// Used by both the bulk action bar (selected ids) and a single row's
  /// archive action (one id).
  Future<void> archiveIds(List<int> ids, {required String reason}) async {
    if (ids.isEmpty) return;
    state = state.copyWith(mutatingIds: {...state.mutatingIds, ...ids});
    try {
      await _repository.archiveStudents(ids, reason: reason);
      if (!mounted) return;
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference(ids.toSet()),
        selectedIds: state.selectedIds.difference(ids.toSet()),
        flashSuccess: '${ids.length} student${ids.length == 1 ? '' : 's'} archived.',
        flashError: null,
      );
      await _loadSection(page: state.sectionPage);
      _loadStats();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        mutatingIds: state.mutatingIds.difference(ids.toSet()),
        flashError: _cleanMessage(e),
        flashSuccess: null,
      );
    }
  }

  Future<void> archiveSelected(String reason) =>
      archiveIds(state.selectedIds.toList(), reason: reason);

  void dismissFlash() {
    state = state.copyWith(flashSuccess: null, flashError: null);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
