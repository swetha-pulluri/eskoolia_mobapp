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
  Future<ProvisionSchoolResultEntity> provisionSchool(Map<String, dynamic> data) async {
    final response = await _remoteDataSource.provisionSchool(data);
    return ProvisionSchoolResultEntity(
      tenantId: response['tenant_id'] as String,
      status: response['status'] as String? ?? 'onboarding',
      adminUsername: response['admin_username'] as String?,
      adminPassword: response['admin_password'] as String?,
    );
  }

  @override
  Future<SchoolEntity> updateSchoolFields(String tenantId, Map<String, dynamic> data) async {
    final dto = await _remoteDataSource.updateSchool(tenantId, data);
    return dto.toEntity();
  }

  @override
  Future<String?> uploadSchoolLogo(String tenantId, List<int> bytes, String filename) async {
    return _remoteDataSource.uploadSchoolLogo(tenantId, bytes, filename);
  }

  @override
  Future<SchoolEntity> updateSchoolStatus(String tenantId, String status) async {
    try {
      final dto = await _remoteDataSource.updateSchool(tenantId, {'status': status});
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> archiveSchool(String tenantId) async {
    try {
      await _remoteDataSource.archiveSchool(tenantId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ImpersonateResultEntity> impersonateSchool(String tenantId) async {
    try {
      final data = await _remoteDataSource.impersonateSchool(tenantId);
      return ImpersonateResultEntity(
        tenantId: data['tenant_id'] as String,
        username: data['username'] as String,
        handoffUrl: data['handoff_url'] as String,
      );
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
    try {
      final dto = await _remoteDataSource.getInvoices(
        page: page,
        pageSize: pageSize,
        status: status,
        schoolName: schoolName,
        tenantId: tenantId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BillingMrrEntity> getMrr() async {
    try {
      final dto = await _remoteDataSource.getMrr();
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<InvoiceEntity> createInvoice(Map<String, dynamic> data) async {
    final dto = await _remoteDataSource.createInvoice(data);
    return dto.toEntity();
  }

  @override
  Future<InvoiceEntity> markInvoicePaid(String invoiceId) async {
    try {
      final dto = await _remoteDataSource.markInvoicePaid(invoiceId);
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<RecordPaymentResultEntity> recordInvoicePayment(String invoiceId, Map<String, dynamic> payload) async {
    final dto = await _remoteDataSource.recordInvoicePayment(invoiceId, payload);
    return dto.toEntity();
  }

  @override
  Future<InvoiceEntity> updateInvoice(String invoiceId, Map<String, dynamic> data) async {
    final dto = await _remoteDataSource.updateInvoice(invoiceId, data);
    return dto.toEntity();
  }

  @override
  Future<InvoiceEntity> cancelInvoice(String invoiceId) async {
    final dto = await _remoteDataSource.cancelInvoice(invoiceId);
    return dto.toEntity();
  }

  @override
  Future<InvoiceReminderResultEntity> sendInvoiceReminder(String invoiceId) async {
    try {
      final dto = await _remoteDataSource.sendInvoiceReminder(invoiceId);
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> exportGstr1() async {
    try {
      return await _remoteDataSource.exportGstr1();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PlansCatalogEntity> getPlans() async {
    try {
      final dto = await _remoteDataSource.getPlans();
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SubscriptionPlanEntity> createPlan(Map<String, dynamic> data) async {
    final dto = await _remoteDataSource.createPlan(data);
    return dto.toEntity();
  }

  @override
  Future<SubscriptionPlanEntity> updatePlan(String code, Map<String, dynamic> data) async {
    final dto = await _remoteDataSource.updatePlan(code, data);
    return dto.toEntity();
  }

  @override
  Future<void> deletePlan(String code) async {
    await _remoteDataSource.deletePlan(code);
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
    try {
      final dto = await _remoteDataSource.getAuditEvents(
        page: page,
        pageSize: pageSize,
        actor: actor,
        action: action,
        tenantId: tenantId,
        severity: severity,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      return dto.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PolicyGroupEntity>> getPolicies() async {
    try {
      final dtos = await _remoteDataSource.getPolicies();
      return dtos.map((e) => e.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PolicyGroupEntity>> updatePolicies(Map<String, dynamic> updates) async {
    try {
      final dtos = await _remoteDataSource.updatePolicies(updates);
      return dtos.map((e) => e.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getPolicySettings() async {
    try {
      return await _remoteDataSource.getPolicySettings();
    } catch (e) {
      rethrow;
    }
  }
}
