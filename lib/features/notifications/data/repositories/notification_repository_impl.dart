import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;

  NotificationRepositoryImpl(this._remote);

  @override
  Future<List<NotificationEntity>> getNotifications() => _remote.getNotifications();

  @override
  Future<int> getUnreadCount() => _remote.getUnreadCount();

  @override
  Future<void> markRead(int id) => _remote.markRead(id);

  @override
  Future<void> markAllRead() => _remote.markAllRead();
}
