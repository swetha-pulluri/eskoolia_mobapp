import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/notification_entity.dart';

/// Mirrors `frontend/components/nav/NotificationBell.tsx`'s calls to
/// `/api/v1/utilities/communication/notifications/`.
class NotificationRemoteDataSource {
  final DioClient _dioClient;

  NotificationRemoteDataSource(this._dioClient);

  Future<List<NotificationEntity>> getNotifications() async {
    final response = await _dioClient.get(
      ApiConstants.notifications,
      queryParameters: {'page_size': 10, 'ordering': '-created_at'},
    );
    final data = response.data;
    final results = data is Map<String, dynamic> ? data['results'] as List? : data as List?;
    return (results ?? const [])
        .map((e) => NotificationEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dioClient.get(
      ApiConstants.notifications,
      queryParameters: {'is_read': false, 'page_size': 1},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data['count'] as int? ?? 0;
    return 0;
  }

  Future<void> markRead(int id) async {
    await _dioClient.post(ApiConstants.notificationMarkRead(id));
  }

  Future<void> markAllRead() async {
    await _dioClient.post(ApiConstants.notificationsMarkAllRead);
  }
}
