import '../../domain/models/academic_year.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_data.dart';
import '../../domain/models/student_stats.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';

/// Real (Dio-backed) implementation — unlike role_repository_impl.dart /
/// login_permission_repository_impl.dart, this one isn't a pure delegate:
/// the Students API has no single endpoint matching a few of the mock's
/// higher-level operations (bulk activate/archive, "students filtered by
/// special needs/allergy/medication/new/docs pending"), so this repository
/// composes several datasource calls the same way the reference frontend's
/// own component code does, rather than a backend endpoint doing it.
class StudentRepositoryImpl implements StudentRepository {
  final StudentRemoteDataSource _remoteDataSource;

  StudentRepositoryImpl(this._remoteDataSource);

  @override
  Future<StudentStats> fetchStats() => _remoteDataSource.fetchStats();

  @override
  Future<List<SchoolClass>> fetchClasses() => _remoteDataSource.fetchClasses();

  @override
  Future<List<AcademicYear>> fetchAcademicYears() => _remoteDataSource.fetchAcademicYears();

  @override
  Future<List<StudentCategory>> fetchCategories() => _remoteDataSource.fetchCategories();

  @override
  Future<StudentsPage> fetchStudentsBySection({
    required int sectionId,
    String? search,
    StudentStatusFilter filter = StudentStatusFilter.all,
    bool specialNeedsOnly = false,
    bool hasAllergyOnly = false,
    bool onMedicationOnly = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    // Section ids are unique per school (not scoped per class), so a
    // section filter alone is enough to identify the roster — matches how
    // `current_section` is used across the reference frontend's own calls.
    bool? isActive;
    var deletedOnly = false;
    switch (filter) {
      case StudentStatusFilter.all:
      case StudentStatusFilter.newThisMonth:
      case StudentStatusFilter.docsPending:
        break;
      case StudentStatusFilter.active:
        isActive = true;
      case StudentStatusFilter.inactive:
        isActive = false;
      case StudentStatusFilter.archived:
        deletedOnly = true;
    }

    final page0 = await _remoteDataSource.fetchStudents(
      sectionId: sectionId,
      search: search,
      isActive: isActive,
      deletedOnly: deletedOnly,
      page: page,
      pageSize: pageSize,
    );

    // `new this month` / `docs pending` and the special-needs/allergy/
    // medication toggles have no backend query param — mirrors the
    // reference frontend's own client-side-only filtering for these exact
    // categories. Applied over just this page, same limitation the
    // frontend has (the "count"/pager reflects the server-side filtered
    // set, not this sub-filter).
    var results = page0.results;
    final now = DateTime.now();
    if (filter == StudentStatusFilter.newThisMonth) {
      results = results.where((s) => s.isNewThisMonth(now)).toList();
    } else if (filter == StudentStatusFilter.docsPending) {
      results = results.where((s) => s.docsPendingCount > 0).toList();
    }
    if (specialNeedsOnly) results = results.where((s) => s.isSpeciallyAbled).toList();
    if (hasAllergyOnly) results = results.where((s) => s.hasAllergy).toList();
    if (onMedicationOnly) results = results.where((s) => s.onMedication).toList();

    if (identical(results, page0.results)) return page0;
    return StudentsPage(results: results, count: page0.count);
  }

  @override
  Future<StudentData> fetchStudentDetail(int id) => _remoteDataSource.fetchStudentDetail(id);

  @override
  Future<(String, String)?> fetchGuardianDetail(int guardianId) async {
    try {
      return await _remoteDataSource.fetchGuardianDetail(guardianId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> fetchNextAdmissionNo() => _remoteDataSource.fetchNextAdmissionNo();

  @override
  Future<void> setStudentsStatus(List<int> ids, {required bool isActive}) async {
    // No bulk activate/deactivate endpoint exists for students (only per-id
    // `set-status`) — mirrors the reference frontend, which also loops one
    // POST per selected row rather than a single bulk call. Deactivating
    // requires a non-empty `reason` server-side; activating does not.
    for (final id in ids) {
      await _remoteDataSource.setStudentStatus(
        id,
        isActive: isActive,
        reason: isActive ? '' : 'Deactivated via mobile app',
      );
    }
  }

  @override
  Future<void> archiveStudents(List<int> ids, {required String reason}) async {
    for (final id in ids) {
      await _remoteDataSource.archiveStudent(id, reason: reason);
    }
  }

  @override
  Future<StudentData> createStudent(StudentData draft) async {
    // Guardians are a separate resource on the backend (Student.guardian is
    // a single nullable FK, not a nested write) — resolve/create the
    // primary guardian first, exactly like StudentAddPanel.tsx does, then
    // send its id as `guardian` on the student payload.
    int? guardianId;
    final name = draft.guardianName?.trim() ?? '';
    if (name.isNotEmpty) {
      guardianId = await _remoteDataSource.createGuardian(
        fullName: name,
        relation: draft.guardianRelation?.trim().isNotEmpty == true
            ? draft.guardianRelation!.trim()
            : 'Father',
        phone: draft.guardianPhone?.trim() ?? '',
      );
    }
    final body = draft.toRequestJson(guardianId: guardianId);
    return _remoteDataSource.createStudent(body);
  }
}
