import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/school_entity.dart';

part 'school_dto.g.dart';

@JsonSerializable()
class SchoolDto {
  @JsonKey(name: 'tenant_id')
  final String tenantId;
  
  final String name;
  
  @JsonKey(name: 'short_code')
  final String shortCode;
  
  @JsonKey(name: 'subdomain_url')
  final String subdomainUrl;
  
  @JsonKey(name: 'shard_region')
  final String shardRegion;
  
  @JsonKey(name: 'storage_region')
  final String storageRegion;
  
  @JsonKey(name: 'backup_retention')
  final int backupRetention;
  
  @JsonKey(name: 'sso_method')
  final String ssoMethod;
  
  @JsonKey(name: 'api_access')
  final bool apiAccess;
  
  final String plan;
  final String status;
  
  @JsonKey(name: 'provisioned_at')
  final String? provisionedAt;
  
  @JsonKey(name: 'created_at')
  final String? createdAt;
  
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  
  final int? students;
  
  @JsonKey(name: 'activeStudents')
  final int? activeStudents;
  
  final int? seats;
  final int? staff;
  
  @JsonKey(name: 'lastActivity')
  final String? lastActivity;
  
  final String? board;
  final String? state;
  final String? region;
  final String? gstin;
  
  @JsonKey(name: 'udiseCode')
  final String? udiseCode;
  
  @JsonKey(name: 'udise_code')
  final String? udiseCodeSnake;
  
  final String? pan;
  
  @JsonKey(name: 'brand_color')
  final String? brandColor;
  
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  SchoolDto({
    required this.tenantId,
    required this.name,
    required this.shortCode,
    required this.subdomainUrl,
    required this.shardRegion,
    required this.storageRegion,
    required this.backupRetention,
    required this.ssoMethod,
    required this.apiAccess,
    required this.plan,
    required this.status,
    this.provisionedAt,
    this.createdAt,
    this.updatedAt,
    this.students,
    this.activeStudents,
    this.seats,
    this.staff,
    this.lastActivity,
    this.board,
    this.state,
    this.region,
    this.gstin,
    this.udiseCode,
    this.udiseCodeSnake,
    this.pan,
    this.brandColor,
    this.logoUrl,
  });

  factory SchoolDto.fromJson(Map<String, dynamic> json) => _$SchoolDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$SchoolDtoToJson(this);

  SchoolEntity toEntity() {
    return SchoolEntity(
      tenantId: tenantId,
      name: name,
      shortCode: shortCode,
      subdomainUrl: subdomainUrl,
      shardRegion: shardRegion,
      storageRegion: storageRegion,
      backupRetention: backupRetention,
      ssoMethod: ssoMethod,
      apiAccess: apiAccess,
      plan: plan,
      status: status,
      provisionedAt: provisionedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      students: students ?? 0,
      activeStudents: activeStudents ?? 0,
      seats: seats ?? 0,
      staff: staff ?? 0,
      lastActivity: lastActivity,
      board: board,
      state: state,
      region: region,
      gstin: gstin,
      udiseCode: udiseCode ?? udiseCodeSnake,
      pan: pan,
      brandColor: brandColor,
      logoUrl: logoUrl,
    );
  }
}

@JsonSerializable()
class PaginatedSchoolsDto {
  final int count;
  final String? next;
  final String? previous;
  final List<SchoolDto> results;

  PaginatedSchoolsDto({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedSchoolsDto.fromJson(Map<String, dynamic> json) => _$PaginatedSchoolsDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$PaginatedSchoolsDtoToJson(this);

  PaginatedSchoolsEntity toEntity() {
    return PaginatedSchoolsEntity(
      count: count,
      next: next,
      previous: previous,
      results: results.map((e) => e.toEntity()).toList(),
    );
  }
}
