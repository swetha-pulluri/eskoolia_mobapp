import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../../domain/entities/student_category_entity.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/certificate_entity.dart';

/// ========================================================================
/// UI-ONLY LOCAL DATA STORE — Administration module
/// ========================================================================
/// No backend/API calls are made for Administration right now (by explicit
/// instruction). Every list below starts EMPTY — there is no static/demo
/// row data anywhere in the actual web source (`VisitorBookPanel.tsx`,
/// `ComplaintPanel.tsx`, etc. all fetch real rows from the backend; none of
/// them ship hardcoded sample records). Inventing placeholder rows (fake
/// visitor names, fake complaints, fake categories, etc.) would show data
/// that does not exist in the web application, so instead these lists start
/// empty and each screen renders its own real, web-verified empty-state
/// text ("No visitor records found.", "No complaints found.", ...) by
/// default — exactly what an unseeded web instance would show. Anything
/// that appears in a list after that is only data entered through the
/// Flutter form itself during this session, via the same CRUD methods
/// below.
///
/// The two exceptions are `fallbackComplaintTypeOptions` /
/// `fallbackComplaintSourceOptions` below — those ARE real hardcoded
/// literals inside `ComplaintPanel.tsx` itself (used when the admin-setups
/// fetch is empty/unavailable), so they are reproduced verbatim rather than
/// invented.
///
/// When backend integration is restored, only `administration_provider.dart`
/// needs to change back to the repository-backed wiring — no screen files
/// are touched by this file.
/// ========================================================================
class AdministrationLocalData {
  AdministrationLocalData._();

  // ─── Visitor Book ─────────────────────────────────────────────────────
  static final List<VisitorEntity> _visitors = [];

  // ─── Complaints ───────────────────────────────────────────────────────
  static final List<ComplaintEntity> _complaints = [];

  // ─── Phone Call Log ───────────────────────────────────────────────────
  static final List<PhoneCallEntity> _phoneCalls = [];

  // ─── Postal Received / Dispatched ─────────────────────────────────────
  static final List<PostalReceiveEntity> _postalReceives = [];

  static final List<PostalDispatchEntity> _postalDispatches = [];

  // ─── Admin Setup lookups ───────────────────────────────────────────────
  // Type "1" (Purpose) and "4" (Reference) have no static fallback in the
  // web source — they come only from the live API, so they start empty.
  // Type "2"/"3" are seeded with the web's own literal fallback lists
  // (`fallbackComplaintTypeOptions` / `fallbackComplaintSourceOptions` in
  // ComplaintPanel.tsx) since those specific labels really do ship in the
  // web bundle itself, verbatim, not invented.
  static final List<AdminSetupEntity> _adminSetups = [
    const AdminSetupEntity(id: 1, type: '2', typeName: 'Complaint Type', name: 'Academic Performance'),
    const AdminSetupEntity(id: 2, type: '2', typeName: 'Complaint Type', name: 'Discipline Issue'),
    const AdminSetupEntity(id: 3, type: '2', typeName: 'Complaint Type', name: 'Fee Related'),
    const AdminSetupEntity(id: 4, type: '2', typeName: 'Complaint Type', name: 'Food/Canteen'),
    const AdminSetupEntity(id: 5, type: '2', typeName: 'Complaint Type', name: 'Infrastructure'),
    const AdminSetupEntity(id: 6, type: '2', typeName: 'Complaint Type', name: 'Safety Concern'),
    const AdminSetupEntity(id: 7, type: '2', typeName: 'Complaint Type', name: 'Staff Behaviour'),
    const AdminSetupEntity(id: 8, type: '2', typeName: 'Complaint Type', name: 'Transport'),
    const AdminSetupEntity(id: 9, type: '3', typeName: 'Source', name: 'Walk-in'),
    const AdminSetupEntity(id: 10, type: '3', typeName: 'Source', name: 'Phone Call'),
    const AdminSetupEntity(id: 11, type: '3', typeName: 'Source', name: 'Website'),
    const AdminSetupEntity(id: 12, type: '3', typeName: 'Source', name: 'Social Media'),
    const AdminSetupEntity(id: 13, type: '3', typeName: 'Source', name: 'Newspaper Ad'),
    const AdminSetupEntity(id: 14, type: '3', typeName: 'Source', name: 'Referral'),
    const AdminSetupEntity(id: 15, type: '3', typeName: 'Source', name: 'School Event'),
    const AdminSetupEntity(id: 16, type: '3', typeName: 'Source', name: 'In Person'),
    const AdminSetupEntity(id: 17, type: '3', typeName: 'Source', name: 'Online'),
    const AdminSetupEntity(id: 18, type: '3', typeName: 'Source', name: 'Written'),
  ];

  // ─── Roles / Classes / Sections (ID Card & Certificate generate-setup) ─
  // All come only from live API/backend data on web — no static fallback,
  // so these start empty (ID Cards' web panel explicitly renders a "No
  // roles available" warning in this exact case — see IdCardsScreen).
  static final List<RoleEntity> _roles = [];
  static final List<ClassEntity> _classes = [];
  static final List<SectionEntity> _sections = [];
  static final List<RecipientEntity> _recipients = [];

  // ─── ID Card Templates ─────────────────────────────────────────────────
  static final List<IdCardTemplateEntity> _idCardTemplates = [];

  // ─── Certificate Templates ─────────────────────────────────────────────
  static final List<CertificateTemplateEntity> _certificateTemplates = [];

  // ─── Student Categories ───────────────────────────────────────────────
  static final List<StudentCategoryEntity> _studentCategories = [];

  // ─── Generic in-memory pagination + CRUD helpers ──────────────────────
  static PaginatedResult<T> _page<T>(List<T> source, int page, int pageSize) {
    final start = (page - 1) * pageSize;
    if (start >= source.length) return PaginatedResult(results: const [], count: source.length);
    final end = (start + pageSize).clamp(0, source.length);
    return PaginatedResult(results: source.sublist(start, end), count: source.length);
  }

  static int _nextId(List<dynamic> source) {
    var max = 0;
    for (final item in source) {
      final id = item.id as int?;
      if (id != null && id > max) max = id;
    }
    return max + 1;
  }

  // Visitor Book
  static Future<PaginatedResult<VisitorEntity>> getVisitors({required int page, required int pageSize}) async =>
      _page(_visitors, page, pageSize);
  static Future<VisitorEntity> createVisitor(VisitorEntity v) async {
    final created = VisitorEntity(
      id: _nextId(_visitors),
      purposeId: v.purposeId,
      purposeName: v.purposeName,
      name: v.name,
      phone: v.phone,
      noOfPerson: v.noOfPerson,
      date: v.date,
      inTime: v.inTime,
      outTime: v.outTime,
    );
    _visitors.insert(0, created);
    return created;
  }

  static Future<VisitorEntity> updateVisitor(int id, VisitorEntity v) async {
    final updated = VisitorEntity(
      id: id,
      purposeId: v.purposeId,
      purposeName: v.purposeName,
      name: v.name,
      phone: v.phone,
      noOfPerson: v.noOfPerson,
      date: v.date,
      inTime: v.inTime,
      outTime: v.outTime,
    );
    final index = _visitors.indexWhere((e) => e.id == id);
    if (index != -1) _visitors[index] = updated;
    return updated;
  }

  static Future<void> deleteVisitor(int id) async => _visitors.removeWhere((e) => e.id == id);

  // Complaints
  static Future<PaginatedResult<ComplaintEntity>> getComplaints({required int page, required int pageSize}) async =>
      _page(_complaints, page, pageSize);
  static Future<ComplaintEntity> createComplaint(ComplaintEntity c) async {
    final created = ComplaintEntity(
      id: _nextId(_complaints),
      complaintBy: c.complaintBy,
      complaintTypeId: c.complaintTypeId,
      complaintTypeName: c.complaintTypeName,
      complaintSourceId: c.complaintSourceId,
      complaintSourceName: c.complaintSourceName,
      phone: c.phone,
      date: c.date,
      actionTaken: c.actionTaken,
      assigned: c.assigned,
      description: c.description,
    );
    _complaints.insert(0, created);
    return created;
  }

  static Future<ComplaintEntity> updateComplaint(int id, ComplaintEntity c) async {
    final updated = ComplaintEntity(
      id: id,
      complaintBy: c.complaintBy,
      complaintTypeId: c.complaintTypeId,
      complaintTypeName: c.complaintTypeName,
      complaintSourceId: c.complaintSourceId,
      complaintSourceName: c.complaintSourceName,
      phone: c.phone,
      date: c.date,
      actionTaken: c.actionTaken,
      assigned: c.assigned,
      description: c.description,
    );
    final index = _complaints.indexWhere((e) => e.id == id);
    if (index != -1) _complaints[index] = updated;
    return updated;
  }

  static Future<void> deleteComplaint(int id) async => _complaints.removeWhere((e) => e.id == id);

  // Phone Call Log
  static Future<PaginatedResult<PhoneCallEntity>> getPhoneCalls({required int page, required int pageSize}) async =>
      _page(_phoneCalls, page, pageSize);
  static Future<PhoneCallEntity> createPhoneCall(PhoneCallEntity c) async {
    final created = PhoneCallEntity(
      id: _nextId(_phoneCalls),
      name: c.name,
      phone: c.phone,
      date: c.date,
      nextFollowUpDate: c.nextFollowUpDate,
      callDuration: c.callDuration,
      description: c.description,
      callType: c.callType,
    );
    _phoneCalls.insert(0, created);
    return created;
  }

  static Future<PhoneCallEntity> updatePhoneCall(int id, PhoneCallEntity c) async {
    final updated = PhoneCallEntity(
      id: id,
      name: c.name,
      phone: c.phone,
      date: c.date,
      nextFollowUpDate: c.nextFollowUpDate,
      callDuration: c.callDuration,
      description: c.description,
      callType: c.callType,
    );
    final index = _phoneCalls.indexWhere((e) => e.id == id);
    if (index != -1) _phoneCalls[index] = updated;
    return updated;
  }

  static Future<void> deletePhoneCall(int id) async => _phoneCalls.removeWhere((e) => e.id == id);

  // Postal Received
  static Future<PaginatedResult<PostalReceiveEntity>> getPostalReceives({required int page, required int pageSize}) async =>
      _page(_postalReceives, page, pageSize);
  static Future<PostalReceiveEntity> createPostalReceive(PostalReceiveEntity e) async {
    final created = PostalReceiveEntity(
      id: _nextId(_postalReceives),
      fromTitle: e.fromTitle,
      referenceNo: e.referenceNo,
      address: e.address,
      note: e.note,
      toTitle: e.toTitle,
      date: e.date,
    );
    _postalReceives.insert(0, created);
    return created;
  }

  static Future<PostalReceiveEntity> updatePostalReceive(int id, PostalReceiveEntity e) async {
    final updated = PostalReceiveEntity(
      id: id,
      fromTitle: e.fromTitle,
      referenceNo: e.referenceNo,
      address: e.address,
      note: e.note,
      toTitle: e.toTitle,
      date: e.date,
    );
    final index = _postalReceives.indexWhere((x) => x.id == id);
    if (index != -1) _postalReceives[index] = updated;
    return updated;
  }

  static Future<void> deletePostalReceive(int id) async => _postalReceives.removeWhere((e) => e.id == id);

  // Postal Dispatched
  static Future<PaginatedResult<PostalDispatchEntity>> getPostalDispatches({required int page, required int pageSize}) async =>
      _page(_postalDispatches, page, pageSize);
  static Future<PostalDispatchEntity> createPostalDispatch(PostalDispatchEntity e) async {
    final created = PostalDispatchEntity(
      id: _nextId(_postalDispatches),
      toTitle: e.toTitle,
      referenceNo: e.referenceNo,
      address: e.address,
      note: e.note,
      fromTitle: e.fromTitle,
      date: e.date,
    );
    _postalDispatches.insert(0, created);
    return created;
  }

  static Future<PostalDispatchEntity> updatePostalDispatch(int id, PostalDispatchEntity e) async {
    final updated = PostalDispatchEntity(
      id: id,
      toTitle: e.toTitle,
      referenceNo: e.referenceNo,
      address: e.address,
      note: e.note,
      fromTitle: e.fromTitle,
      date: e.date,
    );
    final index = _postalDispatches.indexWhere((x) => x.id == id);
    if (index != -1) _postalDispatches[index] = updated;
    return updated;
  }

  static Future<void> deletePostalDispatch(int id) async => _postalDispatches.removeWhere((e) => e.id == id);

  // Admin Setup
  static Future<PaginatedResult<AdminSetupEntity>> getAdminSetups({
    required String type,
    required int page,
    required int pageSize,
  }) async {
    final filtered = _adminSetups.where((e) => e.type == type).toList();
    return _page(filtered, page, pageSize);
  }

  static Future<AdminSetupEntity> createAdminSetup(AdminSetupEntity e) async {
    final created = AdminSetupEntity(
      id: _nextId(_adminSetups),
      type: e.type,
      typeName: AdminSetupEntity.typeLabels[e.type],
      name: e.name,
      description: e.description,
    );
    _adminSetups.insert(0, created);
    return created;
  }

  static Future<AdminSetupEntity> updateAdminSetup(int id, AdminSetupEntity e) async {
    final updated = AdminSetupEntity(
      id: id,
      type: e.type,
      typeName: AdminSetupEntity.typeLabels[e.type],
      name: e.name,
      description: e.description,
    );
    final index = _adminSetups.indexWhere((x) => x.id == id);
    if (index != -1) _adminSetups[index] = updated;
    return updated;
  }

  static Future<void> deleteAdminSetup(int id) async => _adminSetups.removeWhere((e) => e.id == id);

  // Student Categories
  static Future<PaginatedResult<StudentCategoryEntity>> getStudentCategories({
    required int page,
    required int pageSize,
    String? status,
  }) async {
    final filtered = (status == null || status.isEmpty)
        ? _studentCategories
        : _studentCategories.where((e) => e.status == status).toList();
    return _page(filtered, page, pageSize);
  }

  /// Session-local activity log backing the "Recent Activity" summary
  /// card — records real mutations made this session rather than
  /// fabricating history (there is no backend activity log to mirror).
  static final List<({int id, String name, String action, DateTime at})> _categoryActivity = [];

  static Future<StudentCategoryEntity> createStudentCategory(StudentCategoryEntity e) async {
    final created = StudentCategoryEntity(
      id: _nextId(_studentCategories),
      name: e.name,
      code: e.code,
      description: e.description,
      status: e.status,
      studentsCount: 0,
      createdAt: DateTime.now().toIso8601String(),
      updatedBy: 'Admin',
    );
    _studentCategories.insert(0, created);
    _categoryActivity.insert(0, (id: created.id!, name: created.name, action: 'created', at: DateTime.now()));
    return created;
  }

  static Future<StudentCategoryEntity> updateStudentCategory(int id, StudentCategoryEntity e) async {
    final existingIndex = _studentCategories.indexWhere((x) => x.id == id);
    final existing = existingIndex != -1 ? _studentCategories[existingIndex] : null;
    final updated = StudentCategoryEntity(
      id: id,
      name: e.name,
      code: e.code,
      description: e.description,
      status: e.status,
      studentsCount: existing?.studentsCount,
      createdAt: existing?.createdAt,
      updatedBy: 'Admin',
    );
    if (existingIndex != -1) _studentCategories[existingIndex] = updated;
    _categoryActivity.insert(0, (id: id, name: updated.name, action: 'updated', at: DateTime.now()));
    return updated;
  }

  static Future<void> deleteStudentCategory(int id) async => _studentCategories.removeWhere((e) => e.id == id);

  /// Activates/deactivates a category by id — mirrors the web's dedicated
  /// `/{id}/deactivate/` endpoint and the status-toggle PATCH.
  static Future<StudentCategoryEntity> setStudentCategoryStatus(int id, String status) async {
    final index = _studentCategories.indexWhere((e) => e.id == id);
    final updated = _studentCategories[index].copyWith(status: status);
    _studentCategories[index] = updated;
    _categoryActivity.insert(0, (id: id, name: updated.name, action: status == 'active' ? 'activated' : 'deactivated', at: DateTime.now()));
    return updated;
  }

  /// Mirrors the web's `/api/v1/students/categories/summary/` shape —
  /// derived from the same in-memory list (no separate backend aggregate).
  static Future<StudentCategorySummary> getStudentCategorySummary() async {
    final total = _studentCategories.length;
    final active = _studentCategories.where((c) => c.isActive).length;
    final inactive = total - active;
    final attention = _studentCategories.where((c) => (c.description ?? '').trim().isEmpty).length;
    final sorted = List.of(_studentCategories)..sort((a, b) => (b.studentsCount ?? 0).compareTo(a.studentsCount ?? 0));
    final top = sorted.take(5).map((c) => (id: c.id!, name: c.name, studentsCount: c.studentsCount ?? 0)).toList();
    final totalStudents = _studentCategories.fold<int>(0, (sum, c) => sum + (c.studentsCount ?? 0));
    return StudentCategorySummary(
      totalCount: total,
      activeCount: active,
      inactiveCount: inactive,
      attentionCount: attention,
      topTotalStudents: totalStudents,
      topCategories: top,
      recentActivity: List.of(_categoryActivity.take(5)),
    );
  }

  // ─── Roles / Classes / Sections / Recipients ──────────────────────────
  static Future<List<RoleEntity>> getRoles() async => List.of(_roles);
  static Future<List<ClassEntity>> getClasses() async => List.of(_classes);
  static Future<List<SectionEntity>> getSections({int? classId}) async =>
      classId == null ? List.of(_sections) : _sections.where((s) => s.classId == classId).toList();
  static Future<List<RecipientEntity>> getRecipients() async => List.of(_recipients);

  // ID Card Templates
  static Future<PaginatedResult<IdCardTemplateEntity>> getIdCardTemplates({required int page, required int pageSize}) async =>
      _page(_idCardTemplates, page, pageSize);

  static Future<IdCardTemplateEntity> createIdCardTemplate(IdCardTemplateEntity e) async {
    final created = IdCardTemplateEntity(
      id: _nextId(_idCardTemplates),
      title: e.title,
      pageLayoutStyle: e.pageLayoutStyle,
      applicableRoleIds: e.applicableRoleIds,
      backgroundUrl: e.backgroundUrl,
      profileUrl: e.profileUrl,
      logoUrl: e.logoUrl,
      signatureUrl: e.signatureUrl,
    );
    _idCardTemplates.insert(0, created);
    return created;
  }

  static Future<IdCardTemplateEntity> updateIdCardTemplate(int id, IdCardTemplateEntity e) async {
    final updated = IdCardTemplateEntity(
      id: id,
      title: e.title,
      pageLayoutStyle: e.pageLayoutStyle,
      applicableRoleIds: e.applicableRoleIds,
      backgroundUrl: e.backgroundUrl,
      profileUrl: e.profileUrl,
      logoUrl: e.logoUrl,
      signatureUrl: e.signatureUrl,
    );
    final index = _idCardTemplates.indexWhere((x) => x.id == id);
    if (index != -1) _idCardTemplates[index] = updated;
    return updated;
  }

  static Future<void> deleteIdCardTemplate(int id) async => _idCardTemplates.removeWhere((e) => e.id == id);

  // Certificate Templates
  static Future<PaginatedResult<CertificateTemplateEntity>> getCertificateTemplates({required int page, required int pageSize}) async =>
      _page(_certificateTemplates, page, pageSize);

  static Future<CertificateTemplateEntity> createCertificateTemplate(CertificateTemplateEntity e) async {
    final created = CertificateTemplateEntity(
      id: _nextId(_certificateTemplates),
      type: e.type,
      title: e.title,
      applicableRoleId: e.applicableRoleId,
      body: e.body,
      backgroundHeight: e.backgroundHeight,
      backgroundWidth: e.backgroundWidth,
      paddingTop: e.paddingTop,
      paddingRight: e.paddingRight,
      paddingBottom: e.paddingBottom,
      paddingLeft: e.paddingLeft,
      backgroundUrl: e.backgroundUrl,
    );
    _certificateTemplates.insert(0, created);
    return created;
  }

  static Future<CertificateTemplateEntity> updateCertificateTemplate(int id, CertificateTemplateEntity e) async {
    final updated = CertificateTemplateEntity(
      id: id,
      type: e.type,
      title: e.title,
      applicableRoleId: e.applicableRoleId,
      body: e.body,
      backgroundHeight: e.backgroundHeight,
      backgroundWidth: e.backgroundWidth,
      paddingTop: e.paddingTop,
      paddingRight: e.paddingRight,
      paddingBottom: e.paddingBottom,
      paddingLeft: e.paddingLeft,
      backgroundUrl: e.backgroundUrl,
    );
    final index = _certificateTemplates.indexWhere((x) => x.id == id);
    if (index != -1) _certificateTemplates[index] = updated;
    return updated;
  }

  static Future<void> deleteCertificateTemplate(int id) async => _certificateTemplates.removeWhere((e) => e.id == id);
}
