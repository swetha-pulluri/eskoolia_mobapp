import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/administration_remote_datasource.dart';
import '../../data/repositories/administration_repository_impl.dart';
import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/student_category_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/repositories/administration_repository.dart';
import 'administration_list_state.dart';

/// ========================================================================
/// DEPENDENCY INJECTION — real backend
/// ========================================================================
final administrationRemoteDataSourceProvider = Provider<AdministrationRemoteDataSource>((ref) {
  return AdministrationRemoteDataSource(ref.watch(dioClientProvider));
});

final administrationRepositoryProvider = Provider<AdministrationRepository>((ref) {
  return AdministrationRepositoryImpl(ref.watch(administrationRemoteDataSourceProvider));
});

/// ========================================================================
/// Every provider below — Communication Hub, Postal Management, System
/// Config, and Documents Studio — is wired to the real
/// `AdministrationRepository` (`/api/v1/admissions/...`,
/// `/api/v1/students/categories/...`, `/api/v1/access-control/roles/`).
/// No screen file depends on this — they all go through the generic
/// `AdminListNotifier`/repository interface.
/// ========================================================================

// ─── Visitor Book ─────────────────────────────────────────────────────────
/// Smart Filter state — `purposeName` is the resolved setup *name* (the
/// backend's `purpose` query param matches against the name, not the id;
/// web resolves this the same way before building the request).
typedef VisitorFilter = ({String search, String? purposeId, String? purposeName, String? date});

final visitorFilterProvider = StateProvider.autoDispose<VisitorFilter>(
  (ref) => (search: '', purposeId: null, purposeName: null, date: null),
);

final visitorListProvider =
    StateNotifierProvider.autoDispose<AdminListNotifier<VisitorEntity>, AdminListState<VisitorEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  final filter = ref.watch(visitorFilterProvider);
  return AdminListNotifier<VisitorEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getVisitors(
      page: page,
      pageSize: pageSize,
      search: filter.search.isEmpty ? null : filter.search,
      purpose: filter.purposeName,
      date: filter.date,
    ),
    createItem: repository.createVisitor,
    updateItem: repository.updateVisitor,
    deleteItem: repository.deleteVisitor,
    idOf: (v) => v.id!,
  );
});

// ─── Complaints ───────────────────────────────────────────────────────────
final complaintListProvider =
    StateNotifierProvider.autoDispose<AdminListNotifier<ComplaintEntity>, AdminListState<ComplaintEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return AdminListNotifier<ComplaintEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getComplaints(page: page, pageSize: pageSize),
    createItem: repository.createComplaint,
    updateItem: repository.updateComplaint,
    deleteItem: repository.deleteComplaint,
    idOf: (c) => c.id!,
  );
});

// ─── Phone Call Log ───────────────────────────────────────────────────────
final phoneCallListProvider =
    StateNotifierProvider.autoDispose<AdminListNotifier<PhoneCallEntity>, AdminListState<PhoneCallEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return AdminListNotifier<PhoneCallEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getPhoneCalls(page: page, pageSize: pageSize),
    createItem: repository.createPhoneCall,
    updateItem: repository.updatePhoneCall,
    deleteItem: repository.deletePhoneCall,
    idOf: (c) => c.id!,
  );
});

// ─── Admin Setup (Purpose / Complaint Type / Source / Reference) ────────
/// One notifier instance per lookup `type` ("1".."4"), keyed via `.family`.
final adminSetupListProvider = StateNotifierProvider.autoDispose
    .family<AdminListNotifier<AdminSetupEntity>, AdminListState<AdminSetupEntity>, String>((ref, type) {
  final repository = ref.watch(administrationRepositoryProvider);
  return AdminListNotifier<AdminSetupEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getAdminSetups(type: type, page: page, pageSize: pageSize),
    createItem: repository.createAdminSetup,
    updateItem: repository.updateAdminSetup,
    deleteItem: repository.deleteAdminSetup,
    idOf: (e) => e.id!,
    pageSize: 5,
  );
});

/// Purpose options for the Visitor Book form's dropdown.
///
/// The real, currently-deployed `VisitorBookPanel.tsx` (`main` — confirmed
/// by inspecting the actual running frontend dev server's process, which
/// serves from this checkout's `main` branch) fetches
/// `/api/v1/admissions/admin-setups/` with **no** query params at all and
/// filters client-side by `type === "1"`. `AdminSetupEntryViewSet` paginates
/// with `AdminSetupPagination.page_size = 5` when no `page_size` is
/// requested, and `AdminSetupEntry.Meta.ordering = ['type', 'name']` sorts
/// type "1" (Purpose) first — so for any school with more than 5 Purpose
/// entries, the real web page only ever shows the first 5 alphabetically
/// and silently drops the rest (confirmed against real data: school id 1
/// has 6 Purpose entries; the unfiltered fetch returns only the first 5,
/// omitting "Ravi"). An earlier pass "fixed" this by switching to a richer,
/// server-side `type`-filtered fetch that shows every Purpose entry — that
/// is exactly why the dropdown stopped matching web (it showed one *more*
/// real entry than the web page ever displays). Reverted to the identical
/// unfiltered-fetch-then-client-filter call so this dropdown shows exactly
/// what web shows, including web's own truncation.
final purposeOptionsProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) async {
  final repository = ref.watch(administrationRepositoryProvider);
  final all = (await repository.getAdminSetupsUnfiltered()).results;
  return all.where((e) => e.type == '1').toList();
});

/// Complaint Type / Complaint Source options for the Complaints form's
/// dropdowns.
///
/// Corrected after directly enumerating the currently-deployed backend's
/// registered URL patterns (`django.urls.get_resolver()`): there is no
/// `/complaint-types/` or `/complaint-sources/` route registered at all —
/// only `/admissions/complaints/`, `/visitors/`, `/admin-setups/`. A
/// dedicated `ComplaintType`/`ComplaintSource` FK-table design exists on
/// the `origin/demo` branch, but that branch's code is not what is running
/// here, so calling those endpoints only ever 404s (which is exactly why
/// these dropdowns previously showed no options and felt "unresponsive").
/// The currently-deployed `ComplaintEntrySerializer` (`main`) treats
/// `complaint_type`/`complaint_source` as plain `CharField`s resolved via
/// `_resolve_setup_name()` against `AdminSetupEntry` rows of `type="2"`
/// (Complaint Type) / `type="3"` (Source) — the exact same lookup table
/// Purpose (`type="1"`) already uses. So these dropdowns are wired to the
/// same `getAdminSetups(type: ...)` call as Purpose, just with the other
/// two type codes.
final complaintTypeOptionsProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) async {
  final repository = ref.watch(administrationRepositoryProvider);
  return (await repository.getAdminSetups(type: '2', pageSize: 50)).results;
});

/// Complaint Source options — see [complaintTypeOptionsProvider].
final complaintSourceOptionsProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) async {
  final repository = ref.watch(administrationRepositoryProvider);
  return (await repository.getAdminSetups(type: '3', pageSize: 50)).results;
});

// ─── Postal Received ──────────────────────────────────────────────────────
final postalReceiveListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<PostalReceiveEntity>,
    AdminListState<PostalReceiveEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return AdminListNotifier<PostalReceiveEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getPostalReceives(page: page, pageSize: pageSize),
    createItem: repository.createPostalReceive,
    updateItem: repository.updatePostalReceive,
    deleteItem: repository.deletePostalReceive,
    idOf: (e) => e.id!,
  );
});

// ─── Postal Dispatched ────────────────────────────────────────────────────
final postalDispatchListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<PostalDispatchEntity>,
    AdminListState<PostalDispatchEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return AdminListNotifier<PostalDispatchEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getPostalDispatches(page: page, pageSize: pageSize),
    createItem: repository.createPostalDispatch,
    updateItem: repository.updatePostalDispatch,
    deleteItem: repository.deletePostalDispatch,
    idOf: (e) => e.id!,
  );
});

// ─── Student Categories ───────────────────────────────────────────────────
/// '' = All, 'active' | 'inactive' = `status` query param, 'attention' =
/// the "AI flagged" chip — a *separate* `attention=1` query param on the
/// backend (`StudentCategoryViewSet.get_queryset`), not a `status` value.
final studentCategoryStatusFilterProvider = StateProvider.autoDispose<String>((ref) => '');

final studentCategoryListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<StudentCategoryEntity>,
    AdminListState<StudentCategoryEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  final filter = ref.watch(studentCategoryStatusFilterProvider);
  final isAttention = filter == 'attention';
  return AdminListNotifier<StudentCategoryEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getStudentCategories(
      page: page,
      pageSize: pageSize,
      status: isAttention || filter.isEmpty ? null : filter,
      attention: isAttention,
    ),
    createItem: repository.createStudentCategory,
    updateItem: repository.updateStudentCategory,
    deleteItem: repository.deleteStudentCategory,
    idOf: (c) => c.id!,
  );
});

/// Summary cards data for Student Categories — recomputed whenever the
/// list changes (matches web re-fetching `/summary/` after every mutation).
final studentCategorySummaryProvider = FutureProvider.autoDispose<StudentCategorySummary>((ref) {
  ref.watch(studentCategoryListProvider);
  final repository = ref.watch(administrationRepositoryProvider);
  return repository.getStudentCategorySummary();
});

// ─── Roles / Classes / Sections / Recipients (ID Card & Certificate) ─────
/// Backs the Class/Section lists both ID Card screens use, and the Role
/// list specifically for ID Card's own *Generate & Print* screen
/// (`GenerateIdCardPanel.tsx` sources its role dropdown only from this
/// action's `roles`, never `/access-control/roles/`).
final _idCardGenerateSetupProvider = FutureProvider.autoDispose<DocumentGenerateSetup>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return repository.getIdCardGenerateSetup();
});

/// ID Card's Design Template screen (`IdCardPanel.tsx`) — a DIFFERENT role
/// source from Generate & Print: it calls `/api/v1/access-control/roles/`
/// first, and only falls back to `generate-setup`'s `roles` if that comes
/// back empty (`IdCardPanel.tsx` `load()`). Used only by
/// [id_cards_screen.dart]'s Applicable Roles picker.
final idCardDesignRolesProvider = FutureProvider.autoDispose<List<RoleEntity>>((ref) async {
  final repository = ref.watch(administrationRepositoryProvider);
  try {
    final direct = await repository.getRoles();
    if (direct.isNotEmpty) return direct;
  } catch (_) {
    // fall through to generate-setup, matching web's try/catch-and-continue
  }
  try {
    return (await repository.getIdCardGenerateSetup()).roles;
  } catch (_) {
    return const [];
  }
});

/// Certificate's Design Template screen (`CertificatePanel.tsx`) does NOT
/// use a generate-setup action for its role picker — it calls
/// `/api/v1/access-control/roles/` directly, in parallel with the
/// certificate-templates list fetch. Certificate's own Generate & Print
/// screen (`GenerateCertificatePanel.tsx`), by contrast, DOES use its own
/// `certificate-templates/generate-setup/` action for roles/classes/
/// sections — a separate endpoint from ID Card's.
final certificateRolesProvider = FutureProvider.autoDispose<List<RoleEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return repository.getRoles();
});

final _certificateGenerateSetupProvider = FutureProvider.autoDispose<DocumentGenerateSetup>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return repository.getCertificateGenerateSetup();
});

final rolesProvider = FutureProvider.autoDispose<List<RoleEntity>>((ref) async {
  return (await ref.watch(_idCardGenerateSetupProvider.future)).roles;
});
final classesProvider = FutureProvider.autoDispose<List<ClassEntity>>((ref) async {
  return (await ref.watch(_idCardGenerateSetupProvider.future)).classes;
});
final sectionsProvider = FutureProvider.autoDispose<List<SectionEntity>>((ref) async {
  return (await ref.watch(_idCardGenerateSetupProvider.future)).sections;
});

final certificateGenerateRolesProvider = FutureProvider.autoDispose<List<RoleEntity>>((ref) async {
  return (await ref.watch(_certificateGenerateSetupProvider.future)).roles;
});
final certificateClassesProvider = FutureProvider.autoDispose<List<ClassEntity>>((ref) async {
  return (await ref.watch(_certificateGenerateSetupProvider.future)).classes;
});
final certificateSectionsProvider = FutureProvider.autoDispose<List<SectionEntity>>((ref) async {
  return (await ref.watch(_certificateGenerateSetupProvider.future)).sections;
});

/// Template dropdown for the Generate & Print screens — `generate-setup`'s
/// own embedded, unpaginated `templates` list (matches
/// `GenerateIdCardPanel.tsx`/`GenerateCertificatePanel.tsx` exactly), NOT
/// the separate paginated CRUD list endpoint used by the Design Template
/// management screens (`idCardTemplateListProvider`/
/// `certificateTemplateListProvider`), which defaults to 10/page and would
/// silently truncate for a school with more templates than that.
final idCardGenerateTemplatesProvider = FutureProvider.autoDispose<List<IdCardTemplateEntity>>((ref) async {
  final setup = await ref.watch(_idCardGenerateSetupProvider.future);
  return setup.templates.map((e) => IdCardTemplateEntity.fromJson(e as Map<String, dynamic>)).toList();
});

final certificateGenerateTemplatesProvider = FutureProvider.autoDispose<List<CertificateTemplateEntity>>((ref) async {
  final setup = await ref.watch(_certificateGenerateSetupProvider.future);
  return setup.templates.map((e) => CertificateTemplateEntity.fromJson(e as Map<String, dynamic>)).toList();
});

/// Recipients for the Generate & Print screens — needs `role` (required by
/// the backend) plus optional `classId`/`sectionId`.
typedef RecipientsQuery = ({int? roleId, int? classId, int? sectionId});

final recipientsProvider = FutureProvider.autoDispose.family<List<RecipientEntity>, RecipientsQuery>((ref, query) async {
  if (query.roleId == null) return const [];
  final repository = ref.watch(administrationRepositoryProvider);
  final result = await repository.getIdCardRecipients(role: query.roleId!, classId: query.classId, sectionId: query.sectionId);
  return result.recipients;
});

final certificateRecipientsProvider = FutureProvider.autoDispose.family<List<RecipientEntity>, RecipientsQuery>((ref, query) async {
  if (query.roleId == null) return const [];
  final repository = ref.watch(administrationRepositoryProvider);
  final result = await repository.getCertificateRecipients(role: query.roleId!, classId: query.classId, sectionId: query.sectionId);
  return result.recipients;
});

// ─── ID Card Templates ────────────────────────────────────────────────────
final idCardTemplateListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<IdCardTemplateEntity>,
    AdminListState<IdCardTemplateEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return AdminListNotifier<IdCardTemplateEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getIdCardTemplates(page: page, pageSize: pageSize),
    createItem: repository.createIdCardTemplate,
    updateItem: repository.updateIdCardTemplate,
    deleteItem: repository.deleteIdCardTemplate,
    idOf: (e) => e.id!,
  );
});

// ─── Certificate Templates ────────────────────────────────────────────────
final certificateTemplateListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<CertificateTemplateEntity>,
    AdminListState<CertificateTemplateEntity>>((ref) {
  final repository = ref.watch(administrationRepositoryProvider);
  return AdminListNotifier<CertificateTemplateEntity>(
    fetchPage: ({required page, required pageSize}) => repository.getCertificateTemplates(page: page, pageSize: pageSize),
    createItem: repository.createCertificateTemplate,
    updateItem: repository.updateCertificateTemplate,
    deleteItem: repository.deleteCertificateTemplate,
    idOf: (e) => e.id!,
  );
});
