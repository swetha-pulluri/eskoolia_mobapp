import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/admissions_remote_datasource.dart';
import '../../data/repositories/admissions_repository_impl.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/entities/school_class_entity.dart';
import '../../domain/entities/analytics_data_entity.dart';
import '../../domain/repositories/admissions_repository.dart';
import '../../../administration/domain/entities/admin_setup_entity.dart';

/// ========================================================================
/// DEPENDENCY INJECTION — real backend
/// ========================================================================
final admissionsRemoteDataSourceProvider = Provider<AdmissionsRemoteDataSource>((ref) {
  return AdmissionsRemoteDataSource(ref.watch(dioClientProvider));
});

final admissionsRepositoryProvider = Provider<AdmissionsRepository>((ref) {
  return AdmissionsRepositoryImpl(ref.watch(admissionsRemoteDataSourceProvider));
});

/// ========================================================================
/// Command Center / Analytics providers — wired to the real
/// `AdmissionsRepository` (`/api/v1/admissions/inquiries/`,
/// `/api/v1/core/classes/`, `/api/v1/admissions/admin-setups/`,
/// `/api/v1/admissions/analytics/overview/`). Marketing's static content
/// stays in `admissions_local_data.dart` (see that file — the real web
/// Marketing tab makes zero API calls).
/// ========================================================================

/// Reload token — bumped after any create/update/delete so dependent
/// providers (inquiries, classes, analytics) refetch. Mirrors the web's
/// `loadAll()` re-fetch pattern without needing a full CRUD notifier per
/// entity (Admissions' data is read/derived far more than it's edited from
/// a list screen — most mutations happen through modals).
final admissionsReloadProvider = StateProvider<int>((ref) => 0);

/// The current logged-in user's own school id (`UserEntity.schoolId`, from
/// `GET /auth/me/`). Used below to re-scope every Admissions list to the
/// account's own school, client-side.
///
/// This matters specifically for superuser test accounts:
/// `ClassViewSet`/`AdmissionInquiryViewSet`/`AdminSetupEntryViewSet.get_queryset()`
/// all skip the `school_id` filter entirely when `request.user.is_superuser`
/// (confirmed directly against the live backend — a superuser sees every
/// class from every school merged together, e.g. "Nursery" appearing once
/// per school instead of once). Command Center is a single-school
/// operational tool (New Enquiry, Morning Brief, etc. all assume one
/// school's context), so re-scoping to the logged-in account's own school
/// here is a correctness fix, not a deviation — it's the same scoping the
/// backend already correctly applies for every non-superuser account, just
/// applied client-side for the one case where the server skips it. This is
/// a no-op for already-scoped (non-superuser) accounts.
final currentSchoolIdProvider = Provider<int?>((ref) {
  return ref.watch(authNotifierProvider).whenOrNull(authenticated: (user) => user.schoolId);
});

final inquiriesProvider = FutureProvider.autoDispose<List<InquiryEntity>>((ref) async {
  ref.watch(admissionsReloadProvider);
  final all = await ref.watch(admissionsRepositoryProvider).getInquiries();
  final schoolId = ref.watch(currentSchoolIdProvider);
  if (schoolId == null) return all;
  return all.where((i) => i.schoolId == null || i.schoolId == schoolId).toList();
});


final schoolClassesProvider = FutureProvider.autoDispose<List<SchoolClassEntity>>((ref) async {
  ref.watch(admissionsReloadProvider);
  final all = await ref.watch(admissionsRepositoryProvider).getClasses();
  final schoolId = ref.watch(currentSchoolIdProvider);
  if (schoolId == null) return all;
  return all.where((c) => c.schoolId == null || c.schoolId == schoolId).toList();
});

/// Source options (Admin Setup type "3") for the enquiry form's "How did
/// they hear about us?" dropdown — same backend model as Administration's
/// Admin Setup, reused rather than duplicated.
final admissionSourcesProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) async {
  ref.watch(admissionsReloadProvider);
  final all = await ref.watch(admissionsRepositoryProvider).getSources();
  final schoolId = ref.watch(currentSchoolIdProvider);
  if (schoolId == null) return all;
  return all.where((s) => s.schoolId == null || s.schoolId == schoolId).toList();
});

/// Reference options (Admin Setup type "4").
final admissionReferencesProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) async {
  ref.watch(admissionsReloadProvider);
  final all = await ref.watch(admissionsRepositoryProvider).getReferences();
  final schoolId = ref.watch(currentSchoolIdProvider);
  if (schoolId == null) return all;
  return all.where((r) => r.schoolId == null || r.schoolId == schoolId).toList();
});

/// Analytics period filter — "month" | "quarter" | "year" | "all".
/// Default "all", matching web's `AdmissionsAnalytics.tsx` initial state.
final analyticsPeriodProvider = StateProvider.autoDispose<String>((ref) => 'all');

/// Unlike inquiries/classes/sources above, this cannot be re-scoped
/// client-side: `AnalyticsOverviewView` returns already-aggregated numbers
/// (counts, percentages, monthly trend), not raw rows, so there is nothing
/// to re-filter by school on the client. For a superuser account this
/// endpoint's `request.user.school_id` check is skipped too, so its
/// figures are genuinely cross-tenant-aggregated today — a backend
/// limitation out of scope to fix here.
final analyticsOverviewProvider = FutureProvider.autoDispose<AnalyticsDataEntity>((ref) {
  ref.watch(admissionsReloadProvider);
  final period = ref.watch(analyticsPeriodProvider);
  return ref.watch(admissionsRepositoryProvider).getAnalyticsOverview(period: period);
});

/// Selected class in the Command Center's Class Portfolio Grid.
/// `null` initial = no class selected yet (workspace hidden);
/// once set, `-1` sentinel means "All Classes" (matches web's
/// `selectedClassId` semantics: `undefined` vs `null` vs a real id).
final selectedClassIdProvider = StateProvider.autoDispose<int?>((ref) => null);
final classWorkspaceVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);
