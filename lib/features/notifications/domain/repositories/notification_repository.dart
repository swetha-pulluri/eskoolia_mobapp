import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markRead(int id);
  Future<void> markAllRead();
}
