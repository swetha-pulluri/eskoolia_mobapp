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
  final int? backupRetention;
  
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

  @JsonKey(name: 'school_type')
  final String? schoolType;

  @JsonKey(name: 'medium_of_instruction')
  final String? mediumOfInstruction;

  @JsonKey(name: 'year_established')
  final int? yearEstablished;

  final String? motto;

  @JsonKey(name: 'affiliation_number')
  final String? affiliationNumber;

  @JsonKey(name: 'principal_name')
  final String? principalName;

  @JsonKey(name: 'principal_email')
  final String? principalEmail;

  @JsonKey(name: 'principal_phone')
  final String? principalPhone;

  @JsonKey(name: 'school_phone')
  final String? schoolPhone;

  @JsonKey(name: 'school_email')
  final String? schoolEmail;

  final String? website;

  @JsonKey(name: 'campus_address')
  final String? campusAddress;

  final String? city;

  @JsonKey(name: 'pin_code')
  final String? pinCode;

  final String? country;

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
    this.schoolType,
    this.mediumOfInstruction,
    this.yearEstablished,
    this.motto,
    this.affiliationNumber,
    this.principalName,
    this.principalEmail,
    this.principalPhone,
    this.schoolPhone,
    this.schoolEmail,
    this.website,
    this.campusAddress,
    this.city,
    this.pinCode,
    this.country,
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
      backupRetention: backupRetention ?? 0,
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
      schoolType: schoolType,
      mediumOfInstruction: mediumOfInstruction,
      yearEstablished: yearEstablished,
      motto: motto,
      affiliationNumber: affiliationNumber,
      principalName: principalName,
      principalEmail: principalEmail,
      principalPhone: principalPhone,
      schoolPhone: schoolPhone,
      schoolEmail: schoolEmail,
      website: website,
      campusAddress: campusAddress,
      city: city,
      pinCode: pinCode,
      country: country,
    );
  }
}

/// Manually parsed (not `@JsonSerializable`) so it can also carry the
/// `status_counts`/`health_flags_counts` objects the backend appends onto
/// the paginated envelope (`SchoolTenantListView.get()`).
class PaginatedSchoolsDto {
  final int count;
  final String? next;
  final String? previous;
  final List<SchoolDto> results;
  final SchoolStatusCountsEntity? statusCounts;
  final HealthFlagsCountsEntity? healthFlagsCounts;

  PaginatedSchoolsDto({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    this.statusCounts,
    this.healthFlagsCounts,
  });

  factory PaginatedSchoolsDto.fromJson(Map<String, dynamic> json) {
    final statusCountsJson = json['status_counts'] as Map<String, dynamic>?;
    final healthFlagsJson = json['health_flags_counts'] as Map<String, dynamic>?;
    return PaginatedSchoolsDto(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>? ?? const [])
          .map((e) => SchoolDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusCounts: statusCountsJson == null
          ? null
          : SchoolStatusCountsEntity(
              all: statusCountsJson['all'] as int? ?? 0,
              active: statusCountsJson['active'] as int? ?? 0,
              trial: statusCountsJson['trial'] as int? ?? 0,
              suspended: statusCountsJson['suspended'] as int? ?? 0,
              archived: statusCountsJson['archived'] as int? ?? 0,
            ),
      healthFlagsCounts: healthFlagsJson == null
          ? null
          : HealthFlagsCountsEntity(
              billingOverdue: healthFlagsJson['billing_overdue'] as int? ?? 0,
              storage80: healthFlagsJson['storage_80'] as int? ?? 0,
              trialEnding: healthFlagsJson['trial_ending'] as int? ?? 0,
              gstinMissing: healthFlagsJson['gstin_missing'] as int? ?? 0,
            ),
    );
  }

  PaginatedSchoolsEntity toEntity() {
    return PaginatedSchoolsEntity(
      count: count,
      next: next,
      previous: previous,
      results: results.map((e) => e.toEntity()).toList(),
      statusCounts: statusCounts,
      healthFlagsCounts: healthFlagsCounts,
    );
  }
}
