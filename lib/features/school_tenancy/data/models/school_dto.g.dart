// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolDto _$SchoolDtoFromJson(Map<String, dynamic> json) => SchoolDto(
  tenantId: json['tenant_id'] as String,
  name: json['name'] as String,
  shortCode: json['short_code'] as String,
  subdomainUrl: json['subdomain_url'] as String,
  shardRegion: json['shard_region'] as String,
  storageRegion: json['storage_region'] as String,
  backupRetention: (json['backup_retention'] as num?)?.toInt(),
  ssoMethod: json['sso_method'] as String,
  apiAccess: json['api_access'] as bool,
  plan: json['plan'] as String,
  status: json['status'] as String,
  provisionedAt: json['provisioned_at'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  students: (json['students'] as num?)?.toInt(),
  activeStudents: (json['activeStudents'] as num?)?.toInt(),
  seats: (json['seats'] as num?)?.toInt(),
  staff: (json['staff'] as num?)?.toInt(),
  lastActivity: json['lastActivity'] as String?,
  board: json['board'] as String?,
  state: json['state'] as String?,
  region: json['region'] as String?,
  gstin: json['gstin'] as String?,
  udiseCode: json['udiseCode'] as String?,
  udiseCodeSnake: json['udise_code'] as String?,
  pan: json['pan'] as String?,
  brandColor: json['brand_color'] as String?,
  logoUrl: json['logo_url'] as String?,
);

Map<String, dynamic> _$SchoolDtoToJson(SchoolDto instance) => <String, dynamic>{
  'tenant_id': instance.tenantId,
  'name': instance.name,
  'short_code': instance.shortCode,
  'subdomain_url': instance.subdomainUrl,
  'shard_region': instance.shardRegion,
  'storage_region': instance.storageRegion,
  'backup_retention': instance.backupRetention,
  'sso_method': instance.ssoMethod,
  'api_access': instance.apiAccess,
  'plan': instance.plan,
  'status': instance.status,
  'provisioned_at': instance.provisionedAt,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'students': instance.students,
  'activeStudents': instance.activeStudents,
  'seats': instance.seats,
  'staff': instance.staff,
  'lastActivity': instance.lastActivity,
  'board': instance.board,
  'state': instance.state,
  'region': instance.region,
  'gstin': instance.gstin,
  'udiseCode': instance.udiseCode,
  'udise_code': instance.udiseCodeSnake,
  'pan': instance.pan,
  'brand_color': instance.brandColor,
  'logo_url': instance.logoUrl,
};

PaginatedSchoolsDto _$PaginatedSchoolsDtoFromJson(Map<String, dynamic> json) =>
    PaginatedSchoolsDto(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => SchoolDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedSchoolsDtoToJson(
  PaginatedSchoolsDto instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
