import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/broadcast_entity.dart';
import '../../domain/repositories/teacher_api_exception.dart';

/// Calls the real, implemented `apps.communication` broadcast endpoints.
/// The backend itself re-derives/clamps a teacher's audience server-side
/// (forces `audience_type=class_parents`, restricts `class_ids` to their
/// own assigned classes) — this datasource just sends what the compose UI
/// collected; enforcement is the backend's job, not the client's.
class BroadcastRemoteDataSource {
  final DioClient _dioClient;

  BroadcastRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String) throw TeacherApiException(rawMessage);
      if (rawMessage != null) throw TeacherApiException(rawMessage.toString());
    }
    throw TeacherApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  Future<BroadcastAudienceOptionsEntity> getAudienceOptions() async {
    try {
      final response = await _dioClient.get(ApiConstants.broadcastAudienceOptions);
      return BroadcastAudienceOptionsEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get broadcast audience options error', e);
      _throwApiException(e);
    }
  }

  Future<BroadcastSendResultEntity> sendBroadcast({
    required String message,
    required String template,
    required String audienceType,
    required List<int> classIds,
    required List<String> channels,
    DateTime? scheduledAt,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.broadcastSend,
        data: {
          'message': message,
          'template': template,
          'audience_type': audienceType,
          'class_ids': classIds,
          'channels': channels,
          'scheduled_at': ?scheduledAt?.toIso8601String(),
        },
      );
      return BroadcastSendResultEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }
}
