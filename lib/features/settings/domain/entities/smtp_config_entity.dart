/// Settings → SMTP Settings: one `SchoolSMTPSettings` record. Reference:
/// backend/apps/settings/{models,serializers}.py::SchoolSMTPSettings(Serializer),
/// frontend/components/settings/SmtpSettingsPanel.tsx (`interface SmtpConfig`).
///
/// The raw `password` is never present in a response — the serializer marks
/// it `write_only=True`; only a masked [passwordDisplay] ("••••••••" or "")
/// comes back, matching the web's `SmtpConfig.password_display`.
class SmtpConfigEntity {
  final int id;
  final String name;
  final String smtpType; // "server" | "local"
  final String host;
  final int port;
  final String username;
  final String passwordDisplay;
  final bool useTls;
  final String fromEmail;
  final String bccEmail;
  final String senderName;
  final String priority; // "normal" | "high" | "low"
  final String receiverEmailType; // "email_id" | "personal_email_id"
  final bool isActive;

  const SmtpConfigEntity({
    required this.id,
    required this.name,
    required this.smtpType,
    required this.host,
    required this.port,
    required this.username,
    required this.passwordDisplay,
    required this.useTls,
    required this.fromEmail,
    required this.bccEmail,
    required this.senderName,
    required this.priority,
    required this.receiverEmailType,
    required this.isActive,
  });

  factory SmtpConfigEntity.fromJson(Map<String, dynamic> json) {
    return SmtpConfigEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      smtpType: json['smtp_type'] as String? ?? 'server',
      host: json['host'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 587,
      username: json['username'] as String? ?? '',
      passwordDisplay: json['password_display'] as String? ?? '',
      useTls: json['use_tls'] as bool? ?? true,
      fromEmail: json['from_email'] as String? ?? '',
      bccEmail: json['bcc_email'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      receiverEmailType: json['receiver_email_type'] as String? ?? 'email_id',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  /// Seeds the wizard's editable `draft` on edit — mirrors the web's
  /// `{ ...WIZARD_DEFAULTS, ...config, password: "" }`. `password` always
  /// starts blank (the real value is never available to seed it with).
  Map<String, dynamic> toDraftMap() {
    return {
      'name': name,
      'smtp_type': smtpType,
      'host': host,
      'port': port,
      'username': username,
      'password': '',
      'use_tls': useTls,
      'from_email': fromEmail,
      'bcc_email': bccEmail,
      'sender_name': senderName,
      'priority': priority,
      'receiver_email_type': receiverEmailType,
    };
  }
}

/// One `SettingsAuditLog` row for an SMTP config — mirrors the web's
/// `interface AuditEntry`. Kept self-contained (not shared with Leave
/// Policy's equivalent) per this Settings module's per-feature convention.
class SmtpAuditEntry {
  final int id;
  final String actorName;
  final String action;
  final DateTime? createdAt;

  const SmtpAuditEntry({
    required this.id,
    required this.actorName,
    required this.action,
    required this.createdAt,
  });

  factory SmtpAuditEntry.fromJson(Map<String, dynamic> json) {
    return SmtpAuditEntry(
      id: json['id'] as int,
      actorName: json['actor_name'] as String? ?? '—',
      action: json['action'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
