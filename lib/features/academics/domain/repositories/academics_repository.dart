import '../../../student/domain/models/academic_year.dart';
import '../entities/class_entity.dart';
import '../entities/holiday_entity.dart';
import '../entities/room_entity.dart';
import '../entities/staff_assignment_entities.dart';
import '../entities/subject_entry.dart';

/// Domain-facing seam over the Academics → Foundation & Core Settings APIs.
/// Reference: frontend/components/academics/foundation/** (backend:
/// /api/v1/core/*, /api/v1/academics/*).
abstract class AcademicsRepository {
  // ── Academic Years (Step 1) ──────────────────────────────────────────
  Future<List<AcademicYear>> fetchAcademicYears();

  Future<AcademicYear> createAcademicYear({
    String? board,
    String? numberOfTerms,
    required String startDate,
    required String endDate,
    required bool isCurrent,
    required bool isActive,
  });

  Future<AcademicYear> updateAcademicYear(
    int id, {
    String? board,
    String? numberOfTerms,
    required String startDate,
    required String endDate,
    required bool isCurrent,
    required bool isActive,
  });

  Future<void> deleteAcademicYear(int id);

  // ── Holidays (Step 1 — Holiday Calendar card) ───────────────────────
  Future<List<Holiday>> fetchHolidays({int? academicYearId});

  Future<void> createHoliday({
    required String name,
    required String date,
    String? endDate,
    required String holidayType,
    String description = '',
    int? academicYearId,
  });

  Future<void> updateHoliday(
    int id, {
    required String name,
    required String date,
    String? endDate,
    required String holidayType,
    String description = '',
    int? academicYearId,
  });

  Future<void> deleteHoliday(int id);

  Future<({int created, int skipped})> copyHolidaysFromYear({
    required int sourceYearId,
    required int targetYearId,
    required bool shiftYear,
  });

  // ── Classes (Step 2) ─────────────────────────────────────────────────
  Future<List<FoundationClass>> fetchClasses();

  Future<void> createClass({required String name, int? capacity, List<({int streamId, int capacity})>? streamCapacities});

  Future<void> updateClass(int id, {required String name, List<({int streamId, int capacity})>? streamCapacities});

  Future<void> deleteClass(int id);

  Future<void> toggleClassActive(int id, bool isActive);

  // Streams
  Future<List<StreamDetail>> fetchStreams();
  Future<StreamDetail> createStream(String name);

  // ── Sections (Step 3) ────────────────────────────────────────────────
  Future<({int created, int deleted})> replaceSections({
    required List<int> classIds,
    required List<String> oldNames,
    required List<String> newNames,
    required int capacity,
  });
  Future<void> renameSection(int id, String name);
  Future<void> deleteSection(int id);
  Future<int> bulkDeleteSections(List<int> ids);

  // ── Subjects / Class-Subject Entries (Step 4) ───────────────────────
  Future<List<ClassSubjectEntry>> fetchClassSubjectEntries();
  Future<List<String>> fetchGlobalSubjectNames();

  /// Fans a single subject out to one or more classes in one call — mirrors
  /// the backend's custom `create()` (not a plain per-class POST).
  Future<({int created, int skipped, List<ClassSubjectEntry> data, List<({int classId, String message})> errors})> createSubjectEntry({
    required List<int> classIds,
    required String name,
    required String code,
    required String subjectType,
    int? periodsPerWeek,
  });

  Future<ClassSubjectEntry> updateSubjectEntry(
    int id, {
    required String name,
    required String code,
    required String subjectType,
    required int periodsPerWeek,
  });

  Future<ClassSubjectEntry> toggleSubjectEntryActive(int id, bool activeStatus);

  Future<void> deleteSubjectEntry(int id);

  Future<void> resetClassSubjects(int classId);

  // ── Rooms (Step 5) ───────────────────────────────────────────────────
  Future<List<FoundationRoom>> fetchRooms();
  Future<void> createRoom({required String roomNo, String floor = '', required int capacity, int? sectionId});
  Future<void> updateRoom(int id, {required String roomNo, String floor = '', required int capacity, int? sectionId});
  Future<void> toggleRoomActive(int id, bool activeStatus);
  Future<void> deleteRoom(int id);

  // ── Staff Assignment ─────────────────────────────────────────────────
  Future<List<StaffTeacher>> fetchStaffTeachers();

  Future<List<CTAssignment>> fetchClassTeacherAssignments({int? academicYearId});

  /// Mirrors POST /staff/class-teachers/ — creates a new CT assignment, or
  /// (if one already exists and is unlocked) updates its teacher in place.
  Future<({bool success, String message, int? id})> assignClassTeacher({
    required int sectionId,
    required int teacherId,
    required int classId,
    required int academicYearId,
  });

  Future<void> lockClassTeacher(int ctId);

  /// Mirrors POST /staff/class-teachers/{id}/unlock/ — records an audit
  /// entry, unlocks, and (if a new teacher is given) reassigns in one call.
  Future<({bool success, String message})> unlockClassTeacher({
    required int ctId,
    int? newTeacherId,
    required String reason,
  });

  Future<List<StaffSubjectRow>> fetchStaffSubjectRows({int? academicYearId, int? classId, int? sectionId});

  Future<({bool success, String message})> assignSubjectTeacher({required int rowId, required int teacherId});

  Future<StaffKpi> fetchStaffKpi({int? academicYearId});

  Future<List<StaffWorkloadEntry>> fetchStaffWorkload({int? academicYearId});

  Future<List<StaffAuditLogEntry>> fetchStaffAuditLog();
}
