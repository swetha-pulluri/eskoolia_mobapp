import '../models/academic_year.dart';
import '../models/school_class.dart';
import '../models/student_attendance_record.dart';
import '../models/student_data.dart';
import '../models/student_record_audit.dart';
import '../models/student_stats.dart';

/// Status filter for the List screen's "Panel 01 — Smart filters" status
/// pills — mirrors frontend StudentListPanel.tsx's StatusFilter union.
enum StudentStatusFilter { all, active, inactive, archived, newThisMonth, docsPending }

/// Domain-facing seam over the Students API.
/// Reference: frontend/components/students/StudentListPanel.tsx +
/// StudentAddPanel.tsx (backend: /api/v1/students/*, /api/v1/core/*).
///
/// Backed by StudentRepositoryImpl (Dio), the same seam pattern used by
/// roles/login_permission — the mock implementation this replaced is gone.
abstract class StudentRepository {
  Future<StudentStats> fetchStats();

  /// Classes with their nested sections (+ live student counts) — powers
  /// the "Browse & edit by class" accordion.
  Future<List<SchoolClass>> fetchClasses();

  Future<List<AcademicYear>> fetchAcademicYears();

  /// Categories are free-text rows the school creates (e.g. General/OBC/SC/
  /// ST/EWS) — carries a real id since the Enroll form's create/update
  /// payload sends `category` as a Guardian-style FK id, not a name string.
  Future<List<StudentCategory>> fetchCategories();

  /// Students within one section, already paginated (frontend's own
  /// section-level pager, 10/page). `count` on the returned page is the
  /// total matching the filters (not just this page), for the "X–Y of N"
  /// footer text.
  Future<StudentsPage> fetchStudentsBySection({
    required int sectionId,
    String? search,
    StudentStatusFilter filter = StudentStatusFilter.all,
    bool specialNeedsOnly = false,
    bool hasAllergyOnly = false,
    bool onMedicationOnly = false,
    int page = 1,
    int pageSize = 10,
  });

  Future<StudentData> fetchStudentDetail(int id);

  /// Resolves a linked guardian's display name/phone for the Profile page's
  /// Contact section — `Student.guardian` is only a raw FK id, never nested.
  /// Returns null if [guardianId] can't be resolved (e.g. a transient
  /// network error) so the caller can fall back to a "Linked" placeholder
  /// instead of crashing the whole profile view over a secondary field.
  Future<(String fullName, String phone)?> fetchGuardianDetail(int guardianId);

  Future<String> fetchNextAdmissionNo();

  Future<void> setStudentsStatus(List<int> ids, {required bool isActive});

  Future<void> archiveStudents(List<int> ids, {required String reason});

  Future<StudentData> createStudent(StudentData draft);

  /// Note: a guardian edited during this call is not round-tripped back to
  /// the Guardian resource (no PATCH /guardians/{id}/ endpoint is wired) —
  /// an existing linked guardian id is preserved as-is; a guardian is only
  /// newly created if the student didn't have one linked yet.
  Future<StudentData> updateStudent(int id, StudentData draft);

  /// A student's attendance for [from]..[to] inclusive (backend field is a
  /// letter code — see [StudentAttendanceRecord] for the normalisation).
  Future<List<StudentAttendanceRecord>> fetchStudentAttendance(
    int studentId, {
    required DateTime from,
    required DateTime to,
  });

  /// Uploads a photo and returns its URL, ready to attach to a student
  /// create/update payload's `photo` field.
  Future<String> uploadStudentPhoto({required List<int> bytes, required String filename});

  /// Only valid once a student has a real backend id (i.e. after creation,
  /// or while editing) — the frontend's own new-enrollment flow uploads
  /// documents against a server-assigned draft id that this pass doesn't
  /// reproduce, so document upload during a brand-new enrollment stays
  /// deferred (see student_enroll_page.dart's Documents step).
  Future<void> uploadStudentDocument({
    required int studentId,
    required String documentType,
    required List<int> bytes,
    required String filename,
  });

  /// General-purpose filtered/paginated fetch used by the Disabled/Deleted
  /// /Restore/Unassigned screens — unlike [fetchStudentsBySection] this
  /// isn't scoped to one section and doesn't apply the List screen's
  /// client-only sub-filters (special needs/allergy/medication/new this
  /// month), none of which apply here.
  Future<StudentsPage> fetchStudentsFiltered({
    int? classId,
    int? sectionId,
    String? search,
    bool? isActive,
    bool deletedOnly = false,
    bool? unassigned,
    int page = 1,
    int pageSize = 25,
  });

  /// Disabled Students screen's "Enable" — `PATCH {is_disabled:false,
  /// is_active:true}`, distinct from [setStudentsStatus]'s `set-status`
  /// endpoint (which never touches `is_disabled`).
  Future<void> enableStudents(List<int> ids);

  /// Unassigned Students screen's per-row/bulk "Assign to class" action.
  Future<void> assignClassSection(List<int> ids, {required int classId, required int sectionId});

  Future<void> restoreStudents(List<int> ids);

  /// Superuser-only server-side (see `permanent-delete` view) — callers
  /// should gate this action's visibility on the current user's role.
  Future<void> permanentDeleteStudent(int id);

  Future<List<StudentRecordAudit>> fetchRecordAudits({
    int? studentId,
    String? action,
    int? classId,
    int? sectionId,
    String? search,
  });

  /// The only real backend-wired student export (fixed 8 columns, .xlsx) —
  /// see student_export_page.dart for the CSV/PDF/column-picker gap
  /// disclosure.
  Future<List<int>> exportStudentsXlsx({int? classId, int? sectionId, bool? isActive});

  /// Powers the "Browse & edit by class" accordion's synthetic "Unassigned"
  /// tab — mirrors the frontend's own `loadClassSection(classId,
  /// UNASSIGNED_SECTION_ID)` exactly: there's no backend endpoint for
  /// "students in class X with no section", so this fetches the whole class
  /// (up to 200, matching the frontend's own page size) and filters
  /// client-side for a null/zero section, the same client-side approach the
  /// reference frontend uses for this exact feature.
  Future<List<StudentData>> fetchClassUnassignedStudents(int classId, {String? search});
}
