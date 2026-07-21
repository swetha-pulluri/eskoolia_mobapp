import '../entities/dashboard_entity.dart';
import '../entities/school_entity.dart';
import '../entities/invoice_entity.dart';
import '../entities/audit_entity.dart';
import '../entities/policy_entity.dart';

/// School Tenancy Repository
abstract class SchoolTenancyRepository {
  // Dashboard
  Future<DashboardEntity> getDashboard();

  // Schools
  Future<PaginatedSchoolsEntity> getSchools({
    int? page,
    int? pageSize,
    String? search,
    String? status,
    String? board,
    String? plan,
    String? region,
    String? state,
  });

  Future<SchoolEntity> getSchool(String tenantId);

  // Billing
  Future<PaginatedInvoicesEntity> getInvoices({
    int? page,
    int? pageSize,
    String? status,
    String? schoolName,
    String? tenantId,
    String? dateFrom,
    String? dateTo,
  });

  Future<BillingMrrEntity> getMrr();

  // Audit
  Future<PaginatedAuditEventsEntity> getAuditEvents({
    int? page,
    int? pageSize,
    String? actor,
    String? action,
    String? tenantId,
    String? severity,
    String? dateFrom,
    String? dateTo,
  });

  // Policies
  Future<List<PolicyGroupEntity>> getPolicies();
}
