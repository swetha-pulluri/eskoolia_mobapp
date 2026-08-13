import '../entities/broadcast_entity.dart';

abstract class BroadcastRepository {
  Future<BroadcastAudienceOptionsEntity> getAudienceOptions();

  Future<BroadcastSendResultEntity> sendBroadcast({
    required String message,
    required String template,
    required String audienceType,
    required List<int> classIds,
    required List<String> channels,
    DateTime? scheduledAt,
  });
}
