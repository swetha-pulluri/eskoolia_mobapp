import 'package:dio/dio.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/dashboard_dto.dart';
import '../models/school_dto.dart';
import '../models/invoice_dto.dart';
import '../models/audit_dto.dart';
import '../models/policy_dto.dart';

/// School Tenancy Remote Data Source
class SchoolTenancyRemoteDataSource {
  final DioClient _dioClient;

  SchoolTenancyRemoteDataSource(this._dioClient);

  /// Get Dashboard Data
  Future<DashboardDto> getDashboard() async {
    try {
      final response = await _dioClient.get('/api/super-admin/dashboard/');
      return DashboardDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get dashboard error', e);
      rethrow;
    }
  }

  /// Get Schools with pagination and filters
  Future<PaginatedSchoolsDto> getSchools({
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
      final queryParams = <String, dynamic>{};
      
      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (board != null && board.isNotEmpty) queryParams['board'] = board;
      if (plan != null && plan.isNotEmpty) queryParams['plan'] = plan;
      if (region != null && region.isNotEmpty) queryParams['region'] = region;
      if (state != null && state.isNotEmpty) queryParams['state'] = state;

      final response = await _dioClient.get(
        '/api/super-admin/schools/',
        queryParameters: queryParams,
      );
      
      return PaginatedSchoolsDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get schools error', e);
      rethrow;
    }
  }

  /// Get single school by tenant ID
  Future<SchoolDto> getSchool(String tenantId) async {
    try {
      final response = await _dioClient.get('/api/super-admin/schools/$tenantId/');
      return SchoolDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get school error', e);
      rethrow;
    }
  }

  /// Provision a new school tenant — mirrors web's `provisionSchool()`
  /// (`POST /api/super-admin/schools/provision/`).
  Future<Map<String, dynamic>> provisionSchool(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post('/api/super-admin/schools/provision/', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Provision school error', e);
      rethrow;
    }
  }

  /// Upload a school's logo — mirrors web's `uploadSchoolLogo()`
  /// (`POST /api/super-admin/schools/{tenantId}/logo/`, multipart).
  Future<String?> uploadSchoolLogo(String tenantId, List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'logo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dioClient.post('/api/super-admin/schools/$tenantId/logo/', data: formData);
      final data = response.data as Map<String, dynamic>;
      return data['logo_url'] as String?;
    } catch (e) {
      AppLogger.error('Upload school logo error', e);
      rethrow;
    }
  }

  /// Update a school tenant (e.g. `{'status': 'suspended'}` /
  /// `{'status': 'active'}` — mirrors web's `updateSchool()`).
  Future<SchoolDto> updateSchool(String tenantId, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.patch('/api/super-admin/schools/$tenantId/', data: data);
      return SchoolDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Update school error', e);
      rethrow;
    }
  }

  /// Archive a school tenant (soft-delete on the backend — mirrors web's
  /// `deleteSchool()`, which calls `DELETE /schools/{tenantId}/`).
  Future<void> archiveSchool(String tenantId) async {
    try {
      await _dioClient.delete('/api/super-admin/schools/$tenantId/');
    } catch (e) {
      AppLogger.error('Archive school error', e);
      rethrow;
    }
  }

  /// Mint a short-lived impersonation token + handoff URL for a tenant.
  Future<Map<String, dynamic>> impersonateSchool(String tenantId) async {
    try {
      final response = await _dioClient.post('/api/super-admin/schools/$tenantId/impersonate/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Impersonate school error', e);
      rethrow;
    }
  }

  /// Get invoices with pagination and filters
  Future<PaginatedInvoicesDto> getInvoices({
    int? page,
    int? pageSize,
    String? status,
    String? schoolName,
    String? tenantId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (schoolName != null && schoolName.isNotEmpty) queryParams['school_name'] = schoolName;
      if (tenantId != null && tenantId.isNotEmpty) queryParams['tenant_id'] = tenantId;
      if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;

      final response = await _dioClient.get(
        '/api/super-admin/billing/invoices/',
        queryParameters: queryParams,
      );

      return PaginatedInvoicesDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get invoices error', e);
      rethrow;
    }
  }

  /// Get MRR and billing metrics
  Future<BillingMrrDto> getMrr() async {
    try {
      final response = await _dioClient.get('/api/super-admin/billing/mrr/');
      return BillingMrrDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get MRR error', e);
      rethrow;
    }
  }

  /// Create an invoice — mirrors web's `createInvoice()` (`POST
  /// /billing/invoices/`). Callers must catch a 409 DioException themselves
  /// to detect the backend's duplicate-invoice guard (response data
  /// `{code: 'duplicate_invoice', ...}`) and retry with `force: true`.
  Future<InvoiceDto> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post('/api/super-admin/billing/invoices/', data: data);
      return InvoiceDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Create invoice error', e);
      rethrow;
    }
  }

  /// Mark an invoice as paid — mirrors web's `markInvoicePaid()`.
  Future<InvoiceDto> markInvoicePaid(String invoiceId) async {
    try {
      final response = await _dioClient.post('/api/super-admin/billing/invoices/$invoiceId/mark-paid/');
      return InvoiceDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Mark invoice paid error', e);
      rethrow;
    }
  }

  /// Record a payment (full or partial) — mirrors web's `recordInvoicePayment()`
  /// (`POST /billing/invoices/{id}/payments/`).
  Future<RecordPaymentResultDto> recordInvoicePayment(String invoiceId, Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.post('/api/super-admin/billing/invoices/$invoiceId/payments/', data: payload);
      return RecordPaymentResultDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Record invoice payment error', e);
      rethrow;
    }
  }

  /// Update editable invoice fields — mirrors web's `updateInvoice()`
  /// (`PATCH /billing/invoices/{id}/`).
  Future<InvoiceDto> updateInvoice(String invoiceId, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.patch('/api/super-admin/billing/invoices/$invoiceId/', data: data);
      return InvoiceDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Update invoice error', e);
      rethrow;
    }
  }

  /// Cancel (soft-delete) an invoice — mirrors web's `cancelInvoice()`
  /// (`DELETE /billing/invoices/{id}/`).
  Future<InvoiceDto> cancelInvoice(String invoiceId) async {
    try {
      final response = await _dioClient.delete('/api/super-admin/billing/invoices/$invoiceId/');
      return InvoiceDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Cancel invoice error', e);
      rethrow;
    }
  }

  /// Send (record) a payment reminder for an invoice — mirrors web's
  /// `sendInvoiceReminder()` (`POST /billing/invoices/{id}/reminder/`).
  /// The endpoint returns a small `{invoice_number, status,
  /// reminder_recorded}` envelope, not a full invoice.
  Future<InvoiceReminderResultDto> sendInvoiceReminder(String invoiceId) async {
    try {
      final response = await _dioClient.post('/api/super-admin/billing/invoices/$invoiceId/reminder/');
      return InvoiceReminderResultDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Send invoice reminder error', e);
      rethrow;
    }
  }

  /// Fetch the GSTR-1 export as raw CSV text — mirrors web's `exportGstr1()`
  /// (`GET /billing/export/gstr1/`, `text/csv` response).
  Future<String> exportGstr1() async {
    try {
      final response = await _dioClient.get(
        '/api/super-admin/billing/export/gstr1/',
        options: Options(responseType: ResponseType.plain),
      );
      return response.data as String;
    } catch (e) {
      AppLogger.error('Export GSTR-1 error', e);
      rethrow;
    }
  }

  /// Get the subscription plans catalog — mirrors web's `getPlans()`.
  Future<PlansCatalogDto> getPlans() async {
    try {
      final response = await _dioClient.get('/api/super-admin/billing/plans/');
      return PlansCatalogDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get plans error', e);
      rethrow;
    }
  }

  /// Create a new subscription plan — mirrors web's `createPlan()`
  /// (`POST /billing/plans/`).
  Future<SubscriptionPlanDto> createPlan(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post('/api/super-admin/billing/plans/', data: data);
      return SubscriptionPlanDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Create plan error', e);
      rethrow;
    }
  }

  /// Update an existing subscription plan — mirrors web's `updatePlan()`
  /// (`PATCH /billing/plans/{code}/`, code is immutable).
  Future<SubscriptionPlanDto> updatePlan(String code, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.patch('/api/super-admin/billing/plans/$code/', data: data);
      return SubscriptionPlanDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Update plan error', e);
      rethrow;
    }
  }

  /// Delete a subscription plan by code — mirrors web's `deletePlan()`
  /// (`DELETE /billing/plans/{code}/`).
  Future<void> deletePlan(String code) async {
    try {
      await _dioClient.delete('/api/super-admin/billing/plans/$code/');
    } catch (e) {
      AppLogger.error('Delete plan error', e);
      rethrow;
    }
  }

  /// Get audit events with pagination and filters
  Future<PaginatedAuditEventsDto> getAuditEvents({
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
      final queryParams = <String, dynamic>{};

      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();
      if (actor != null && actor.isNotEmpty) queryParams['actor'] = actor;
      if (action != null && action.isNotEmpty) queryParams['action'] = action;
      if (tenantId != null && tenantId.isNotEmpty) queryParams['tenant_id'] = tenantId;
      if (severity != null && severity.isNotEmpty) queryParams['severity'] = severity;
      if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;

      final response = await _dioClient.get(
        '/api/super-admin/audit/',
        queryParameters: queryParams,
      );

      return PaginatedAuditEventsDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get audit events error', e);
      rethrow;
    }
  }

  /// Get platform policies grouped by category
  Future<List<PolicyGroupDto>> getPolicies() async {
    try {
      final response = await _dioClient.get('/api/super-admin/policies/');
      final data = response.data as List<dynamic>;
      return data.map((e) => PolicyGroupDto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.error('Get policies error', e);
      rethrow;
    }
  }

  /// Get read-only platform settings — mirrors web's `getPolicySettings()`.
  /// Response shape: `{system: {...}, notification: {...}, integrations: {...},
  /// storage: {...}, api: {...}}`, each a flat map of primitive values
  /// (`PolicySettingsSerializer`, backend `serializers.py:457-462`).
  Future<Map<String, dynamic>> getPolicySettings() async {
    try {
      final response = await _dioClient.get('/api/super-admin/policies/settings/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Get policy settings error', e);
      rethrow;
    }
  }

  /// Save one or more policy value changes — mirrors web's `updatePolicies()`,
  /// which PATCHes a flat `{key: value}` map (`policies.ts:26-36`) to the
  /// same endpoint the GET above uses. Returns the refreshed grouped list.
  Future<List<PolicyGroupDto>> updatePolicies(Map<String, dynamic> updates) async {
    try {
      final response = await _dioClient.patch('/api/super-admin/policies/', data: updates);
      final data = response.data as List<dynamic>;
      return data.map((e) => PolicyGroupDto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.error('Update policies error', e);
      rethrow;
    }
  }
}
