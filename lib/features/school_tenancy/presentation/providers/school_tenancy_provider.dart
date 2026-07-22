import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/school_entity.dart';
import '../../domain/entities/billing_entity.dart';
import '../../domain/entities/audit_entity.dart';
import '../../domain/entities/policy_entity.dart';
import 'school_tenancy_local_data.dart';

/// ========================================
/// UI-ONLY PROVIDERS - LOCAL SAMPLE DATA
/// ========================================
/// 
/// These providers use local sample data for UI preview only.
/// No backend API calls are made.
/// 
/// After authentication is merged on Monday, these will be replaced
/// with real API integration using repositories and remote datasources.
/// ========================================

/// Dashboard Provider - Returns local sample data
final schoolTenancyDashboardProvider = Provider<DashboardEntity>((ref) {
  return SchoolTenancyLocalData.getDashboard();
});

/// Schools Provider with Filters - Returns filtered local sample data
final schoolsFiltersProvider = StateProvider<SchoolFilters>((ref) {
  return const SchoolFilters();
});

final schoolsProvider = Provider<PaginatedSchoolsEntity>((ref) {
  final filters = ref.watch(schoolsFiltersProvider);
  
  return SchoolTenancyLocalData.getSchools(
    search: filters.search,
    status: filters.status,
    board: filters.board,
    plan: filters.plan,
  );
});

/// Billing Provider - Returns local sample billing data
final billingProvider = Provider<BillingStateEntity>((ref) {
  return SchoolTenancyLocalData.getBillingState();
});

/// Audit Provider - Returns local sample audit data
final auditProvider = Provider<AuditStateEntity>((ref) {
  return SchoolTenancyLocalData.getAuditState();
});

/// Policies Provider - Returns local sample policies data
final policiesProvider = Provider<PoliciesStateEntity>((ref) {
  return SchoolTenancyLocalData.getPoliciesState();
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
    this.pageSize = 20,
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
