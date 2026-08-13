import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/teacher_me_entity.dart';
import '../../domain/repositories/teacher_api_exception.dart';

/// Calls the real, implemented `apps.teacher_portal` endpoints.
class TeacherRemoteDataSource {
  final DioClient _dioClient;

  TeacherRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String) throw TeacherApiException(rawMessage);
      if (rawMessage != null) throw TeacherApiException(rawMessage.toString());
    }
    throw TeacherApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  Future<TeacherMeEntity> getMe() async {
    try {
      final response = await _dioClient.get(ApiConstants.teacherMe);
      return TeacherMeEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get teacher me error', e);
      _throwApiException(e);
    }
  }
}
