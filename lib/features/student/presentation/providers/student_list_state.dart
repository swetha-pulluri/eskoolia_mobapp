import '../../domain/models/academic_year.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_data.dart';
import '../../domain/models/student_stats.dart';
import '../../domain/repositories/student_repository.dart';

/// Sentinel used by [StudentListState.copyWith] to distinguish "leave this
/// field unchanged" from "set this field to null".
const Object _unset = Object();

/// State for the Student List screen — mirrors frontend
/// StudentListPanel.tsx's structure: a "Smart filters" panel whose values
/// only take effect on Apply, and a "Browse & edit by class" accordion.
///
/// Mobile simplification (disclosed): the frontend's accordion allows
/// multiple classes open with per-class section tabs; here only one class
/// is expanded at a time (opening another collapses the previous), each
/// showing one active section's table — a standard mobile-accordion
/// simplification that keeps the same underlying browse/filter/paginate
/// interactions without stacking several open tables at once on a phone.
class StudentListState {
  final bool loadingStats;
  final StudentStats? stats;

  final bool loadingClasses;
  final String? classesError;
  final List<SchoolClass> classes;

  final bool filtersPanelExpanded;
  final bool browsePanelExpanded;

  // Filter draft values (editable; only take effect when Apply is pressed).
  final String searchDraft;
  final int? academicYearIdDraft;
  final int? classIdFilterDraft;
  final int? sectionIdFilterDraft;
  final StudentStatusFilter statusDraft;
  final bool specialNeedsDraft;
  final bool hasAllergyDraft;
  final bool onMedicationDraft;

  // Applied filter values (drive the currently-open section's fetch).
  final bool filtersApplied;
  final String appliedSearch;
  final int? appliedClassId;
  final int? appliedSectionId;
  final StudentStatusFilter appliedStatus;
  final bool appliedSpecialNeeds;
  final bool appliedHasAllergy;
  final bool appliedOnMedication;

  final List<AcademicYear> academicYears;

  // Browse-by-class / active section table.
  final int? expandedClassId;
  final int? activeSectionId;
  final bool sectionLoading;
  final String? sectionError;
  final List<StudentData> sectionStudents;
  final int sectionTotalCount;
  final int sectionPage;
  final Set<int> selectedIds;
  final Set<int> mutatingIds;

  /// Classes confirmed (via a probe fetch) to have at least one student with
  /// no section — mirrors the frontend's `classesWithUnassigned` state,
  /// which reveals a synthetic "Unassigned" tab per class once known.
  final Set<int> classesWithUnassigned;

  /// Per-class count of section-less students, for the "Unassigned" tab's
  /// badge — mirrors the frontend's `classSectionStudents.get(secKey)
  /// ?.length` for that synthetic key.
  final Map<int, int> unassignedCounts;

  final String? flashSuccess;
  final String? flashError;

  const StudentListState({
    required this.loadingStats,
    this.stats,
    required this.loadingClasses,
    this.classesError,
    required this.classes,
    required this.filtersPanelExpanded,
    required this.browsePanelExpanded,
    required this.searchDraft,
    this.academicYearIdDraft,
    this.classIdFilterDraft,
    this.sectionIdFilterDraft,
    required this.statusDraft,
    required this.specialNeedsDraft,
    required this.hasAllergyDraft,
    required this.onMedicationDraft,
    required this.filtersApplied,
    required this.appliedSearch,
    this.appliedClassId,
    this.appliedSectionId,
    required this.appliedStatus,
    required this.appliedSpecialNeeds,
    required this.appliedHasAllergy,
    required this.appliedOnMedication,
    required this.academicYears,
    this.expandedClassId,
    this.activeSectionId,
    required this.sectionLoading,
    this.sectionError,
    required this.sectionStudents,
    required this.sectionTotalCount,
    required this.sectionPage,
    required this.selectedIds,
    required this.mutatingIds,
    required this.classesWithUnassigned,
    required this.unassignedCounts,
    this.flashSuccess,
    this.flashError,
  });

  factory StudentListState.initial() {
    return const StudentListState(
      loadingStats: true,
      loadingClasses: true,
      classes: [],
      filtersPanelExpanded: true,
      browsePanelExpanded: true,
      searchDraft: '',
      statusDraft: StudentStatusFilter.all,
      specialNeedsDraft: false,
      hasAllergyDraft: false,
      onMedicationDraft: false,
      filtersApplied: false,
      appliedSearch: '',
      appliedStatus: StudentStatusFilter.all,
      appliedSpecialNeeds: false,
      appliedHasAllergy: false,
      appliedOnMedication: false,
      academicYears: [],
      sectionLoading: false,
      sectionStudents: [],
      sectionTotalCount: 0,
      sectionPage: 1,
      selectedIds: {},
      mutatingIds: {},
      classesWithUnassigned: {},
      unassignedCounts: {},
    );
  }

  StudentListState copyWith({
    bool? loadingStats,
    Object? stats = _unset,
    bool? loadingClasses,
    Object? classesError = _unset,
    List<SchoolClass>? classes,
    bool? filtersPanelExpanded,
    bool? browsePanelExpanded,
    String? searchDraft,
    Object? academicYearIdDraft = _unset,
    Object? classIdFilterDraft = _unset,
    Object? sectionIdFilterDraft = _unset,
    StudentStatusFilter? statusDraft,
    bool? specialNeedsDraft,
    bool? hasAllergyDraft,
    bool? onMedicationDraft,
    bool? filtersApplied,
    String? appliedSearch,
    Object? appliedClassId = _unset,
    Object? appliedSectionId = _unset,
    StudentStatusFilter? appliedStatus,
    bool? appliedSpecialNeeds,
    bool? appliedHasAllergy,
    bool? appliedOnMedication,
    List<AcademicYear>? academicYears,
    Object? expandedClassId = _unset,
    Object? activeSectionId = _unset,
    bool? sectionLoading,
    Object? sectionError = _unset,
    List<StudentData>? sectionStudents,
    int? sectionTotalCount,
    int? sectionPage,
    Set<int>? selectedIds,
    Set<int>? mutatingIds,
    Set<int>? classesWithUnassigned,
    Map<int, int>? unassignedCounts,
    Object? flashSuccess = _unset,
    Object? flashError = _unset,
  }) {
    return StudentListState(
      loadingStats: loadingStats ?? this.loadingStats,
      stats: identical(stats, _unset) ? this.stats : stats as StudentStats?,
      loadingClasses: loadingClasses ?? this.loadingClasses,
      classesError: identical(classesError, _unset) ? this.classesError : classesError as String?,
      classes: classes ?? this.classes,
      filtersPanelExpanded: filtersPanelExpanded ?? this.filtersPanelExpanded,
      browsePanelExpanded: browsePanelExpanded ?? this.browsePanelExpanded,
      searchDraft: searchDraft ?? this.searchDraft,
      academicYearIdDraft: identical(academicYearIdDraft, _unset)
          ? this.academicYearIdDraft
          : academicYearIdDraft as int?,
      classIdFilterDraft: identical(classIdFilterDraft, _unset)
          ? this.classIdFilterDraft
          : classIdFilterDraft as int?,
      sectionIdFilterDraft: identical(sectionIdFilterDraft, _unset)
          ? this.sectionIdFilterDraft
          : sectionIdFilterDraft as int?,
      statusDraft: statusDraft ?? this.statusDraft,
      specialNeedsDraft: specialNeedsDraft ?? this.specialNeedsDraft,
      hasAllergyDraft: hasAllergyDraft ?? this.hasAllergyDraft,
      onMedicationDraft: onMedicationDraft ?? this.onMedicationDraft,
      filtersApplied: filtersApplied ?? this.filtersApplied,
      appliedSearch: appliedSearch ?? this.appliedSearch,
      appliedClassId: identical(appliedClassId, _unset) ? this.appliedClassId : appliedClassId as int?,
      appliedSectionId:
          identical(appliedSectionId, _unset) ? this.appliedSectionId : appliedSectionId as int?,
      appliedStatus: appliedStatus ?? this.appliedStatus,
      appliedSpecialNeeds: appliedSpecialNeeds ?? this.appliedSpecialNeeds,
      appliedHasAllergy: appliedHasAllergy ?? this.appliedHasAllergy,
      appliedOnMedication: appliedOnMedication ?? this.appliedOnMedication,
      academicYears: academicYears ?? this.academicYears,
      expandedClassId: identical(expandedClassId, _unset) ? this.expandedClassId : expandedClassId as int?,
      activeSectionId: identical(activeSectionId, _unset) ? this.activeSectionId : activeSectionId as int?,
      sectionLoading: sectionLoading ?? this.sectionLoading,
      sectionError: identical(sectionError, _unset) ? this.sectionError : sectionError as String?,
      sectionStudents: sectionStudents ?? this.sectionStudents,
      sectionTotalCount: sectionTotalCount ?? this.sectionTotalCount,
      sectionPage: sectionPage ?? this.sectionPage,
      selectedIds: selectedIds ?? this.selectedIds,
      mutatingIds: mutatingIds ?? this.mutatingIds,
      classesWithUnassigned: classesWithUnassigned ?? this.classesWithUnassigned,
      unassignedCounts: unassignedCounts ?? this.unassignedCounts,
      flashSuccess: identical(flashSuccess, _unset) ? this.flashSuccess : flashSuccess as String?,
      flashError: identical(flashError, _unset) ? this.flashError : flashError as String?,
    );
  }
}
