import '../models/academic_year.dart';
import '../models/school_class.dart';
import '../models/student_data.dart';
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
}
