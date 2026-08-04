import 'package:equatable/equatable.dart';

/// Notification Entity — mirrors the fields
/// `frontend/components/nav/NotificationBell.tsx` reads off each item
/// returned by `/api/v1/utilities/communication/notifications/`.
class NotificationEntity extends Equatable {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final String? linkUrl;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.linkUrl,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      linkUrl: json['link_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      linkUrl: linkUrl,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, body, isRead, linkUrl, createdAt];
}
