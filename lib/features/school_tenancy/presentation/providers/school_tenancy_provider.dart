import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/school_tenancy_remote_datasource.dart';
import '../../data/repositories/school_tenancy_repository_impl.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/school_entity.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/audit_entity.dart';
import '../../domain/entities/policy_entity.dart';
import '../../domain/repositories/school_tenancy_repository.dart';

/// ========================================
/// DEPENDENCY INJECTION
/// ========================================

final schoolTenancyRemoteDataSourceProvider = Provider<SchoolTenancyRemoteDataSource>((ref) {
  return SchoolTenancyRemoteDataSource(ref.watch(dioClientProvider));
});

final schoolTenancyRepositoryProvider = Provider<SchoolTenancyRepository>((ref) {
  return SchoolTenancyRepositoryImpl(ref.watch(schoolTenancyRemoteDataSourceProvider));
});

/// ========================================
/// REAL API PROVIDERS
/// ========================================
/// Each provider fetches live data from the Super Admin Console backend
/// (`/api/super-admin/...`) via [SchoolTenancyRepository]. Billing, Audit,
/// and Policies are adapted from the backend-shaped entities into the
/// simpler UI-shaped entities the existing tabs already consume.

/// Dashboard Provider
final schoolTenancyDashboardProvider = FutureProvider<DashboardEntity>((ref) {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  return repository.getDashboard();
});

/// Schools Provider with Filters
/// Default `status: 'active'` matches web's own initial state
/// (`const [statusFilter, setStatusFilter] = useState<SchoolStatus | 'all'>('active')`,
/// `schools/page.tsx:429`) — web's own default view is "Active", not "All".
final schoolsFiltersProvider = StateProvider<SchoolFilters>((ref) {
  return const SchoolFilters(status: 'active');
});

final schoolsProvider = FutureProvider<PaginatedSchoolsEntity>((ref) {
  final filters = ref.watch(schoolsFiltersProvider);
  final repository = ref.watch(schoolTenancyRepositoryProvider);

  return repository.getSchools(
    page: filters.page,
    pageSize: filters.pageSize,
    search: filters.search,
    status: filters.status,
    board: filters.board,
    plan: filters.plan,
    region: filters.region,
    state: filters.state,
  );
});

/// Global (unfiltered) school stats used for KPI cards + status-pill counts
/// — mirrors web's `loadGlobalStats()`, which fetches up to 200 schools and
/// derives total/active/trial/attention(suspended)/archived counts locally,
/// independent of whatever filter is currently applied to the main list.
final schoolsGlobalStatsProvider = FutureProvider<SchoolsGlobalStats>((ref) async {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  final response = await repository.getSchools(pageSize: 200);
  final all = response.results;
  return SchoolsGlobalStats(
    total: response.count,
    active: all.where((s) => !['archived', 'suspended'].contains(s.status)).length,
    trial: all.where((s) => s.plan == 'trial' && !['archived', 'suspended'].contains(s.status)).length,
    attention: all.where((s) => s.status == 'suspended').length,
    archived: all.where((s) => s.status == 'archived').length,
  );
});

class SchoolsGlobalStats {
  final int total;
  final int active;
  final int trial;
  final int attention;
  final int archived;

  const SchoolsGlobalStats({
    required this.total,
    required this.active,
    required this.trial,
    required this.attention,
    required this.archived,
  });
}

/// Billing Providers — use the full backend-shaped [InvoiceEntity] directly
/// (previously adapted down to a UI-only entity that dropped tenant/seller/
/// buyer/line-items/tax fields, which made a real Tax Invoice preview
/// impossible).
final billingMrrProvider = FutureProvider<BillingMrrEntity>((ref) {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  return repository.getMrr();
});

/// Matches web's `getInvoices({ page: 1, page_size: 6 })` (`billing/page.tsx:592`).
final invoicesProvider = FutureProvider<PaginatedInvoicesEntity>((ref) {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  return repository.getInvoices(page: 1, pageSize: 6);
});

/// Matches web's `getPlans()` — the real subscription plans catalog.
final plansProvider = FutureProvider<PlansCatalogEntity>((ref) {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  return repository.getPlans();
});

/// A schools list independent of [schoolsFiltersProvider] (which belongs to
/// the Schools tab's own filter UI) — mirrors `NewInvoiceDrawer`'s own
/// independent `getSchools({ page: 1, page_size: 200 })` fetch used to
/// populate the school picker.
final schoolsForInvoicePickerProvider = FutureProvider<PaginatedSchoolsEntity>((ref) {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  return repository.getSchools(pageSize: 200);
});

/// Audit Provider — [AuditEventEntity] already matches field-for-field, so
/// this just unwraps the pagination envelope into [AuditStateEntity].
final auditProvider = FutureProvider<AuditStateEntity>((ref) async {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  // Matches web's own `getAuditEvents({ page: 1, page_size: 200 })` —
  // `audit/page.tsx:177` — both apps filter client-side over this one batch.
  final events = await repository.getAuditEvents(pageSize: 200);
  return AuditStateEntity(events: events.results);
});

/// Policies Provider — regroups the backend's generic
/// `List<PolicyGroupEntity>` into the 4 fixed category lists the Policies
/// tab's `TabController` renders.
final policiesProvider = FutureProvider<PoliciesStateEntity>((ref) async {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  final groups = await repository.getPolicies();

  List<PolicyEntity> policiesFor(String category) {
    return groups.where((g) => g.group == category).expand((g) => g.policies).toList();
  }

  return PoliciesStateEntity(
    security: policiesFor('security'),
    dataIsolation: policiesFor('data_isolation'),
    billing: policiesFor('billing'),
    system: policiesFor('system'),
  );
});

/// Platform Settings Provider — read-only, mirrors web's `getPolicySettings()`.
final policySettingsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(schoolTenancyRepositoryProvider);
  return repository.getPolicySettings();
});

/// School Filters
class SchoolFilters {
  final int? page;
  final int? pageSize;
  final String? search;
  final String? status;
  final String? board;
  final String? plan;
  final String? region;
  final String? state;

  const SchoolFilters({
    this.page,
    // Matches web's `PAGE_SIZE = 10` (`schools/page.tsx:17`).
    this.pageSize = 10,
    this.search,
    this.status,
    this.board,
    this.plan,
    this.region,
    this.state,
  });

  SchoolFilters copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? status,
    String? board,
    String? plan,
    String? region,
    String? state,
  }) {
    return SchoolFilters(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      status: status ?? this.status,
      board: board ?? this.board,
      plan: plan ?? this.plan,
      region: region ?? this.region,
      state: state ?? this.state,
    );
  }
}
