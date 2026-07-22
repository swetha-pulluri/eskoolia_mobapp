import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/student_category_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/certificate_entity.dart';
import 'administration_list_state.dart';
import 'administration_local_data.dart';

/// ========================================================================
/// UI-ONLY PROVIDERS — LOCAL SAMPLE DATA (no backend/API calls)
/// ========================================================================
/// Administration is deliberately NOT wired to the real
/// `AdministrationRepository`/`AdministrationRemoteDataSource` right now —
/// every provider below is backed by `AdministrationLocalData`'s in-memory
/// lists instead. The domain entities and the real repository/datasource
/// implementation are left untouched under `data/` and `domain/` so
/// re-wiring to the real API later is a change to this file only — no
/// screen file depends on where the data comes from.
/// ========================================================================

// ─── Visitor Book ─────────────────────────────────────────────────────────
final visitorListProvider =
    StateNotifierProvider.autoDispose<AdminListNotifier<VisitorEntity>, AdminListState<VisitorEntity>>((ref) {
  return AdminListNotifier<VisitorEntity>(
    fetchPage: ({required page, required pageSize}) => AdministrationLocalData.getVisitors(page: page, pageSize: pageSize),
    createItem: AdministrationLocalData.createVisitor,
    updateItem: AdministrationLocalData.updateVisitor,
    deleteItem: AdministrationLocalData.deleteVisitor,
    idOf: (v) => v.id!,
  );
});

// ─── Complaints ───────────────────────────────────────────────────────────
final complaintListProvider =
    StateNotifierProvider.autoDispose<AdminListNotifier<ComplaintEntity>, AdminListState<ComplaintEntity>>((ref) {
  return AdminListNotifier<ComplaintEntity>(
    fetchPage: ({required page, required pageSize}) => AdministrationLocalData.getComplaints(page: page, pageSize: pageSize),
    createItem: AdministrationLocalData.createComplaint,
    updateItem: AdministrationLocalData.updateComplaint,
    deleteItem: AdministrationLocalData.deleteComplaint,
    idOf: (c) => c.id!,
  );
});

// ─── Phone Call Log ───────────────────────────────────────────────────────
final phoneCallListProvider =
    StateNotifierProvider.autoDispose<AdminListNotifier<PhoneCallEntity>, AdminListState<PhoneCallEntity>>((ref) {
  return AdminListNotifier<PhoneCallEntity>(
    fetchPage: ({required page, required pageSize}) => AdministrationLocalData.getPhoneCalls(page: page, pageSize: pageSize),
    createItem: AdministrationLocalData.createPhoneCall,
    updateItem: AdministrationLocalData.updatePhoneCall,
    deleteItem: AdministrationLocalData.deletePhoneCall,
    idOf: (c) => c.id!,
  );
});

// ─── Admin Setup (Purpose / Complaint Type / Source / Reference) ────────
/// One notifier instance per lookup `type` ("1".."4"), keyed via `.family`.
final adminSetupListProvider = StateNotifierProvider.autoDispose
    .family<AdminListNotifier<AdminSetupEntity>, AdminListState<AdminSetupEntity>, String>((ref, type) {
  return AdminListNotifier<AdminSetupEntity>(
    fetchPage: ({required page, required pageSize}) =>
        AdministrationLocalData.getAdminSetups(type: type, page: page, pageSize: pageSize),
    createItem: AdministrationLocalData.createAdminSetup,
    updateItem: AdministrationLocalData.updateAdminSetup,
    deleteItem: AdministrationLocalData.deleteAdminSetup,
    idOf: (e) => e.id!,
    pageSize: 5,
  );
});

/// Purpose options (type "1") for the Visitor Book form's dropdown.
final purposeOptionsProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) async {
  final result = await AdministrationLocalData.getAdminSetups(type: '1', page: 1, pageSize: 100);
  return result.results;
});

/// Complaint Type options (type "2") for the Complaints form's dropdown.
final complaintTypeOptionsProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) async {
  final result = await AdministrationLocalData.getAdminSetups(type: '2', page: 1, pageSize: 100);
  return result.results;
});

/// Complaint Source options (type "3") for the Complaints form's dropdown.
final complaintSourceOptionsProvider = FutureProvider.autoDispose<List<AdminSetupEntity>>((ref) async {
  final result = await AdministrationLocalData.getAdminSetups(type: '3', page: 1, pageSize: 100);
  return result.results;
});

// ─── Postal Received ──────────────────────────────────────────────────────
final postalReceiveListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<PostalReceiveEntity>,
    AdminListState<PostalReceiveEntity>>((ref) {
  return AdminListNotifier<PostalReceiveEntity>(
    fetchPage: ({required page, required pageSize}) => AdministrationLocalData.getPostalReceives(page: page, pageSize: pageSize),
    createItem: AdministrationLocalData.createPostalReceive,
    updateItem: AdministrationLocalData.updatePostalReceive,
    deleteItem: AdministrationLocalData.deletePostalReceive,
    idOf: (e) => e.id!,
  );
});

// ─── Postal Dispatched ────────────────────────────────────────────────────
final postalDispatchListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<PostalDispatchEntity>,
    AdminListState<PostalDispatchEntity>>((ref) {
  return AdminListNotifier<PostalDispatchEntity>(
    fetchPage: ({required page, required pageSize}) => AdministrationLocalData.getPostalDispatches(page: page, pageSize: pageSize),
    createItem: AdministrationLocalData.createPostalDispatch,
    updateItem: AdministrationLocalData.updatePostalDispatch,
    deleteItem: AdministrationLocalData.deletePostalDispatch,
    idOf: (e) => e.id!,
  );
});

// ─── Student Categories ───────────────────────────────────────────────────
/// '' = All, otherwise 'active' | 'inactive'.
final studentCategoryStatusFilterProvider = StateProvider.autoDispose<String>((ref) => '');

final studentCategoryListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<StudentCategoryEntity>,
    AdminListState<StudentCategoryEntity>>((ref) {
  final status = ref.watch(studentCategoryStatusFilterProvider);
  return AdminListNotifier<StudentCategoryEntity>(
    fetchPage: ({required page, required pageSize}) =>
        AdministrationLocalData.getStudentCategories(page: page, pageSize: pageSize, status: status.isEmpty ? null : status),
    createItem: AdministrationLocalData.createStudentCategory,
    updateItem: AdministrationLocalData.updateStudentCategory,
    deleteItem: AdministrationLocalData.deleteStudentCategory,
    idOf: (c) => c.id!,
  );
});

/// Summary cards data for Student Categories — recomputed whenever the
/// list changes (matches web re-fetching `/summary/` after every mutation).
final studentCategorySummaryProvider = FutureProvider.autoDispose<StudentCategorySummary>((ref) {
  ref.watch(studentCategoryListProvider);
  return AdministrationLocalData.getStudentCategorySummary();
});

// ─── Roles / Classes / Sections / Recipients (ID Card & Certificate) ─────
final rolesProvider = FutureProvider.autoDispose<List<RoleEntity>>((ref) => AdministrationLocalData.getRoles());
final classesProvider = FutureProvider.autoDispose<List<ClassEntity>>((ref) => AdministrationLocalData.getClasses());
final sectionsProvider = FutureProvider.autoDispose<List<SectionEntity>>((ref) => AdministrationLocalData.getSections());
final recipientsProvider = FutureProvider.autoDispose<List<RecipientEntity>>((ref) => AdministrationLocalData.getRecipients());

// ─── ID Card Templates ────────────────────────────────────────────────────
final idCardTemplateListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<IdCardTemplateEntity>,
    AdminListState<IdCardTemplateEntity>>((ref) {
  return AdminListNotifier<IdCardTemplateEntity>(
    fetchPage: ({required page, required pageSize}) => AdministrationLocalData.getIdCardTemplates(page: page, pageSize: pageSize),
    createItem: AdministrationLocalData.createIdCardTemplate,
    updateItem: AdministrationLocalData.updateIdCardTemplate,
    deleteItem: AdministrationLocalData.deleteIdCardTemplate,
    idOf: (e) => e.id!,
  );
});

// ─── Certificate Templates ────────────────────────────────────────────────
final certificateTemplateListProvider = StateNotifierProvider.autoDispose<AdminListNotifier<CertificateTemplateEntity>,
    AdminListState<CertificateTemplateEntity>>((ref) {
  return AdminListNotifier<CertificateTemplateEntity>(
    fetchPage: ({required page, required pageSize}) => AdministrationLocalData.getCertificateTemplates(page: page, pageSize: pageSize),
    createItem: AdministrationLocalData.createCertificateTemplate,
    updateItem: AdministrationLocalData.updateCertificateTemplate,
    deleteItem: AdministrationLocalData.deleteCertificateTemplate,
    idOf: (e) => e.id!,
  );
});
