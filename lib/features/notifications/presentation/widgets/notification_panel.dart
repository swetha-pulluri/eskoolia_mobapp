import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';

const _navBg = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk3 = Color(0xFF9197AE);
const _unreadTint = Color(0xFFF3F0FF);
const _navPurple = Color(0xFF6D4AFF);

/// Flutter port of `frontend/components/nav/NotificationBell.tsx`'s dropdown
/// — header + "Mark all read", list of items (unread highlighted, tap marks
/// read and navigates to `link_url` if present).
Future<void> showNotificationPanel(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: _navBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (context) => const _NotificationPanelContent(),
  );
}

class _NotificationPanelContent extends ConsumerWidget {
  const _NotificationPanelContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navInk1)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(notificationRepositoryProvider).markAllRead();
                      ref.invalidate(notificationsProvider);
                      await ref.read(unreadNotificationCountProvider.notifier).refresh();
                    },
                    child: const Text('Mark all read', style: TextStyle(fontSize: 12.5, color: _navPurple, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _navBorder),
            Flexible(
              child: notificationsAsync.when(
                data: (items) => items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('No notifications yet.', style: TextStyle(color: _navInk3, fontSize: 13))),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: _navBorder),
                        itemBuilder: (context, i) => _NotificationRow(item: items[i]),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Center(child: Text('Could not load notifications.', style: TextStyle(color: _navInk3, fontSize: 13))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  final NotificationEntity item;

  const _NotificationRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        if (!item.isRead) {
          await ref.read(notificationRepositoryProvider).markRead(item.id);
          ref.invalidate(notificationsProvider);
          await ref.read(unreadNotificationCountProvider.notifier).refresh();
        }
        final linkUrl = item.linkUrl;
        if (context.mounted) Navigator.of(context).pop();
        if (linkUrl != null && linkUrl.isNotEmpty) {
          ref.read(appRouterProvider).go(linkUrl);
        }
      },
      child: Container(
        color: item.isRead ? Colors.transparent : _unreadTint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navInk1)),
            const SizedBox(height: 2),
            Text(
              item.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF5A607A)),
            ),
            const SizedBox(height: 4),
            Text(
              app_date_utils.DateUtils.getRelativeTime(item.createdAt),
              style: const TextStyle(fontSize: 10.5, color: _navInk3),
            ),
          ],
        ),
      ),
    );
  }
}
