import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/teacher_timetable_entity.dart';
import '../../domain/repositories/teacher_api_exception.dart';

/// Calls the real, implemented `apps.teacher_portal` timetable endpoint
/// exactly as the web app does.
class TeacherTimetableRemoteDataSource {
  final DioClient _dioClient;

  TeacherTimetableRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String) throw TeacherApiException(rawMessage);
      if (rawMessage != null) throw TeacherApiException(rawMessage.toString());
    }
    throw TeacherApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  Future<TeacherTimetableEntity> getTimetable() async {
    try {
      final response = await _dioClient.get(ApiConstants.teacherTimetable);
      return TeacherTimetableEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get teacher timetable error', e);
      _throwApiException(e);
    }
  }
}
