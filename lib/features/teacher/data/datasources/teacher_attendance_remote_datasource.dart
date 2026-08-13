import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/teacher_attendance_entity.dart';
import '../../domain/repositories/teacher_api_exception.dart';

/// Calls the real `apps.teacher_portal` attendance endpoints
/// (`TeacherAttendanceFetchView`/`TeacherAttendanceStoreView`) exactly as the
/// web app's `app/(teacher-portal)/teacher/attendance/page.tsx` does — these
/// are distinct, teacher-scoped endpoints, not the admin
/// `/api/v1/attendance/student-attendance/...` endpoints.
class TeacherAttendanceRemoteDataSource {
  final DioClient _dioClient;

  TeacherAttendanceRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String) throw TeacherApiException(rawMessage);
      if (rawMessage != null) throw TeacherApiException(rawMessage.toString());
    }
    throw TeacherApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  Future<TeacherAttendanceRosterEntity> getStudents({
    required int classId,
    required int sectionId,
    required String date,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.teacherAttendanceStudents,
        data: {'class_id': classId, 'section_id': sectionId, 'date': date},
      );
      return TeacherAttendanceRosterEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get teacher attendance students error', e);
      _throwApiException(e);
    }
  }

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
  }) async {
    String k(int id) => id.toString();
    final body = <String, dynamic>{
      'class_id': classId,
      'section_id': sectionId,
      'date': date,
      'id': ids,
      'attendance': {for (final e in attendance.entries) k(e.key): e.value},
      if (note != null) 'note': {for (final e in note.entries) k(e.key): e.value},
      if (lunch != null) 'lunch': {for (final e in lunch.entries) k(e.key): e.value},
      if (arrivalTime != null) 'arrival_time': {for (final e in arrivalTime.entries) k(e.key): e.value},
      if (signInTime != null) 'sign_in_time': {for (final e in signInTime.entries) k(e.key): e.value},
      if (signOutTime != null) 'sign_out_time': {for (final e in signOutTime.entries) k(e.key): e.value},
      'lock_attendance': lockAttendance,
    };
    try {
      await _dioClient.post(ApiConstants.teacherAttendanceStore, data: body);
    } on DioException catch (e) {
      AppLogger.error('Store teacher attendance error', e);
      _throwApiException(e);
    }
  }
}
