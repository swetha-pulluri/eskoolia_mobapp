import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/entities/school_class_entity.dart';
import '../../domain/entities/analytics_data_entity.dart';
import '../../../administration/domain/entities/admin_setup_entity.dart';
import 'admissions_local_data.dart';

/// ========================================================================
/// UI-ONLY PROVIDERS — Admissions module (no backend calls; see
/// `admissions_local_data.dart` for the architectural rationale).
/// ========================================================================

/// Reload token — bumped after any create/update/delete so dependent
/// providers (inquiries, classes, analytics) refetch. Mirrors the web's
/// `loadAll()` re-fetch pattern without needing a full CRUD notifier per
/// entity (Admissions' data is read/derived far more than it's edited from
/// a list screen — most mutations happen through modals).
final admissionsReloadProvider = StateProvider<int>((ref) => 0);

final inquiriesProvider = FutureProvider.autoDispose<List<InquiryEntity>>((ref) {
  ref.watch(admissionsReloadProvider);
  return AdmissionsLocalData.getInquiries();
});


final schoolClassesProvider = FutureProvider.autoDispose<List<SchoolClassEntity>>((ref) {
  ref.watch(admissionsReloadProvider);
  return AdmissionsLocalData.getClasses();
});

/// Source options (Admin Setup type "3") for the enquiry form's "How did
/// they hear about us?" dropdown — same backend model as Administration's
/// Admin Setup, reused rather than duplicated.
final admissionSourcesProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) {
  ref.watch(admissionsReloadProvider);
  return AdmissionsLocalData.getSources();
});

/// Reference options (Admin Setup type "4").
final admissionReferencesProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) {
  ref.watch(admissionsReloadProvider);
  return AdmissionsLocalData.getReferences();
});

/// Analytics period filter — "month" | "quarter" | "year" | "all".
/// Default "all", matching web's `AdmissionsAnalytics.tsx` initial state.
final analyticsPeriodProvider = StateProvider.autoDispose<String>((ref) => 'all');

final analyticsOverviewProvider = FutureProvider.autoDispose<AnalyticsDataEntity>((ref) {
  ref.watch(admissionsReloadProvider);
  final period = ref.watch(analyticsPeriodProvider);
  return AdmissionsLocalData.getAnalyticsOverview(period: period);
});

/// Selected class in the Command Center's Class Portfolio Grid.
/// `null` initial = no class selected yet (workspace hidden);
/// once set, `-1` sentinel means "All Classes" (matches web's
/// `selectedClassId` semantics: `undefined` vs `null` vs a real id).
final selectedClassIdProvider = StateProvider.autoDispose<int?>((ref) => null);
final classWorkspaceVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);
