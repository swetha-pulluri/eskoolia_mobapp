/// `GET .../broadcast/audience-options/` response — for a teacher this is
/// always `isTeacher: true`, `audienceTypes: ['class_parents']`, `classes`
/// = only the classes where they're the active class teacher (server-side
/// enforced, see `apps/communication/broadcast.py::teacher_assigned_class_ids`).
class BroadcastAudienceOptionsEntity {
  final bool isTeacher;
  final List<String> audienceTypes;
  final List<BroadcastClassEntity> classes;

  const BroadcastAudienceOptionsEntity({
    required this.isTeacher,
    required this.audienceTypes,
    required this.classes,
  });

  factory BroadcastAudienceOptionsEntity.fromJson(Map<String, dynamic> json) => BroadcastAudienceOptionsEntity(
        isTeacher: json['is_teacher'] as bool? ?? false,
        audienceTypes: ((json['audience_types'] as List?) ?? const []).map((e) => e.toString()).toList(),
        classes: ((json['classes'] as List?) ?? const [])
            .map((e) => BroadcastClassEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BroadcastClassEntity {
  final int id;
  final String name;

  const BroadcastClassEntity({required this.id, required this.name});

  factory BroadcastClassEntity.fromJson(Map<String, dynamic> json) => BroadcastClassEntity(
        id: json['id'] as int,
        name: (json['name'] as String?) ?? '',
      );
}

/// `POST .../broadcast/` success response — `status` is `'sent'` or
/// `'scheduled'`; `message` is the server's own human-readable confirmation
/// string (shown verbatim, not composed client-side, matching web).
class BroadcastSendResultEntity {
  final int id;
  final String status;
  final int recipientCount;
  final String message;
  final DateTime? scheduledAt;

  const BroadcastSendResultEntity({
    required this.id,
    required this.status,
    required this.recipientCount,
    required this.message,
    this.scheduledAt,
  });

  factory BroadcastSendResultEntity.fromJson(Map<String, dynamic> json) => BroadcastSendResultEntity(
        id: json['id'] as int,
        status: (json['status'] as String?) ?? 'sent',
        recipientCount: json['recipient_count'] as int? ?? 0,
        message: (json['message'] as String?) ?? '',
        scheduledAt: json['scheduled_at'] != null ? DateTime.tryParse(json['scheduled_at'] as String) : null,
      );
}
