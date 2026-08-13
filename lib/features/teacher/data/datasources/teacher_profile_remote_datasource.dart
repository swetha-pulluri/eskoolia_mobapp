import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/teacher_profile_entity.dart';
import '../../domain/repositories/teacher_api_exception.dart';

/// Calls the real `apps.hr` `StaffViewSet.me()` action (`GET
/// /api/v1/hr/staff/me/`) — the same self-scoped endpoint web's Settings >
/// Staff Profile panel (`StaffProfilePanel.tsx`) calls for any non-admin
/// user. Self-scoped server-side (always the logged-in user's own record),
/// so no separate teacher/staff-id lookup is needed.
class TeacherProfileRemoteDataSource {
  final DioClient _dioClient;

  TeacherProfileRemoteDataSource(this._dioClient);

  Future<TeacherProfileEntity> getMyProfile() async {
    try {
      final response = await _dioClient.get(ApiConstants.hrStaffMe);
      return TeacherProfileEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get teacher profile error', e);
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
        if (rawMessage != null) throw TeacherApiException(rawMessage.toString());
      }
      throw TeacherApiException(e.message ?? 'Something went wrong. Please try again.');
    }
  }
}
