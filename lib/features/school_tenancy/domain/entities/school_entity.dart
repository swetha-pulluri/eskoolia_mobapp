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

/// Result of provisioning a new school (mirrors web's `ProvisionSchoolResponse`).
class ProvisionSchoolResultEntity {
  final String tenantId;
  final String status;
  final String? adminUsername;
  final String? adminPassword;

  const ProvisionSchoolResultEntity({
    required this.tenantId,
    required this.status,
    this.adminUsername,
    this.adminPassword,
  });
}

/// Impersonation handoff result (mirrors web's `ImpersonateResponse`).
class ImpersonateResultEntity {
  final String tenantId;
  final String username;
  final String handoffUrl;

  const ImpersonateResultEntity({
    required this.tenantId,
    required this.username,
    required this.handoffUrl,
  });
}

/// Paginated Response
class PaginatedSchoolsEntity {
  final int count;
  final String? next;
  final String? previous;
  final List<SchoolEntity> results;
  final SchoolStatusCountsEntity? statusCounts;
  final HealthFlagsCountsEntity? healthFlagsCounts;

  const PaginatedSchoolsEntity({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    this.statusCounts,
    this.healthFlagsCounts,
  });
}

/// Per-tab counts computed server-side over the whole (unpaginated) table —
/// mirrors backend's `SchoolTenantListView._status_counts()`.
class SchoolStatusCountsEntity {
  final int all;
  final int active;
  final int trial;
  final int suspended;
  final int archived;

  const SchoolStatusCountsEntity({
    this.all = 0,
    this.active = 0,
    this.trial = 0,
    this.suspended = 0,
    this.archived = 0,
  });
}

/// Result of resetting a school's admin password — mirrors web's
/// `ResetAdminPasswordResponse`. Shown once; never stored.
class ResetAdminPasswordResultEntity {
  final String adminUsername;
  final String adminPassword;
  final String message;

  const ResetAdminPasswordResultEntity({
    required this.adminUsername,
    required this.adminPassword,
    required this.message,
  });
}

/// LLM access registry entry for one school — mirrors backend's
/// `SchoolLLMListView` (`GET /api/super-admin/llm/schools/`).
class LLMSchoolStateEntity {
  final int id;
  final String name;
  final String code;
  final String tenantId;
  final bool llmEnabled;
  final String? llmEnabledAt;
  final bool isActive;

  const LLMSchoolStateEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.tenantId,
    required this.llmEnabled,
    this.llmEnabledAt,
    required this.isActive,
  });

  factory LLMSchoolStateEntity.fromJson(Map<String, dynamic> json) {
    return LLMSchoolStateEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      llmEnabled: json['llm_enabled'] as bool? ?? false,
      llmEnabledAt: json['llm_enabled_at'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Health-flag counts for the Smart Filters "Health flags" pill row —
/// mirrors backend's `SchoolTenantListView._health_flags_counts()`.
/// `storage80` is a real backend placeholder (always `0` — "no storage
/// field yet" per the backend's own comment), not a Flutter-side gap.
class HealthFlagsCountsEntity {
  final int billingOverdue;
  final int storage80;
  final int trialEnding;
  final int gstinMissing;

  const HealthFlagsCountsEntity({
    this.billingOverdue = 0,
    this.storage80 = 0,
    this.trialEnding = 0,
    this.gstinMissing = 0,
  });
}
