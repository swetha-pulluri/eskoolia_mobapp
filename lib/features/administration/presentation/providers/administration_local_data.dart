import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../../domain/entities/student_category_entity.dart';
import '../../domain/entities/paginated_result.dart';

/// ========================================================================
/// UI-ONLY LOCAL SAMPLE DATA — Administration module
/// ========================================================================
/// No backend/API calls are made for Administration right now (by explicit
/// instruction) — every list below is an in-memory placeholder data set
/// used purely so the real web layout/forms/tables can be reproduced and
/// interacted with. Complaint Type / Source labels are copied verbatim
/// from the web's own `fallbackComplaintTypeOptions` /
/// `fallbackComplaintSourceOptions` (real literals in `ComplaintPanel.tsx`,
/// not invented). Everything else is a small, clearly-placeholder seed set.
///
/// When backend integration is restored, only `administration_provider.dart`
/// needs to change back to the repository-backed wiring — no screen files
/// are touched by this file.
/// ========================================================================
class AdministrationLocalData {
  AdministrationLocalData._();

  // ─── Visitor Book ─────────────────────────────────────────────────────
  static final List<VisitorEntity> _visitors = [
    const VisitorEntity(
      id: 1,
      purposeId: '1',
      purposeName: 'Admission Inquiry',
      name: 'Ramesh Kumar',
      phone: '9876543210',
      noOfPerson: 2,
      date: '2026-07-18',
      inTime: '10:15:00',
      outTime: '10:45:00',
    ),
    const VisitorEntity(
      id: 2,
      purposeId: '2',
      purposeName: 'Meeting',
      name: 'Sunita Rao',
      phone: '9123456780',
      noOfPerson: 1,
      date: '2026-07-19',
      inTime: '11:30:00',
      outTime: '12:00:00',
    ),
    const VisitorEntity(
      id: 3,
      purposeId: '3',
      purposeName: 'Delivery',
      name: 'Courier — BlueDart',
      noOfPerson: 1,
      date: '2026-07-20',
      inTime: '09:05:00',
      outTime: '09:10:00',
    ),
  ];

  // ─── Complaints ───────────────────────────────────────────────────────
  static final List<ComplaintEntity> _complaints = [
    const ComplaintEntity(
      id: 1,
      complaintBy: 'Parent of Aarav Shah',
      complaintTypeId: '16',
      complaintTypeName: 'Discipline Issue',
      complaintSourceId: '24',
      complaintSourceName: 'Phone Call',
      phone: '9988776655',
      date: '2026-07-17',
      description: 'Reported bullying incident in class 6.',
    ),
    const ComplaintEntity(
      id: 2,
      complaintBy: 'Meena Iyer',
      complaintTypeId: '19',
      complaintTypeName: 'Fee Related',
      complaintSourceId: '23',
      complaintSourceName: 'Walk-in',
      date: '2026-07-19',
      actionTaken: 'Forwarded to accounts team.',
    ),
  ];

  // ─── Phone Call Log ───────────────────────────────────────────────────
  static final List<PhoneCallEntity> _phoneCalls = [
    const PhoneCallEntity(
      id: 1,
      name: 'Vikram Singh',
      phone: '9871234560',
      date: '2026-07-18',
      callDuration: '00:04:30',
      description: 'Asked about transport routes.',
      callType: 'I',
    ),
    const PhoneCallEntity(
      id: 2,
      name: 'Admissions Follow-up',
      phone: '9012345678',
      date: '2026-07-19',
      nextFollowUpDate: '2026-07-26',
      callDuration: '00:02:10',
      callType: 'O',
    ),
  ];

  // ─── Postal Received / Dispatched ─────────────────────────────────────
  static final List<PostalReceiveEntity> _postalReceives = [
    const PostalReceiveEntity(
      id: 1,
      fromTitle: 'District Education Office',
      referenceNo: 'PR-2026-001',
      address: 'Collectorate Road, Hyderabad',
      toTitle: 'Principal',
      date: '2026-07-15',
      note: 'Circular on exam schedule.',
    ),
  ];

  static final List<PostalDispatchEntity> _postalDispatches = [
    const PostalDispatchEntity(
      id: 1,
      toTitle: 'Regional Transport Office',
      referenceNo: 'PD-2026-001',
      address: 'RTO Complex, Hyderabad',
      fromTitle: 'School Administration',
      date: '2026-07-16',
      note: 'Bus fitness renewal application.',
    ),
  ];

  // ─── Admin Setup lookups ───────────────────────────────────────────────
  // Type "2"/"3" labels are the web's own literal fallback lists
  // (`fallbackComplaintTypeOptions` / `fallbackComplaintSourceOptions` in
  // ComplaintPanel.tsx) — not invented.
  static final List<AdminSetupEntity> _adminSetups = [
    const AdminSetupEntity(id: 1, type: '1', typeName: 'Purpose', name: 'Admission Inquiry'),
    const AdminSetupEntity(id: 2, type: '1', typeName: 'Purpose', name: 'Meeting'),
    const AdminSetupEntity(id: 3, type: '1', typeName: 'Purpose', name: 'Delivery'),
    const AdminSetupEntity(id: 4, type: '1', typeName: 'Purpose', name: 'Official Visit'),
    const AdminSetupEntity(id: 5, type: '2', typeName: 'Complaint Type', name: 'Academic Performance'),
    const AdminSetupEntity(id: 6, type: '2', typeName: 'Complaint Type', name: 'Discipline Issue'),
    const AdminSetupEntity(id: 7, type: '2', typeName: 'Complaint Type', name: 'Fee Related'),
    const AdminSetupEntity(id: 8, type: '2', typeName: 'Complaint Type', name: 'Food/Canteen'),
    const AdminSetupEntity(id: 9, type: '2', typeName: 'Complaint Type', name: 'Infrastructure'),
    const AdminSetupEntity(id: 10, type: '2', typeName: 'Complaint Type', name: 'Safety Concern'),
    const AdminSetupEntity(id: 11, type: '2', typeName: 'Complaint Type', name: 'Staff Behaviour'),
    const AdminSetupEntity(id: 12, type: '2', typeName: 'Complaint Type', name: 'Transport'),
    const AdminSetupEntity(id: 13, type: '3', typeName: 'Source', name: 'Walk-in'),
    const AdminSetupEntity(id: 14, type: '3', typeName: 'Source', name: 'Phone Call'),
    const AdminSetupEntity(id: 15, type: '3', typeName: 'Source', name: 'Website'),
    const AdminSetupEntity(id: 16, type: '3', typeName: 'Source', name: 'Social Media'),
    const AdminSetupEntity(id: 17, type: '3', typeName: 'Source', name: 'Newspaper Ad'),
    const AdminSetupEntity(id: 18, type: '3', typeName: 'Source', name: 'Referral'),
    const AdminSetupEntity(id: 19, type: '3', typeName: 'Source', name: 'School Event'),
    const AdminSetupEntity(id: 20, type: '4', typeName: 'Reference', name: 'Existing Parent'),
    const AdminSetupEntity(id: 21, type: '4', typeName: 'Reference', name: 'Staff Referral'),
  ];

  // ─── Student Categories ───────────────────────────────────────────────
  static final List<StudentCategoryEntity> _studentCategories = [
    const StudentCategoryEntity(id: 1, name: 'General', code: 'GEN', description: 'Default category for all students.', status: 'active', studentsCount: 420),
    const StudentCategoryEntity(id: 2, name: 'SC/ST', code: 'SCST', description: 'Reserved category as per government norms.', status: 'active', studentsCount: 96),
    const StudentCategoryEntity(id: 3, name: 'OBC', code: 'OBC', description: 'Other Backward Classes category.', status: 'active', studentsCount: 133),
    const StudentCategoryEntity(id: 4, name: 'Staff Ward', code: 'STAFF', description: 'Children of school staff members.', status: 'inactive', studentsCount: 12),
  ];

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

  static Future<StudentCategoryEntity> createStudentCategory(StudentCategoryEntity e) async {
    final created = StudentCategoryEntity(
      id: _nextId(_studentCategories),
      name: e.name,
      code: e.code,
      description: e.description,
      status: e.status,
      studentsCount: 0,
    );
    _studentCategories.insert(0, created);
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
    );
    if (existingIndex != -1) _studentCategories[existingIndex] = updated;
    return updated;
  }

  static Future<void> deleteStudentCategory(int id) async => _studentCategories.removeWhere((e) => e.id == id);
}
