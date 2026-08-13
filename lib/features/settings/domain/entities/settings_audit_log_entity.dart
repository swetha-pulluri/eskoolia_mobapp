/// One row of the Settings module's audit trail — a 1:1 port of
/// `SettingsAuditLogSerializer`'s output fields (backend/apps/settings/
/// serializers.py:170-180). Deliberately separate from the narrower
/// `LeaveAuditEntry`/`SmtpAuditEntry` "view history" entries used inline by
/// other Settings sub-panels — this one powers the standalone, filterable,
/// paginated Audit Log screen (frontend/components/settings/
/// AuditLogPanel.tsx), which surfaces `object_type`/`object_id`/`ip_address`
/// that those narrower views don't need.
class SettingsAuditLogEntity {
  final int id;
  final String actorName;
  final String action;
  final String objectType;
  final String objectId;
  final String? ipAddress;
  final String createdAt;

  const SettingsAuditLogEntity({
    required this.id,
    required this.actorName,
    required this.action,
    required this.objectType,
    required this.objectId,
    required this.ipAddress,
    required this.createdAt,
  });

  factory SettingsAuditLogEntity.fromJson(Map<String, dynamic> json) {
    return SettingsAuditLogEntity(
      id: json['id'] as int,
      actorName: json['actor_name'] as String? ?? 'System',
      action: json['action'] as String? ?? '',
      objectType: json['object_type'] as String? ?? '',
      objectId: json['object_id'] as String? ?? '',
      ipAddress: json['ip_address'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
