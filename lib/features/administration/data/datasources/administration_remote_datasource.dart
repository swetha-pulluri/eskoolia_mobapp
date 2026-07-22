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

  // ─── Visitor Book ─────────────────────────────────────────────────────
  Future<PaginatedResult<VisitorEntity>> getVisitors({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/admissions/visitors/',
        queryParameters: _pageParams(page, pageSize),
      );
      return PaginatedResult.fromJson(response.data, VisitorEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get visitors error', e);
      rethrow;
    }
  }

  Future<VisitorEntity> createVisitor(VisitorEntity visitor) async {
    final response = await _dioClient.post('/api/v1/admissions/visitors/', data: await _visitorPayload(visitor));
    return VisitorEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VisitorEntity> updateVisitor(int id, VisitorEntity visitor) async {
    final response = await _dioClient.patch('/api/v1/admissions/visitors/$id/', data: await _visitorPayload(visitor));
    return VisitorEntity.fromJson(response.data as Map<String, dynamic>);
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
  Future<PaginatedResult<ComplaintEntity>> getComplaints({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/admissions/complaints/',
        queryParameters: _pageParams(page, pageSize),
      );
      return PaginatedResult.fromJson(response.data, ComplaintEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get complaints error', e);
      rethrow;
    }
  }

  Future<ComplaintEntity> createComplaint(ComplaintEntity complaint) async {
    final response = await _dioClient.post('/api/v1/admissions/complaints/', data: complaint.toJson());
    return ComplaintEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ComplaintEntity> updateComplaint(int id, ComplaintEntity complaint) async {
    final response = await _dioClient.patch('/api/v1/admissions/complaints/$id/', data: complaint.toJson());
    return ComplaintEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteComplaint(int id) async {
    await _dioClient.delete('/api/v1/admissions/complaints/$id/');
  }

  // ─── Phone Call Log ────────────────────────────────────────────────────
  Future<PaginatedResult<PhoneCallEntity>> getPhoneCalls({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/admissions/phone-call-logs/',
        queryParameters: _pageParams(page, pageSize),
      );
      return PaginatedResult.fromJson(response.data, PhoneCallEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get phone call logs error', e);
      rethrow;
    }
  }

  Future<PhoneCallEntity> createPhoneCall(PhoneCallEntity call) async {
    final response = await _dioClient.post('/api/v1/admissions/phone-call-logs/', data: call.toJson());
    return PhoneCallEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PhoneCallEntity> updatePhoneCall(int id, PhoneCallEntity call) async {
    final response = await _dioClient.patch('/api/v1/admissions/phone-call-logs/$id/', data: call.toJson());
    return PhoneCallEntity.fromJson(response.data as Map<String, dynamic>);
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

  Future<AdminSetupEntity> createAdminSetup(AdminSetupEntity entry) async {
    final response = await _dioClient.post('/api/v1/admissions/admin-setups/', data: entry.toJson());
    return AdminSetupEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminSetupEntity> updateAdminSetup(int id, AdminSetupEntity entry) async {
    final response = await _dioClient.patch('/api/v1/admissions/admin-setups/$id/', data: entry.toJson());
    return AdminSetupEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAdminSetup(int id) async {
    await _dioClient.delete('/api/v1/admissions/admin-setups/$id/');
  }

  // ─── Postal Received ───────────────────────────────────────────────────
  Future<PaginatedResult<PostalReceiveEntity>> getPostalReceives({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/admissions/postal-receive/',
        queryParameters: _pageParams(page, pageSize),
      );
      return PaginatedResult.fromJson(response.data, PostalReceiveEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get postal receive error', e);
      rethrow;
    }
  }

  Future<PostalReceiveEntity> createPostalReceive(PostalReceiveEntity entry) async {
    final response = await _dioClient.post('/api/v1/admissions/postal-receive/', data: entry.toJson());
    return PostalReceiveEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostalReceiveEntity> updatePostalReceive(int id, PostalReceiveEntity entry) async {
    final response = await _dioClient.patch('/api/v1/admissions/postal-receive/$id/', data: entry.toJson());
    return PostalReceiveEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePostalReceive(int id) async {
    await _dioClient.delete('/api/v1/admissions/postal-receive/$id/');
  }

  // ─── Postal Dispatched ─────────────────────────────────────────────────
  Future<PaginatedResult<PostalDispatchEntity>> getPostalDispatches({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/admissions/postal-dispatch/',
        queryParameters: _pageParams(page, pageSize),
      );
      return PaginatedResult.fromJson(response.data, PostalDispatchEntity.fromJson);
    } catch (e) {
      AppLogger.error('Get postal dispatch error', e);
      rethrow;
    }
  }

  Future<PostalDispatchEntity> createPostalDispatch(PostalDispatchEntity entry) async {
    final response = await _dioClient.post('/api/v1/admissions/postal-dispatch/', data: entry.toJson());
    return PostalDispatchEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostalDispatchEntity> updatePostalDispatch(int id, PostalDispatchEntity entry) async {
    final response = await _dioClient.patch('/api/v1/admissions/postal-dispatch/$id/', data: entry.toJson());
    return PostalDispatchEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePostalDispatch(int id) async {
    await _dioClient.delete('/api/v1/admissions/postal-dispatch/$id/');
  }

  // ─── Student Categories ────────────────────────────────────────────────
  Future<PaginatedResult<StudentCategoryEntity>> getStudentCategories({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/students/categories/',
        queryParameters: {
          ..._pageParams(page, pageSize),
          if (status != null && status.isNotEmpty) 'status': status,
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
    return StudentCategoryEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentCategoryEntity> updateStudentCategory(int id, StudentCategoryEntity category) async {
    final response = await _dioClient.patch('/api/v1/students/categories/$id/', data: category.toJson());
    return StudentCategoryEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteStudentCategory(int id) async {
    await _dioClient.delete('/api/v1/students/categories/$id/');
  }
}
