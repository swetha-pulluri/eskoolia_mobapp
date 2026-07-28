import 'package:dio/dio.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../administration/domain/entities/paginated_result.dart';
import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/attendance_daily_summary_entity.dart';
import '../../domain/entities/attendance_import_result_entity.dart';
import '../../domain/entities/attendance_monthly_report_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/department_type_entity.dart';
import '../../domain/entities/designation_entity.dart';
import '../../domain/entities/master_option_entity.dart';
import '../../domain/entities/onboard_document_entity.dart';
import '../../domain/entities/onboard_draft_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_files_draft.dart';
import '../../domain/entities/staff_form_options_entity.dart';
import '../../domain/entities/staff_lite_entity.dart';
import '../../domain/repositories/hr_repository.dart';

/// HR Remote Data Source — calls the ACTUAL currently-running backend
/// endpoints under `apps/hr` (verified read-only against the live local
/// server: `departments`, `designations`, `staff` only — no
/// `department-types` or `designations/reorder/`, which exist only on the
/// unmerged `demo` branch and are NOT part of this API).
///
/// Department/Designation create/update/delete return
/// `{"success", "message", "data"}` — unwrapped via [_unwrap]. List
/// endpoints return the raw DRF paginated envelope `{count, next, previous,
/// results}`.
class HrRemoteDataSource {
  final DioClient _dioClient;

  HrRemoteDataSource(this._dioClient);

  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final data = map['data'];
    if (data is Map<String, dynamic>) return data;
    return map;
  }

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      // Onboard draft endpoints use a simpler `{"error": "<message>"}` shape
      // rather than the ViewSet-based `{"success","message","errors"}`
      // envelope used everywhere else in this API. Some error bodies (e.g.
      // DRF's default `{"detail": "..."}` for permission/auth failures, or
      // a nested validation object) put a non-string value under
      // `message`/`error` — coerce rather than blind-cast, which used to
      // crash with a confusing `_JsonMap is not a subtype of String?`
      // TypeError that masked the real backend error entirely.
      final rawMessage = data['message'] ?? data['error'] ?? data['detail'];
      // Some error bodies nest a `{"code": "...", "message": "..."}` object
      // under `error` (e.g. a generic 500 envelope) rather than a bare
      // string — pull the real message out instead of falling through to
      // `.toString()`, which used to render the raw Dart Map literally
      // (`{code: internal_server_error, message: ...}`) as the shown error.
      final String? message;
      if (rawMessage is String) {
        message = rawMessage;
      } else if (rawMessage is Map && rawMessage['message'] is String) {
        message = rawMessage['message'] as String;
      } else {
        message = rawMessage?.toString();
      }
      final rawErrors = data['errors'];
      final fieldErrors = <String, String>{};
      if (rawErrors is Map) {
        rawErrors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            fieldErrors[key.toString()] = value.first.toString();
          } else if (value is String) {
            fieldErrors[key.toString()] = value;
          }
        });
      }
      if (message != null) throw HrApiException(message, fieldErrors);
    }
    throw HrApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  // ─── Departments ──────────────────────────────────────────────────────

  Future<PaginatedResult<DepartmentEntity>> _getDepartmentsPage({required int page, required int pageSize}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/departments/',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      return PaginatedResult.fromJson(response.data, DepartmentEntity.fromJson);
    } on DioException catch (e) {
      AppLogger.error('Get departments error', e);
      _throwApiException(e);
    }
  }

  Future<PaginatedResult<DepartmentEntity>> getDepartments({required int page, int pageSize = 10}) {
    return _getDepartmentsPage(page: page, pageSize: pageSize);
  }

  Future<PaginatedResult<DepartmentEntity>> getAllDepartments() {
    return _getDepartmentsPage(page: 1, pageSize: 200);
  }

  Future<PaginatedResult<DepartmentEntity>> getHierarchyDepartments({required int page}) {
    return _getDepartmentsPage(page: page, pageSize: 5);
  }

  Future<DepartmentEntity> createDepartment(DepartmentEntity draft) async {
    try {
      final response = await _dioClient.post('/api/v1/hr/departments/', data: draft.toJson());
      return DepartmentEntity.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<DepartmentEntity> updateDepartment(int id, DepartmentEntity draft) async {
    try {
      final response = await _dioClient.patch('/api/v1/hr/departments/$id/', data: draft.toJson());
      return DepartmentEntity.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      await _dioClient.delete('/api/v1/hr/departments/$id/');
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<List<DepartmentTypeEntity>> getDepartmentTypes() async {
    try {
      final response = await _dioClient.get('/api/v1/hr/department-types/');
      final data = response.data as Map<String, dynamic>;
      final list = (data['data'] as List?) ?? const [];
      return list.map((e) => DepartmentTypeEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get department types error', e);
      _throwApiException(e);
    }
  }

  Future<DepartmentTypeEntity> createDepartmentType(String name) async {
    try {
      final response = await _dioClient.post('/api/v1/hr/department-types/', data: {'name': name});
      return DepartmentTypeEntity.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  // ─── Staff (Staff Assigned KPI only) ───────────────────────────────────

  Future<PaginatedResult<StaffLiteEntity>> getActiveStaff() async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/staff/',
        queryParameters: {'page_size': 200, 'status': 'active'},
      );
      return PaginatedResult.fromJson(response.data, StaffLiteEntity.fromJson);
    } on DioException catch (e) {
      AppLogger.error('Get staff error', e);
      _throwApiException(e);
    }
  }

  // ─── Designations ─────────────────────────────────────────────────────

  Future<PaginatedResult<DesignationEntity>> getDesignations({int? departmentId}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/designations/',
        queryParameters: {
          'page_size': 200,
          'department': ?departmentId,
        },
      );
      return PaginatedResult.fromJson(response.data, DesignationEntity.fromJson);
    } on DioException catch (e) {
      AppLogger.error('Get designations error', e);
      _throwApiException(e);
    }
  }

  Future<DesignationEntity> createDesignation(DesignationEntity draft) async {
    try {
      final response = await _dioClient.post('/api/v1/hr/designations/', data: draft.toJson());
      return DesignationEntity.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<DesignationEntity> updateDesignation(int id, DesignationEntity draft) async {
    try {
      final response = await _dioClient.patch('/api/v1/hr/designations/$id/', data: draft.toJson());
      return DesignationEntity.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<void> deleteDesignation(int id) async {
    try {
      await _dioClient.delete('/api/v1/hr/designations/$id/');
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  // ─── Staff Directory & Onboarding ───────────────────────────────────

  Future<PaginatedResult<StaffEntity>> getStaffPage({
    required int page,
    required int pageSize,
    String? search,
    int? roleId,
    int? departmentId,
    int? designationId,
    String? status,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/staff/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          'role': ?roleId,
          'department': ?departmentId,
          'designation': ?designationId,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return PaginatedResult.fromJson(response.data, StaffEntity.fromJson);
    } on DioException catch (e) {
      AppLogger.error('Get staff page error', e);
      _throwApiException(e);
    }
  }

  Future<StaffEntity> getStaffById(int id) async {
    try {
      final response = await _dioClient.get('/api/v1/hr/staff/$id/');
      return StaffEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  /// Matches web's rule exactly: send JSON unless a file was picked, in
  /// which case rebuild the whole payload as multipart `FormData`, with
  /// the picked files overwriting their corresponding string fields.
  dynamic _staffPayload(StaffEntity draft, StaffFilesDraft files, List<PickedOtherDocument> otherDocuments) {
    final json = draft.toJson();
    json['other_document'] = otherDocuments.map((d) => d.name).toList();
    if (!files.hasAnyFile) return json;

    final map = <String, dynamic>{};
    json.forEach((key, value) {
      if (value == null) return;
      if (key == 'custom_field') {
        map[key] = value is Map ? _jsonEncodeMap(value) : value.toString();
      } else if (value is bool || value is num) {
        map[key] = value.toString();
      } else if (value is List) {
        map[key] = value.map((e) => e.toString()).toList();
      } else {
        map[key] = value.toString();
      }
    });
    if (files.staffPhoto != null) map['staff_photo'] = MultipartFile.fromBytes(files.staffPhoto!.bytes, filename: files.staffPhoto!.name);
    if (files.resume != null) map['resume'] = MultipartFile.fromBytes(files.resume!.bytes, filename: files.resume!.name);
    if (files.joiningLetter != null) map['joining_letter'] = MultipartFile.fromBytes(files.joiningLetter!.bytes, filename: files.joiningLetter!.name);
    if (files.tenthCertificate != null) map['tenth_certificate'] = MultipartFile.fromBytes(files.tenthCertificate!.bytes, filename: files.tenthCertificate!.name);
    if (files.eleventhCertificate != null) map['eleventh_certificate'] = MultipartFile.fromBytes(files.eleventhCertificate!.bytes, filename: files.eleventhCertificate!.name);
    if (files.aadharCard != null) map['aadhar_card'] = MultipartFile.fromBytes(files.aadharCard!.bytes, filename: files.aadharCard!.name);
    if (files.drivingLicenseDoc != null) map['driving_license_doc'] = MultipartFile.fromBytes(files.drivingLicenseDoc!.bytes, filename: files.drivingLicenseDoc!.name);
    return FormData.fromMap(map);
  }

  String _jsonEncodeMap(Map value) {
    final buffer = StringBuffer('{');
    var first = true;
    value.forEach((k, v) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"$k":${v is String ? '"$v"' : v}');
    });
    buffer.write('}');
    return buffer.toString();
  }

  Future<StaffEntity> createStaff(StaffEntity draft, {StaffFilesDraft files = const StaffFilesDraft(), List<PickedOtherDocument> otherDocuments = const []}) async {
    try {
      final response = await _dioClient.post('/api/v1/hr/staff/', data: _staffPayload(draft, files, otherDocuments));
      return StaffEntity.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<StaffEntity> updateStaff(int id, StaffEntity draft, {StaffFilesDraft files = const StaffFilesDraft(), List<PickedOtherDocument> otherDocuments = const []}) async {
    try {
      final response = await _dioClient.patch('/api/v1/hr/staff/$id/', data: _staffPayload(draft, files, otherDocuments));
      return StaffEntity.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<void> deleteStaff(int id) async {
    try {
      await _dioClient.delete('/api/v1/hr/staff/$id/');
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<void> updateStaffStatus(int id, String status) async {
    try {
      await _dioClient.patch('/api/v1/hr/staff/$id/', data: {'status': status});
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<StaffFormOptionsEntity> getStaffFormOptions() async {
    try {
      final response = await _dioClient.get('/api/v1/hr/staff/form-options/');
      final data = response.data as Map<String, dynamic>;
      return StaffFormOptionsEntity.fromJson((data['data'] as Map<String, dynamic>?) ?? const {});
    } on DioException catch (e) {
      AppLogger.error('Get staff form options error', e);
      _throwApiException(e);
    }
  }

  Future<String> getNextStaffNo() async {
    try {
      final response = await _dioClient.get('/api/v1/hr/staff/next-staff-no/');
      final data = response.data as Map<String, dynamic>;
      return data['staff_no']?.toString() ?? '';
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<List<RoleEntity>> getRoles() async {
    try {
      final response = await _dioClient.get('/api/v1/access-control/roles/');
      final data = response.data;
      final list = data is Map<String, dynamic> ? (data['results'] as List? ?? data['data'] as List? ?? const []) : (data as List);
      return list.map((e) => RoleEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get roles error', e);
      _throwApiException(e);
    }
  }

  // ─── Staff Attendance ───────────────────────────────────────────────

  Future<PaginatedResult<StaffAttendanceEntity>> getAttendanceForDate(String date) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/staff-attendance/',
        queryParameters: {'attendance_date': date, 'page_size': 500},
      );
      return PaginatedResult.fromJson(response.data, StaffAttendanceEntity.fromJson);
    } on DioException catch (e) {
      AppLogger.error('Get attendance for date error', e);
      _throwApiException(e);
    }
  }

  Future<PaginatedResult<StaffAttendanceEntity>> getAllAttendance() async {
    try {
      final response = await _dioClient.get('/api/v1/hr/staff-attendance/', queryParameters: {'page_size': 1000});
      return PaginatedResult.fromJson(response.data, StaffAttendanceEntity.fromJson);
    } on DioException catch (e) {
      AppLogger.error('Get all attendance error', e);
      _throwApiException(e);
    }
  }

  Future<int> bulkSaveAttendance(List<StaffAttendanceEntity> rows) async {
    try {
      final response = await _dioClient.post(
        '/api/v1/hr/staff-attendance/bulk-store/',
        data: {'rows': rows.map((r) => r.toJson()).toList()},
      );
      final data = response.data as Map<String, dynamic>;
      return data['count'] as int? ?? rows.length;
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<AttendanceReportEntity> getAttendanceReport({String? attendanceDate}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/staff-attendance/report/',
        queryParameters: {'attendance_date': ?attendanceDate},
      );
      return AttendanceReportEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get attendance report error', e);
      _throwApiException(e);
    }
  }

  Future<AttendanceDailySummaryEntity> getDailySummary({required String date, int? departmentId}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/staff-attendance/daily-summary/',
        queryParameters: {'date': date, 'department': ?departmentId},
      );
      return AttendanceDailySummaryEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get daily summary error', e);
      _throwApiException(e);
    }
  }

  Future<AttendanceMonthlyReportEntity> getMonthlyReport({required int month, required int year, int? departmentId, int? staffId}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/staff-attendance/monthly-report/',
        queryParameters: {
          'month': month,
          'year': year,
          'department': ?departmentId,
          'staff': ?staffId,
        },
      );
      return AttendanceMonthlyReportEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get monthly report error', e);
      _throwApiException(e);
    }
  }

  Future<List<int>> downloadSampleAttendance() async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/staff-attendance/download-sample/',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      AppLogger.error('Download sample attendance error', e);
      _throwApiException(e);
    }
  }

  Future<List<int>> exportAttendance({String? date, String? department, String? attendanceType, String fmt = 'xlsx'}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/staff-attendance/export/',
        queryParameters: {
          'fmt': fmt,
          'date': ?date,
          if (department != null && department != 'all') 'department': department,
          if (attendanceType != null && attendanceType != 'all') 'attendance_type': attendanceType,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      AppLogger.error('Export attendance error', e);
      _throwApiException(e);
    }
  }

  Future<AttendanceImportResultEntity> importAttendance({required String attendanceDate, required PickedAttachment file}) async {
    try {
      final formData = FormData.fromMap({
        'attendance_date': attendanceDate,
        'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
      });
      final response = await _dioClient.post('/api/v1/hr/staff-attendance/import/', data: formData);
      return AttendanceImportResultEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  // ─── Staff Onboarding Wizard ─────────────────────────────────────────

  Future<List<OnboardDraftEntity>> getOnboardDrafts() async {
    try {
      final response = await _dioClient.get('/api/v1/hr/onboard/drafts/');
      final data = response.data as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      return results.map((e) => OnboardDraftEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get onboard drafts error', e);
      _throwApiException(e);
    }
  }

  /// The real `StaffOnboardDraftSaveView` returns the saved draft's plain
  /// serializer data directly — no `{success,data}` envelope (unlike the
  /// rest of this API) — so this deliberately does NOT call [_unwrap].
  Future<OnboardDraftEntity> saveOnboardDraft({int? id, required Map<String, dynamic> formData, required int currentStep}) async {
    try {
      final response = await _dioClient.post(
        '/api/v1/hr/onboard/drafts/save/',
        data: {'id': id, 'form_data': formData, 'current_step': currentStep},
      );
      return OnboardDraftEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<void> deleteOnboardDraft(int id) async {
    try {
      await _dioClient.delete('/api/v1/hr/onboard/drafts/$id/');
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<List<int>> downloadBlankForm({int copies = 1}) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/onboard/blank-form/',
        queryParameters: {'copies': copies},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      AppLogger.error('Download blank onboarding form error', e);
      _throwApiException(e);
    }
  }

  Future<List<int>> downloadFilledForm(Map<String, dynamic> formData) async {
    try {
      final response = await _dioClient.post(
        '/api/v1/hr/onboard/filled-form/',
        data: {'form_data': formData},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      AppLogger.error('Download filled onboarding form error', e);
      _throwApiException(e);
    }
  }

  Future<OnboardDocumentEntity> uploadOnboardDocument({required PickedAttachment file, required String docKey, required String docLabel}) async {
    try {
      final formData = FormData.fromMap({
        'doc_key': docKey,
        'doc_label': docLabel,
        'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
      });
      final response = await _dioClient.post('/api/v1/hr/onboard/documents/upload/', data: formData);
      return OnboardDocumentEntity.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<List<OnboardDocumentEntity>> getOnboardDocuments() async {
    try {
      final response = await _dioClient.get('/api/v1/hr/onboard/documents/');
      final data = response.data as Map<String, dynamic>;
      final list = (data['data'] as List?) ?? const [];
      return list.map((e) => OnboardDocumentEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get onboard documents error', e);
      _throwApiException(e);
    }
  }

  Future<void> deleteOnboardDocument(int id) async {
    try {
      await _dioClient.delete('/api/v1/hr/onboard/documents/$id/');
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<List<int>> previewOnboardDocument(int id) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/hr/onboard/documents/$id/preview/',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<List<MasterOptionEntity>> _getMasterList(String path) async {
    try {
      final response = await _dioClient.get(path);
      final list = response.data as List;
      return list.map((e) => MasterOptionEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get master list error: $path', e);
      _throwApiException(e);
    }
  }

  Future<List<MasterOptionEntity>> getMasterLanguages() => _getMasterList('/api/v1/master/languages/');

  Future<List<MasterOptionEntity>> getMasterReligions() => _getMasterList('/api/v1/master/religions/');

  Future<List<MasterOptionEntity>> getMasterCountries() => _getMasterList('/api/v1/master/countries/');

  Future<List<MasterOptionEntity>> getMasterEmploymentTypes() => _getMasterList('/api/v1/master/employment-types/');

  Future<PincodeLookupResult> lookupPincode(String pincode) async {
    try {
      final response = await _dioClient.get('/api/v1/core/pincode-lookup/', queryParameters: {'pincode': pincode});
      return PincodeLookupResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }
}
