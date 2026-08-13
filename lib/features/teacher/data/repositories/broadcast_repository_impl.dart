import '../../domain/entities/broadcast_entity.dart';
import '../../domain/repositories/broadcast_repository.dart';
import '../datasources/broadcast_remote_datasource.dart';

class BroadcastRepositoryImpl implements BroadcastRepository {
  final BroadcastRemoteDataSource _dataSource;

  BroadcastRepositoryImpl(this._dataSource);

  @override
  Future<BroadcastAudienceOptionsEntity> getAudienceOptions() => _dataSource.getAudienceOptions();

  @override
  Future<BroadcastSendResultEntity> sendBroadcast({
    required String message,
    required String template,
    required String audienceType,
    required List<int> classIds,
    required List<String> channels,
    DateTime? scheduledAt,
  }) =>
      _dataSource.sendBroadcast(
        message: message,
        template: template,
        audienceType: audienceType,
        classIds: classIds,
        channels: channels,
        scheduledAt: scheduledAt,
      );
}
