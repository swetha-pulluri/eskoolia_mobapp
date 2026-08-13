import '../../domain/entities/teacher_attendance_entity.dart';
import '../../domain/repositories/teacher_attendance_repository.dart';
import '../datasources/teacher_attendance_remote_datasource.dart';

class TeacherAttendanceRepositoryImpl implements TeacherAttendanceRepository {
  final TeacherAttendanceRemoteDataSource _remoteDataSource;

  TeacherAttendanceRepositoryImpl(this._remoteDataSource);

  @override
  Future<TeacherAttendanceRosterEntity> getStudents({
    required int classId,
    required int sectionId,
    required String date,
  }) {
    return _remoteDataSource.getStudents(classId: classId, sectionId: sectionId, date: date);
  }

  @override
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
  }) {
    return _remoteDataSource.storeAttendance(
      classId: classId,
      sectionId: sectionId,
      date: date,
      ids: ids,
      attendance: attendance,
      note: note,
      lunch: lunch,
      arrivalTime: arrivalTime,
      signInTime: signInTime,
      signOutTime: signOutTime,
      lockAttendance: lockAttendance,
    );
  }
}
