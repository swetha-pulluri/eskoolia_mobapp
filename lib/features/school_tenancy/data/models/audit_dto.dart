import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/audit_entity.dart';

part 'audit_dto.g.dart';

@JsonSerializable()
class AuditEventDto {
  final String id;
  final String timestamp;
  final String actor;

  @JsonKey(name: 'actor_ip')
  final String? actorIp;

  final String action;
  final String detail;
  final String severity;

  @JsonKey(name: 'tenant_id')
  final String? tenantId;

  @JsonKey(name: 'school_name')
  final String? schoolName;

  @JsonKey(name: 'affected_fields')
  final List<String>? affectedFields;

  @JsonKey(name: 'before_values')
  final Map<String, dynamic>? beforeValues;

  @JsonKey(name: 'after_values')
  final Map<String, dynamic>? afterValues;

  final String status;

  @JsonKey(name: 'error_message')
  final String? errorMessage;

  AuditEventDto({
    required this.id,
    required this.timestamp,
    required this.actor,
    this.actorIp,
    required this.action,
    required this.detail,
    required this.severity,
    this.tenantId,
    this.schoolName,
    this.affectedFields,
    this.beforeValues,
    this.afterValues,
    required this.status,
    this.errorMessage,
  });

  factory AuditEventDto.fromJson(Map<String, dynamic> json) => _$AuditEventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuditEventDtoToJson(this);

  AuditEventEntity toEntity() {
    return AuditEventEntity(
      id: id,
      timestamp: timestamp,
      actor: actor,
      actorIp: actorIp ?? '',
      action: action,
      detail: detail,
      severity: severity,
      tenantId: tenantId,
      schoolName: schoolName,
      affectedFields: affectedFields,
      beforeValues: beforeValues,
      afterValues: afterValues,
      status: status,
      errorMessage: errorMessage,
    );
  }
}

@JsonSerializable()
class PaginatedAuditEventsDto {
  final int count;
  final String? next;
  final String? previous;
  final List<AuditEventDto> results;

  PaginatedAuditEventsDto({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedAuditEventsDto.fromJson(Map<String, dynamic> json) => _$PaginatedAuditEventsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedAuditEventsDtoToJson(this);

  PaginatedAuditEventsEntity toEntity() {
    return PaginatedAuditEventsEntity(
      count: count,
      next: next,
      previous: previous,
      results: results.map((e) => e.toEntity()).toList(),
    );
  }
}
