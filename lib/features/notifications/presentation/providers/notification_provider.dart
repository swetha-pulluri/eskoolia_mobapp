import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRemoteDataSourceProvider = Provider((ref) {
  return NotificationRemoteDataSource(ref.watch(dioClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationRemoteDataSourceProvider));
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationEntity>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

/// Polls the unread count every 60s, matching
/// `NotificationBell.tsx`'s `fetchUnreadCount` interval — kept alive for the
/// lifetime of the app (not `autoDispose`) since the bell badge in
/// `GlobalAppShell` is always mounted while authenticated.
final unreadNotificationCountProvider =
    StateNotifierProvider<UnreadNotificationCountNotifier, int>((ref) {
  return UnreadNotificationCountNotifier(ref.watch(notificationRepositoryProvider));
});

class UnreadNotificationCountNotifier extends StateNotifier<int> {
  final NotificationRepository _repository;
  Timer? _timer;

  UnreadNotificationCountNotifier(this._repository) : super(0) {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      state = await _repository.getUnreadCount();
    } catch (_) {
      // Leave the last-known count on a transient failure — matches the
      // web bell, which silently keeps showing the previous badge value.
    }
  }

  Future<void> refresh() => _refresh();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
