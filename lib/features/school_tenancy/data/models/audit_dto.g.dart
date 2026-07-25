// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEventDto _$AuditEventDtoFromJson(Map<String, dynamic> json) =>
    AuditEventDto(
      id: json['id'] as String,
      timestamp: json['timestamp'] as String,
      actor: json['actor'] as String,
      actorIp: json['actor_ip'] as String?,
      action: json['action'] as String,
      detail: json['detail'] as String,
      severity: json['severity'] as String,
      tenantId: json['tenant_id'] as String?,
      schoolName: json['school_name'] as String?,
      affectedFields: (json['affected_fields'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      beforeValues: json['before_values'] as Map<String, dynamic>?,
      afterValues: json['after_values'] as Map<String, dynamic>?,
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
    );

Map<String, dynamic> _$AuditEventDtoToJson(AuditEventDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp,
      'actor': instance.actor,
      'actor_ip': instance.actorIp,
      'action': instance.action,
      'detail': instance.detail,
      'severity': instance.severity,
      'tenant_id': instance.tenantId,
      'school_name': instance.schoolName,
      'affected_fields': instance.affectedFields,
      'before_values': instance.beforeValues,
      'after_values': instance.afterValues,
      'status': instance.status,
      'error_message': instance.errorMessage,
    };

PaginatedAuditEventsDto _$PaginatedAuditEventsDtoFromJson(
  Map<String, dynamic> json,
) => PaginatedAuditEventsDto(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => AuditEventDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedAuditEventsDtoToJson(
  PaginatedAuditEventsDto instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
