/// Mirrors `ParentNoticesView`'s real response (`GET /api/v1/parent/notices/`).
/// See web's `lib/api/parent.ts`'s `NoticeItem`.
class NoticeItemEntity {
  final int id;
  final String title;
  final String message;
  final String noticeDate;
  final String publishOn;

  const NoticeItemEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.noticeDate,
    required this.publishOn,
  });

  factory NoticeItemEntity.fromJson(Map<String, dynamic> json) => NoticeItemEntity(
        id: json['id'] as int,
        title: (json['title'] as String?) ?? '',
        message: (json['message'] as String?) ?? '',
        noticeDate: (json['notice_date'] as String?) ?? '',
        publishOn: (json['publish_on'] as String?) ?? '',
      );
}
