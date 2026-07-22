/// Audit Event Entity
class AuditEventEntity {
  final String id;
  final String timestamp;
  final String actor;
  final String actorIp;
  final String action;
  final String detail;
  final String severity;
  final String? tenantId;
  final String? schoolName;
  final List<String>? affectedFields;
  final Map<String, dynamic>? beforeValues;
  final Map<String, dynamic>? afterValues;

  const AuditEventEntity({
    required this.id,
    required this.timestamp,
    required this.actor,
    required this.actorIp,
    required this.action,
    required this.detail,
    required this.severity,
    this.tenantId,
    this.schoolName,
    this.affectedFields,
    this.beforeValues,
    this.afterValues,
  });
}

/// Audit State Entity for UI
class AuditStateEntity {
  final List<AuditEventEntity> events;

  const AuditStateEntity({
    required this.events,
  });
}

/// Paginated Audit Events
class PaginatedAuditEventsEntity {
  final int count;
  final String? next;
  final String? previous;
  final List<AuditEventEntity> results;

  const PaginatedAuditEventsEntity({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
