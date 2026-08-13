import '../entities/teacher_attendance_entity.dart';

abstract class TeacherAttendanceRepository {
  /// `POST /api/v1/teacher/attendance/students/`.
  Future<TeacherAttendanceRosterEntity> getStudents({
    required int classId,
    required int sectionId,
    required String date,
  });

  /// `POST /api/v1/teacher/attendance/store/`. Only the ids present in
  /// [ids] are written; every other map only needs an entry for the ids it
  /// actually applies to (matches web's own incremental per-field submits —
  /// see `TeacherAttendanceStoreView`, which keeps each existing field's
  /// value when a given student id is absent from that particular map).
  Future<void> storeAttendance({
    required int classId,
    required int sectionId,
    required String date,
    required List<int> ids,
    required Map<int, String> attendance,
    Map<int, String>? note,
    Map<int, bool>? lunch,
    Map<int, String>? arrivalTime,
    Map<int, String>? signInTime,
    Map<int, String>? signOutTime,
    bool lockAttendance = false,
  });
}
