import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/student_category_entity.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/picked_attachment.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/role_entity.dart';

/// Administration Remote Data Source
/// Calls the real backend endpoints under `apps/admissions`
/// (`/api/v1/admissions/...`) that power the web Administration module.
class AdministrationRemoteDataSource {
  final DioClient _dioClient;

  AdministrationRemoteDataSource(this._dioClient);

  Map<String, dynamic> _pageParams(int page, int pageSize) => {
        'page': page,
        'page_size': pageSize,
      };

  /// Every create/update endpoint under `apps/admissions` and
  /// `apps/students` wraps its response as
  /// `{"success": true, "message": "...", "data": {...actual record...}}`
  /// (`DuplicateSafeWriteMixin._success_response` / the equivalent explicit
  /// `Response({...})` calls on `StudentCategoryViewSet`), unlike `list`
  /// responses which are the plain, unwrapped DRF pagination envelope.
  /// Unwraps that `data` key when present so callers always get the real
  /// record map.
  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final data = map['data'];
    if (data is Map<String, dynamic>) return data;
    return map;
  }

  // ─── Visitor Book ─────────────────────────────────────────────────────
  /// `search`/`purpose`/`date` are real, server-side `get_queryset` filters
  /// on this endpoint (unlike Complaints/Phone Calls/Postal, which the web
  /// app never sends filter params to at all) — Visitor Book's own Smart
  /// Filter "Apply Filters" button triggers a real refetch with these.
  Future<PaginatedResult<VisitorEntity>> getVisitors({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? purpose,
    String? date,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/admissions/visitors/',
        queryParameters: {
          ..._pageParams(page, pageSize),
          if (search != null && search.isNotEmpty) 'search': search,
          if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
          if (date != null && date.isNotEmpty) 'date': date,
        },
      );
      return PaginatedResult.fromJson(response.data, VisitorEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get visitors error', e);
      rethrow;
    }
  }

  Future<VisitorEntity> createVisitor(VisitorEntity visitor) async {
    final response = await _dioClient.post('/api/v1/admissions/visitors/', data: await _visitorPayload(visitor));
    return VisitorEntity.fromJson(_unwrap(response.data));
  }

  Future<VisitorEntity> updateVisitor(int id, VisitorEntity visitor) async {
    final response = await _dioClient.patch('/api/v1/admissions/visitors/$id/', data: await _visitorPayload(visitor));
    return VisitorEntity.fromJson(_unwrap(response.data));
  }

  /// `multipart/form-data` (matches the web's `apiForm()`/FormData submit)
  /// when an attachment is picked, otherwise a plain JSON map.
  Future<dynamic> _visitorPayload(VisitorEntity visitor) async {
    final fields = visitor.toJson();
    if (visitor.attachment == null) return fields;
    return FormData.fromMap({
      ...fields.map((key, value) => MapEntry(key, value.toString())),
      'file_upload': MultipartFile.fromBytes(visitor.attachment!.bytes, filename: visitor.attachment!.name),
    });
  }

  Future<void> deleteVisitor(int id) async {
    await _dioClient.delete('/api/v1/admissions/visitors/$id/');
  }

  // ─── Complaints ────────────────────────────────────────────────────────
  /// The real `ComplaintPanel.tsx` calls this endpoint with **no** query
  /// params at all — not even `page`/`page_size` — so it only ever sees
  /// the backend's default first page (`ApiPageNumberPagination.page_size
  /// = 10`), with all search/type/source/date filtering and sorting done
  /// client-side over that fixed set. `page`/`pageSize` are accepted here
  /// only so the caller's local pagination-display state still works; they
  /// are intentionally NOT sent to the server, matching the real app.
  Future<PaginatedResult<ComplaintEntity>> getComplaints({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dioClient.get('/api/v1/admissions/complaints/');
      return PaginatedResult.fromJson(response.data, ComplaintEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get complaints error', e);
      rethrow;
    }
  }

  Future<ComplaintEntity> createComplaint(ComplaintEntity complaint) async {
    final response = await _dioClient.post('/api/v1/admissions/complaints/', data: _complaintPayload(complaint));
    return ComplaintEntity.fromJson(_unwrap(response.data));
  }

  Future<ComplaintEntity> updateComplaint(int id, ComplaintEntity complaint) async {
    final response = await _dioClient.patch('/api/v1/admissions/complaints/$id/', data: _complaintPayload(complaint));
    return ComplaintEntity.fromJson(_unwrap(response.data));
  }

  /// `multipart/form-data` when an attachment is picked (matches web's
  /// always-appended `file_upload`, `serializers.py`'s write-only
  /// `file_upload` field), otherwise a plain JSON map.
  dynamic _complaintPayload(ComplaintEntity complaint) {
    final fields = complaint.toJson();
    if (complaint.attachment == null) return fields;
    return FormData.fromMap({
      ...fields.map((key, value) => MapEntry(key, value.toString())),
      'file_upload': MultipartFile.fromBytes(complaint.attachment!.bytes, filename: complaint.attachment!.name),
    });
  }

  Future<void> deleteComplaint(int id) async {
    await _dioClient.delete('/api/v1/admissions/complaints/$id/');
  }

  // ─── Phone Call Log ────────────────────────────────────────────────────
  /// Same "no query params at all" behavior as Complaints — the real
  /// `PhoneCallLogPanel.tsx` never sends `page`/`page_size`/filter params;
  /// its Smart Filter UI only filters client-side over the backend's
  /// default first page.
  Future<PaginatedResult<PhoneCallEntity>> getPhoneCalls({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dioClient.get('/api/v1/admissions/phone-call-logs/');
      return PaginatedResult.fromJson(response.data, PhoneCallEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get phone call logs error', e);
      rethrow;
    }
  }

  Future<PhoneCallEntity> createPhoneCall(PhoneCallEntity call) async {
    final response = await _dioClient.post('/api/v1/admissions/phone-call-logs/', data: call.toJson());
    return PhoneCallEntity.fromJson(_unwrap(response.data));
  }

  Future<PhoneCallEntity> updatePhoneCall(int id, PhoneCallEntity call) async {
    final response = await _dioClient.patch('/api/v1/admissions/phone-call-logs/$id/', data: call.toJson());
    return PhoneCallEntity.fromJson(_unwrap(response.data));
  }

  Future<void> deletePhoneCall(int id) async {
    await _dioClient.delete('/api/v1/admissions/phone-call-logs/$id/');
  }

  // ─── Admin Setup (Purpose / Complaint Type / Source / Reference) ──────
  Future<PaginatedResult<AdminSetupEntity>> getAdminSetups({
    required String type,
    int page = 1,
    int pageSize = 5,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/admissions/admin-setups/',
        queryParameters: {'type': type, ..._pageParams(page, pageSize)},
      );
      return PaginatedResult.fromJson(response.data, AdminSetupEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get admin setups error', e);
      rethrow;
    }
  }

  /// `GET /api/v1/admissions/admin-setups/` with **no** query params at
  /// all — the exact call the real `VisitorBookPanel.tsx` makes for its
  /// Purpose dropdown (confirmed directly against `main`, the branch
  /// actually deployed here). The server's own `AdminSetupPagination`
  /// defaults to `page_size=5` when none is requested, so this
  /// intentionally reproduces the same 5-item cap the real web page shows
  /// (client-filtered by `type` afterwards) rather than a richer,
  /// unbounded fetch — matching web exactly, including its own known
  /// truncation, is what "same data as web" means here.
  Future<PaginatedResult<AdminSetupEntity>> getAdminSetupsUnfiltered() async {
    try {
      final response = await _dioClient.get('/api/v1/admissions/admin-setups/');
      return PaginatedResult.fromJson(response.data, AdminSetupEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get admin setups error', e);
      rethrow;
    }
  }

  Future<AdminSetupEntity> createAdminSetup(AdminSetupEntity entry) async {
    final response = await _dioClient.post('/api/v1/admissions/admin-setups/', data: entry.toJson());
    return AdminSetupEntity.fromJson(_unwrap(response.data));
  }

  Future<AdminSetupEntity> updateAdminSetup(int id, AdminSetupEntity entry) async {
    final response = await _dioClient.patch('/api/v1/admissions/admin-setups/$id/', data: entry.toJson());
    return AdminSetupEntity.fromJson(_unwrap(response.data));
  }

  Future<void> deleteAdminSetup(int id) async {
    await _dioClient.delete('/api/v1/admissions/admin-setups/$id/');
  }

  // ─── Postal Received ───────────────────────────────────────────────────
  /// Same "no query params" behavior as Complaints/Phone Calls — the real
  /// `PostalReceivePanel.tsx` fetches the whole endpoint with no
  /// `page`/`page_size`, filtering/sorting/paginating entirely client-side
  /// over the backend's default first page.
  Future<PaginatedResult<PostalReceiveEntity>> getPostalReceives({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dioClient.get('/api/v1/admissions/postal-receive/');
      return PaginatedResult.fromJson(response.data, PostalReceiveEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get postal receive error', e);
      rethrow;
    }
  }

  Future<PostalReceiveEntity> createPostalReceive(PostalReceiveEntity entry) async {
    final response = await _dioClient.post('/api/v1/admissions/postal-receive/', data: _postalPayload(entry.toJson(), entry.attachment));
    return PostalReceiveEntity.fromJson(_unwrap(response.data));
  }

  Future<PostalReceiveEntity> updatePostalReceive(int id, PostalReceiveEntity entry) async {
    final response =
        await _dioClient.patch('/api/v1/admissions/postal-receive/$id/', data: _postalPayload(entry.toJson(), entry.attachment));
    return PostalReceiveEntity.fromJson(_unwrap(response.data));
  }

  /// `multipart/form-data` when an attachment is picked (matches web's
  /// always-appended `file_upload`), otherwise a plain JSON map. Shared by
  /// both Postal Received and Postal Dispatched — same `file_upload`
  /// write-only serializer field on both endpoints.
  dynamic _postalPayload(Map<String, dynamic> fields, PickedAttachment? attachment) {
    if (attachment == null) return fields;
    return FormData.fromMap({
      ...fields.map((key, value) => MapEntry(key, value.toString())),
      'file_upload': MultipartFile.fromBytes(attachment.bytes, filename: attachment.name),
    });
  }

  Future<void> deletePostalReceive(int id) async {
    await _dioClient.delete('/api/v1/admissions/postal-receive/$id/');
  }

  // ─── Postal Dispatched ─────────────────────────────────────────────────
  /// No query params — matches the real `PostalDispatchPanel.tsx`, same
  /// as Postal Received.
  Future<PaginatedResult<PostalDispatchEntity>> getPostalDispatches({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dioClient.get('/api/v1/admissions/postal-dispatch/');
      return PaginatedResult.fromJson(response.data, PostalDispatchEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get postal dispatch error', e);
      rethrow;
    }
  }

  Future<PostalDispatchEntity> createPostalDispatch(PostalDispatchEntity entry) async {
    final response = await _dioClient.post('/api/v1/admissions/postal-dispatch/', data: _postalPayload(entry.toJson(), entry.attachment));
    return PostalDispatchEntity.fromJson(_unwrap(response.data));
  }

  Future<PostalDispatchEntity> updatePostalDispatch(int id, PostalDispatchEntity entry) async {
    final response =
        await _dioClient.patch('/api/v1/admissions/postal-dispatch/$id/', data: _postalPayload(entry.toJson(), entry.attachment));
    return PostalDispatchEntity.fromJson(_unwrap(response.data));
  }

  Future<void> deletePostalDispatch(int id) async {
    await _dioClient.delete('/api/v1/admissions/postal-dispatch/$id/');
  }

  // ─── Student Categories ────────────────────────────────────────────────
  /// `status` accepts `'active'|'inactive'`; the "AI flagged" chip maps to
  /// `attention: true` (a separate query param on the backend, not a
  /// `status` value — `StudentCategoryViewSet.get_queryset`).
  Future<PaginatedResult<StudentCategoryEntity>> getStudentCategories({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? search,
    bool attention = false,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/students/categories/',
        queryParameters: {
          ..._pageParams(page, pageSize),
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          if (attention) 'attention': '1',
        },
      );
      return PaginatedResult.fromJson(response.data, StudentCategoryEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get student categories error', e);
      rethrow;
    }
  }

  Future<StudentCategoryEntity> createStudentCategory(StudentCategoryEntity category) async {
    final response = await _dioClient.post('/api/v1/students/categories/', data: category.toJson());
    return StudentCategoryEntity.fromJson(_unwrap(response.data));
  }

  Future<StudentCategoryEntity> updateStudentCategory(int id, StudentCategoryEntity category) async {
    final response = await _dioClient.patch('/api/v1/students/categories/$id/', data: category.toJson());
    return StudentCategoryEntity.fromJson(_unwrap(response.data));
  }

  Future<void> deleteStudentCategory(int id) async {
    await _dioClient.delete('/api/v1/students/categories/$id/');
  }

  /// `GET /api/v1/students/categories/summary/` — backs the 3 summary
  /// cards (Total Categories / Students by Category / Recent Activity).
  Future<StudentCategorySummary> getStudentCategorySummary({String? search}) async {
    final response = await _dioClient.get(
      '/api/v1/students/categories/summary/',
      queryParameters: {if (search != null && search.isNotEmpty) 'search': search},
    );
    final data = response.data as Map<String, dynamic>;
    final topCategories = (data['top_categories'] as List? ?? const [])
        .map((e) => (
              id: (e as Map<String, dynamic>)['id'] as int,
              name: e['name'] as String? ?? '',
              studentsCount: e['students_count'] as int? ?? 0,
            ))
        .toList();
    final recentActivity = (data['recent_activity'] as List? ?? const [])
        .map((e) => (
              id: (e as Map<String, dynamic>)['id'] as int,
              name: e['name'] as String? ?? '',
              action: e['action'] as String? ?? 'Created',
              at: DateTime.tryParse(e['created_at'] as String? ?? '') ?? DateTime.now(),
            ))
        .toList();
    return StudentCategorySummary(
      totalCount: data['total_count'] as int? ?? 0,
      activeCount: data['active_count'] as int? ?? 0,
      inactiveCount: data['inactive_count'] as int? ?? 0,
      attentionCount: data['attention_count'] as int? ?? 0,
      topTotalStudents: data['top_total_students'] as int? ?? 0,
      topCategories: topCategories,
      recentActivity: recentActivity,
    );
  }

  /// `GET /api/v1/students/categories/check-name/?name=&exclude_id=`
  Future<bool> checkStudentCategoryNameExists(String name, {int? excludeId}) async {
    final response = await _dioClient.get(
      '/api/v1/students/categories/check-name/',
      queryParameters: {'name': name, 'exclude_id': ?excludeId},
    );
    return (response.data as Map<String, dynamic>)['exists'] as bool? ?? false;
  }

  /// `PATCH /api/v1/students/categories/bulk-status/` `{ids, status}`
  Future<String> bulkUpdateStudentCategoryStatus(List<int> ids, String status) async {
    final response = await _dioClient.patch(
      '/api/v1/students/categories/bulk-status/',
      data: {'ids': ids, 'status': status},
    );
    return (response.data as Map<String, dynamic>)['message'] as String? ?? 'Updated.';
  }

  /// `DELETE /api/v1/students/categories/bulk-delete/` `{ids}`
  Future<String> bulkDeleteStudentCategories(List<int> ids) async {
    final response = await _dioClient.delete(
      '/api/v1/students/categories/bulk-delete/',
      data: {'ids': ids},
    );
    return (response.data as Map<String, dynamic>)['message'] as String? ?? 'Deleted.';
  }

  // ─── Documents Studio: ID Card Templates ──────────────────────────────
  /// No query params — the real `IdCardPanel.tsx` fetches this endpoint
  /// with no `page`/`page_size` at all, showing whatever the backend's
  /// default first page returns with no further pagination UI.
  Future<PaginatedResult<IdCardTemplateEntity>> getIdCardTemplates({int page = 1, int pageSize = 10}) async {
    final response = await _dioClient.get('/api/v1/admissions/id-card-templates/');
    return PaginatedResult.fromJson(response.data, IdCardTemplateEntity.fromJson);
  }

  /// Builds multipart `FormData` when any of the 4 files is attached
  /// (matches web's always-multipart submit, `IdCardPanel.tsx:283-289`),
  /// otherwise a plain JSON map. `applicable_role_ids` must be a
  /// JSON-encoded string over multipart (the serializer's `create`/`update`
  /// `json.loads`s it when it arrives as a string) but a real list works
  /// fine as plain JSON.
  dynamic _idCardPayload(IdCardTemplateEntity e) {
    final fields = e.toJson();
    if (!e.hasAnyAttachment) return fields;
    final map = <String, dynamic>{
      'title': e.title,
      'page_layout_style': e.pageLayoutStyle,
      'applicable_role_ids': jsonEncode(e.applicableRoleIds),
    };
    if (e.backgroundAttachment != null) {
      map['background_upload'] = MultipartFile.fromBytes(e.backgroundAttachment!.bytes, filename: e.backgroundAttachment!.name);
    }
    if (e.profileAttachment != null) {
      map['profile_upload'] = MultipartFile.fromBytes(e.profileAttachment!.bytes, filename: e.profileAttachment!.name);
    }
    if (e.logoAttachment != null) {
      map['logo_upload'] = MultipartFile.fromBytes(e.logoAttachment!.bytes, filename: e.logoAttachment!.name);
    }
    if (e.signatureAttachment != null) {
      map['signature_upload'] = MultipartFile.fromBytes(e.signatureAttachment!.bytes, filename: e.signatureAttachment!.name);
    }
    return FormData.fromMap(map);
  }

  Future<IdCardTemplateEntity> createIdCardTemplate(IdCardTemplateEntity e) async {
    final response = await _dioClient.post('/api/v1/admissions/id-card-templates/', data: _idCardPayload(e));
    return IdCardTemplateEntity.fromJson(_unwrap(response.data));
  }

  Future<IdCardTemplateEntity> updateIdCardTemplate(int id, IdCardTemplateEntity e) async {
    final response = await _dioClient.patch('/api/v1/admissions/id-card-templates/$id/', data: _idCardPayload(e));
    return IdCardTemplateEntity.fromJson(_unwrap(response.data));
  }

  Future<void> deleteIdCardTemplate(int id) async {
    await _dioClient.delete('/api/v1/admissions/id-card-templates/$id/');
  }

  Future<DocumentGenerateSetup> getIdCardGenerateSetup() async {
    final response = await _dioClient.get('/api/v1/admissions/id-card-templates/generate-setup/');
    return DocumentGenerateSetup.fromJson(response.data as Map<String, dynamic>);
  }

  /// `page_size: 100` is explicit, not part of the web contract — the
  /// student-role branch of this endpoint paginates server-side at the
  /// default `page_size=10` (`ApiPageNumberPagination`), and neither web
  /// nor a bare call here would ever see more than the first 10
  /// alphabetical students for a class with more than that. Passing the
  /// server's own `max_page_size=100` avoids that truncation without
  /// changing anything for classes under the cap.
  Future<RecipientsResult> getIdCardRecipients({required int role, int? classId, int? sectionId}) async {
    final response = await _dioClient.get(
      '/api/v1/admissions/id-card-templates/recipients/',
      queryParameters: {
        'role': role,
        'page_size': 100,
        'class': ?classId,
        'section': ?sectionId,
      },
    );
    return RecipientsResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Documents Studio: Certificate Templates ──────────────────────────
  Future<PaginatedResult<CertificateTemplateEntity>> getCertificateTemplates({int page = 1, int pageSize = 10}) async {
    final response = await _dioClient.get(
      '/api/v1/admissions/certificate-templates/',
      queryParameters: _pageParams(page, pageSize),
    );
    return PaginatedResult.fromJson(response.data, CertificateTemplateEntity.fromJson);
  }

  dynamic _certificatePayload(CertificateTemplateEntity e) {
    if (e.backgroundAttachment == null) return e.toJson();
    return FormData.fromMap({
      ...e.toJson().map((key, value) => MapEntry(key, value.toString())),
      'background_upload': MultipartFile.fromBytes(e.backgroundAttachment!.bytes, filename: e.backgroundAttachment!.name),
    });
  }

  Future<CertificateTemplateEntity> createCertificateTemplate(CertificateTemplateEntity e) async {
    final response = await _dioClient.post('/api/v1/admissions/certificate-templates/', data: _certificatePayload(e));
    return CertificateTemplateEntity.fromJson(_unwrap(response.data));
  }

  Future<CertificateTemplateEntity> updateCertificateTemplate(int id, CertificateTemplateEntity e) async {
    final response = await _dioClient.patch('/api/v1/admissions/certificate-templates/$id/', data: _certificatePayload(e));
    return CertificateTemplateEntity.fromJson(_unwrap(response.data));
  }

  Future<void> deleteCertificateTemplate(int id) async {
    await _dioClient.delete('/api/v1/admissions/certificate-templates/$id/');
  }

  Future<DocumentGenerateSetup> getCertificateGenerateSetup() async {
    final response = await _dioClient.get('/api/v1/admissions/certificate-templates/generate-setup/');
    return DocumentGenerateSetup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecipientsResult> getCertificateRecipients({required int role, int? classId, int? sectionId}) async {
    final response = await _dioClient.get(
      '/api/v1/admissions/certificate-templates/recipients/',
      queryParameters: {
        'role': role,
        'class': ?classId,
        'section': ?sectionId,
      },
    );
    return RecipientsResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Roles (shared role picker for ID Card / Certificate forms) ──────
  /// `RoleViewSet` paginates at `ApiPageNumberPagination`'s default
  /// `page_size=10` — with 33 real roles across all schools (confirmed live),
  /// an unpaginated request silently returned only the first 10, which is
  /// exactly why the client-side school-scoping filter in
  /// `administration_provider.dart` appeared to "lose" most roles: it was
  /// filtering an already-truncated page, not the full list. `page_size=100`
  /// is the server's own `max_page_size`, comfortably covering the real
  /// total.
  Future<List<RoleEntity>> getRoles() async {
    final response = await _dioClient.get('/api/v1/access-control/roles/', queryParameters: {'page_size': 100});
    final data = response.data;
    final list = data is List ? data : (data as Map<String, dynamic>)['results'] as List? ?? const [];
    return list.map((e) => RoleEntity.fromJson(e as Map<String, dynamic>)).toList();
  }
}
