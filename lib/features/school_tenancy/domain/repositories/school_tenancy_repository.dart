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

  /// Provision a new school tenant — mirrors web's `provisionSchool()`.
  Future<ProvisionSchoolResultEntity> provisionSchool(Map<String, dynamic> data);

  /// Update a school (full field set — mirrors web's `updateSchool()` used
  /// by the Edit-school form; distinct from [updateSchoolStatus] above).
  Future<SchoolEntity> updateSchoolFields(String tenantId, Map<String, dynamic> data);

  /// Upload a school's logo. Returns the stored logo URL, if any.
  Future<String?> uploadSchoolLogo(String tenantId, List<int> bytes, String filename);

  /// Update a school's status (suspend/restore) — mirrors web's `updateSchool()`.
  Future<SchoolEntity> updateSchoolStatus(String tenantId, String status);

  /// Archive (soft-delete) a school — mirrors web's `deleteSchool()`.
  Future<void> archiveSchool(String tenantId);

  /// Mint an impersonation handoff — mirrors web's `impersonateSchool()`.
  Future<ImpersonateResultEntity> impersonateSchool(String tenantId);

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

  /// Create an invoice — mirrors web's `createInvoice()`. Throws the raw
  /// DioException on failure so callers can detect a 409 duplicate-invoice
  /// conflict (`response.data['code'] == 'duplicate_invoice'`).
  Future<InvoiceEntity> createInvoice(Map<String, dynamic> data);

  /// Mark an invoice as paid (settles the full outstanding balance in one
  /// payment) — mirrors web's `markInvoicePaid()`. The real "Record payment"
  /// UI uses [recordInvoicePayment] instead so partial amounts are possible.
  Future<InvoiceEntity> markInvoicePaid(String invoiceId);

  /// Record a payment (full or partial) against an invoice — mirrors web's
  /// `recordInvoicePayment()`. The backend recomputes `paid_amount`/
  /// `due_amount` and derives status (`partially_paid` vs `paid`).
  Future<RecordPaymentResultEntity> recordInvoicePayment(String invoiceId, Map<String, dynamic> payload);

  /// Update editable invoice fields (status/due_date/notes/terms_conditions
  /// only — amounts/line items are locked once issued) — mirrors web's
  /// `updateInvoice()`.
  Future<InvoiceEntity> updateInvoice(String invoiceId, Map<String, dynamic> data);

  /// Cancel (soft-delete) an invoice — mirrors web's `cancelInvoice()`.
  Future<InvoiceEntity> cancelInvoice(String invoiceId);

  /// Send (record) a payment reminder for an invoice — mirrors web's
  /// `sendInvoiceReminder()`. No mailer is wired on the backend's public
  /// schema; this bumps a `draft` invoice to `sent` and logs the action.
  Future<InvoiceReminderResultEntity> sendInvoiceReminder(String invoiceId);

  /// Fetch the GSTR-1 export as raw CSV text — mirrors web's `exportGstr1()`.
  Future<String> exportGstr1();

  /// Get the subscription plans catalog — mirrors web's `getPlans()`.
  Future<PlansCatalogEntity> getPlans();

  /// Create a new subscription plan — mirrors web's `createPlan()`.
  Future<SubscriptionPlanEntity> createPlan(Map<String, dynamic> data);

  /// Update an existing subscription plan (code is immutable) — mirrors
  /// web's `updatePlan()`.
  Future<SubscriptionPlanEntity> updatePlan(String code, Map<String, dynamic> data);

  /// Delete a subscription plan by code — mirrors web's `deletePlan()`.
  Future<void> deletePlan(String code);

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

  /// Persist one or more policy value changes — mirrors web's `updatePolicies()`.
  Future<List<PolicyGroupEntity>> updatePolicies(Map<String, dynamic> updates);

  /// Read-only platform settings — mirrors web's `getPolicySettings()`.
  Future<Map<String, dynamic>> getPolicySettings();
}
