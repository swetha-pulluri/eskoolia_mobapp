import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/school_entity.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/audit_entity.dart';
import '../../domain/entities/policy_entity.dart';
import '../../domain/repositories/school_tenancy_repository.dart';
import '../datasources/school_tenancy_remote_datasource.dart';

/// School Tenancy Repository Implementation
class SchoolTenancyRepositoryImpl implements SchoolTenancyRepository {
  final SchoolTenancyRemoteDataSource _remoteDataSource;

  SchoolTenancyRepositoryImpl(this._remoteDataSource);

  @override
  Future<DashboardEntity> getDashboard() async {
    try {
      final dto = await _remoteDataSource.getDashboard();
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaginatedSchoolsEntity> getSchools({
    int? page,
    int? pageSize,
    String? search,
    String? status,
    String? board,
    String? plan,
    String? region,
    String? state,
  }) async {
    try {
      final dto = await _remoteDataSource.getSchools(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        board: board,
        plan: plan,
        region: region,
        state: state,
      );
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SchoolEntity> getSchool(String tenantId) async {
    try {
      final dto = await _remoteDataSource.getSchool(tenantId);
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaginatedInvoicesEntity> getInvoices({
    int? page,
    int? pageSize,
    String? status,
    String? schoolName,
    String? tenantId,
    String? dateFrom,
    String? dateTo,
  }) async {
    // TODO: Implement billing when needed
    throw UnimplementedError('Billing not yet implemented');
  }

  @override
  Future<BillingMrrEntity> getMrr() async {
    // TODO: Implement billing when needed
    throw UnimplementedError('Billing not yet implemented');
  }

  @override
  Future<PaginatedAuditEventsEntity> getAuditEvents({
    int? page,
    int? pageSize,
    String? actor,
    String? action,
    String? tenantId,
    String? severity,
    String? dateFrom,
    String? dateTo,
  }) async {
    // TODO: Implement audit when needed
    throw UnimplementedError('Audit not yet implemented');
  }

  @override
  Future<List<PolicyGroupEntity>> getPolicies() async {
    // TODO: Implement policies when needed
    throw UnimplementedError('Policies not yet implemented');
  }
}
