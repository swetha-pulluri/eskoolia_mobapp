/// School Tenant Entity
class SchoolEntity {
  final String tenantId;
  final String name;
  final String shortCode;
  final String subdomainUrl;
  final String shardRegion;
  final String storageRegion;
  final int backupRetention;
  final String ssoMethod;
  final bool apiAccess;
  final String plan;
  final String status;
  final String? provisionedAt;
  final String? createdAt;
  final String? updatedAt;
  final int students;
  final int activeStudents;
  final int seats;
  final int staff;
  final String? lastActivity;
  final String? board;
  final String? state;
  final String? region;
  final String? gstin;
  final String? udiseCode;
  final String? pan;
  final String? brandColor;
  final String? logoUrl;

  const SchoolEntity({
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
    required this.students,
    required this.activeStudents,
    required this.seats,
    required this.staff,
    this.lastActivity,
    this.board,
    this.state,
    this.region,
    this.gstin,
    this.udiseCode,
    this.pan,
    this.brandColor,
    this.logoUrl,
  });
}

/// Paginated Response
class PaginatedSchoolsEntity {
  final int count;
  final String? next;
  final String? previous;
  final List<SchoolEntity> results;

  const PaginatedSchoolsEntity({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
