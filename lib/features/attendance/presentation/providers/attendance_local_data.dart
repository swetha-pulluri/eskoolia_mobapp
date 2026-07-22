import '../../domain/entities/attendance_entities.dart';

/// ========================================================================
/// UI-ONLY LOCAL DATA STORE — Attendance module (no backend/API calls)
/// ========================================================================
/// Mirrors the "no backend" architecture already established for
/// Administration and Admissions in this project.
///
/// Classes / sections / students start EMPTY: on web, `useClasses` and
/// `useStudents` fetch everything from `/api/v1/core/classes/`,
/// `/api/v1/core/sections/`, and `/api/v1/attendance/student-attendance/
/// student-search/` with zero hardcoded fallback data (verified by reading
/// both hooks in full) — exactly the same "backend-driven, no static demo
/// data" shape already followed for Administration's classes/sections and
/// Admissions' inquiries/classes. Inventing rows here would show data that
/// doesn't exist in the web app.
/// ========================================================================
class AttendanceLocalData {
  AttendanceLocalData._();

  /// AVATAR_COLORS from web's `useStudents.ts`, cycled by `id % 6`.
  static const List<int> avatarColors = [0xFF4729F4, 0xFF0A8C5A, 0xFFB4721B, 0xFFC2264E, 0xFF7B61FF, 0xFF0891B2];

  static final List<ClassInfoEntity> _classes = [];

  /// Keyed by "classId-sectionId".
  static final Map<String, List<AttendanceStudentEntity>> _students = {};

  static Future<List<ClassInfoEntity>> getClasses() async => List.of(_classes);

  static Future<List<AttendanceStudentEntity>> getStudents(int classId, int sectionId) async {
    return List.of(_students['$classId-$sectionId'] ?? const []);
  }

  static Future<void> setStudents(int classId, int sectionId, List<AttendanceStudentEntity> students) async {
    _students['$classId-$sectionId'] = students;
  }

  static Future<AttendanceStudentEntity> updateStudent(
    int classId,
    int sectionId,
    int studentId,
    AttendanceStudentEntity Function(AttendanceStudentEntity current) update,
  ) async {
    final key = '$classId-$sectionId';
    final list = _students[key];
    if (list == null) throw StateError('Section not loaded: $key');
    final index = list.indexWhere((s) => s.id == studentId);
    final updated = update(list[index]);
    list[index] = updated;
    return updated;
  }

  /// Recomputed class-level present/absent/late totals from whichever
  /// sections of this class currently have loaded students — mirrors web's
  /// `class-summary` endpoint result being merged onto `ClassInfo`.
  static Future<void> refreshClassSummary() async {
    for (var i = 0; i < _classes.length; i++) {
      final cls = _classes[i];
      final loaded = cls.sections.expand((sec) => _students['${cls.id}-${sec.id}'] ?? const <AttendanceStudentEntity>[]);
      if (loaded.isEmpty) continue;
      final present = loaded.where((s) => s.status == 'present').length;
      final absent = loaded.where((s) => s.status == 'absent').length;
      final late = loaded.where((s) => s.status == 'late').length;
      final total = cls.totalStudents;
      final pct = total > 0 ? (((present + late) / total) * 100).round().clamp(0, 100) : 0;
      _classes[i] = cls.copyWith(totalPresent: present, totalAbsent: absent, totalLate: late, overallPct: pct);
    }
  }
}
