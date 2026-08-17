import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../../administration/domain/entities/paginated_result.dart';
import '../../domain/entities/staff_attendance_report_row_entity.dart';
import '../../domain/entities/student_attendance_report_row_entity.dart';
import '../../domain/repositories/reports_api_exception.dart';

/// Calls the real `apps.reports` endpoints (`backend/apps/reports/urls.py`,
/// `backend/apps/reports/views.py`) — the same two report endpoints the
/// web app's `app/(dashboard)/reports/student-attendance/page.tsx` and
/// `.../staff-attendance/page.tsx` actually call (the other 11 report
/// pages in the web nav are still "Coming Soon" there — no backend work
/// has been done for them, so nothing is ported here for those).
///
/// Query params are `start_date`/`end_date` (NOT `date_from`/`date_to` —
/// the web pages themselves get this right even though the doc-comment
/// naming elsewhere in the app uses date_from/date_to for other modules).
/// Response envelope is `{count, page, page_size, total_pages, results}`
/// (`BaseReportAPIView.get()`); only `count`/`results` are actually needed
/// here since `total_pages` is derived client-side the same way the Audit
/// Log page already does it.
class ReportsRemoteDataSource {
  final DioClient _dioClient;
  static const int pageSize = 20;

  ReportsRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) throw ReportsApiException(rawMessage);
      if (rawMessage != null && rawMessage.toString().trim().isNotEmpty) throw ReportsApiException(rawMessage.toString());
    }
    // `e.message` can be a non-null EMPTY string for some Dio error types
    // (e.g. certain connection errors), which `??` alone doesn't catch —
    // that previously produced a `ReportsApiException` with a blank
    // message, rendering as an invisible (but present) error line with no
    // visible feedback and nothing logged beyond this point.
    final fallback = e.message;
    final status = e.response?.statusCode;
    throw ReportsApiException(
      (fallback != null && fallback.trim().isNotEmpty)
          ? fallback
          : (status != null ? 'Request failed (HTTP $status).' : 'Something went wrong. Please try again.'),
    );
  }

  Map<String, dynamic> _studentAttendanceParams({
    int? classId,
    int? sectionId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) {
    return {
      if (classId != null) 'class_id': classId,
      if (sectionId != null) 'section_id': sectionId,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (attendanceType != null && attendanceType.isNotEmpty) 'attendance_type': attendanceType,
    };
  }

  Future<PaginatedResult<StudentAttendanceReportRowEntity>> getStudentAttendanceReport({
    required int page,
    int? classId,
    int? sectionId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/reports/students/attendance/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          ..._studentAttendanceParams(classId: classId, sectionId: sectionId, startDate: startDate, endDate: endDate, attendanceType: attendanceType),
        },
      );
      return PaginatedResult.fromJson(response.data, StudentAttendanceReportRowEntity.fromJson);
    } on DioException catch (e) {
      AppLogger.error('Get student attendance report error', e);
      _throwApiException(e);
    }
  }

  Future<List<int>> exportStudentAttendanceReportCsv({
    int? classId,
    int? sectionId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/reports/students/attendance/',
        queryParameters: {
          'export': 'csv',
          ..._studentAttendanceParams(classId: classId, sectionId: sectionId, startDate: startDate, endDate: endDate, attendanceType: attendanceType),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      AppLogger.error('Export student attendance report error', e);
      _throwApiException(e);
    }
  }

  Map<String, dynamic> _staffAttendanceParams({
    int? departmentId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) {
    return {
      if (departmentId != null) 'department_id': departmentId,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (attendanceType != null && attendanceType.isNotEmpty) 'attendance_type': attendanceType,
    };
  }

  Future<PaginatedResult<StaffAttendanceReportRowEntity>> getStaffAttendanceReport({
    required int page,
    int? departmentId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/reports/hr/staff-attendance/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          ..._staffAttendanceParams(departmentId: departmentId, startDate: startDate, endDate: endDate, attendanceType: attendanceType),
        },
      );
      return PaginatedResult.fromJson(response.data, StaffAttendanceReportRowEntity.fromJson);
    } on DioException catch (e) {
      AppLogger.error('Get staff attendance report error', e);
      _throwApiException(e);
    }
  }

  Future<List<int>> exportStaffAttendanceReportCsv({
    int? departmentId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/reports/hr/staff-attendance/',
        queryParameters: {
          'export': 'csv',
          ..._staffAttendanceParams(departmentId: departmentId, startDate: startDate, endDate: endDate, attendanceType: attendanceType),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      AppLogger.error('Export staff attendance report error', e);
      _throwApiException(e);
    }
  }

  // ── Generic Report Explorer engine — mirrors web's `ReportExplorer.tsx`
  // (data fetch + export), backing the 29 report definitions in
  // `report_definition_entity.dart`. Rows are returned as raw maps since
  // none of the 29 real definitions specify explicit columns — the UI
  // auto-derives columns from the first row's keys, exactly like web does.

  Future<Map<String, dynamic>> getReportPage(String endpoint, {required int page, required Map<String, dynamic> filters}) async {
    try {
      // Same explicit client-side bound as `_fetchLookupOptions` below —
      // confirmed via a real timeout log that at least one of these
      // `apps.reports` endpoints (`/api/v1/core/sections/`, a lookup, not
      // this method) can hang well past `DioClient`'s own configured
      // timeout; report endpoints get the identical guard rather than
      // risking the same silent hang.
      final response = await _dioClient.get(endpoint, queryParameters: {'page': page, 'page_size': pageSize, ...filters}).timeout(const Duration(seconds: 45));
      final data = response.data;
      return data is Map<String, dynamic> ? data : {'count': 0, 'results': const []};
    } on DioException catch (e) {
      AppLogger.error('Get report page error ($endpoint)', e);
      _throwApiException(e);
    } on TimeoutException catch (e) {
      AppLogger.error('Get report page timed out ($endpoint)', e);
      throw const ReportsApiException('The report server took too long to respond — please try again.');
    }
  }

  Future<List<int>> exportReport(String endpoint, String format, Map<String, dynamic> filters) async {
    try {
      final response = await _dioClient
          .get(
            endpoint,
            queryParameters: {'export': format, ...filters},
            options: Options(responseType: ResponseType.bytes),
          )
          .timeout(const Duration(seconds: 60));
      return response.data as List<int>;
    } on DioException catch (e) {
      AppLogger.error('Export report error ($endpoint)', e);
      _throwApiException(e);
    } on TimeoutException catch (e) {
      AppLogger.error('Export report timed out ($endpoint)', e);
      throw const ReportsApiException('The export took too long to complete — please try again.');
    }
  }

  Future<List<(int, String)>> _fetchLookupOptions(
    String path, {
    Map<String, dynamic>? queryParameters,
    required String Function(Map<String, dynamic>) label,
  }) async {
    try {
      // Explicit client-side bound in addition to `DioClient`'s own
      // connect/receive timeouts — a filter dropdown that never resolves
      // (a stuck spinner forever) is worse than one that gives up and
      // shows "no options" after a bounded wait, regardless of what's
      // actually stalling server-side.
      final response = await _dioClient.get(path, queryParameters: {'page_size': 500, ...?queryParameters}).timeout(const Duration(seconds: 45));
      final data = response.data;
      final list = data is Map<String, dynamic> ? (data['results'] as List? ?? const []) : (data as List? ?? const []);
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        final id = map['id'];
        return (id is int ? id : int.tryParse('$id') ?? 0, label(map));
      }).toList();
    } on DioException catch (e) {
      AppLogger.error('Get lookup options error ($path)', e);
      _throwApiException(e);
    } on TimeoutException catch (e) {
      AppLogger.error('Get lookup options timed out ($path)', e);
      throw const ReportsApiException('Timed out loading options — please try again.');
    }
  }

  Future<List<(int, String)>> getClassOptions() => _fetchLookupOptions('/api/v1/core/classes/', label: (m) => m['name'] as String? ?? '');

  /// Sections lookup accepts `class` (NOT `class_id`, unlike the report
  /// endpoints themselves) — verified against `SectionViewSet.get_queryset`
  /// (`apps/core/views.py`).
  Future<List<(int, String)>> getSectionOptions({int? classId}) => _fetchLookupOptions(
        '/api/v1/core/sections/',
        queryParameters: classId != null ? {'class': classId} : null,
        label: (m) => m['name'] as String? ?? '',
      );

  /// Students lookup accepts `class`/`section` (NOT `class_id`/
  /// `section_id`) — verified against `StudentViewSet`
  /// (`apps/students/views.py`). No single `full_name` field on this
  /// serializer — built from first/last name.
  Future<List<(int, String)>> getStudentOptions({int? classId, int? sectionId}) => _fetchLookupOptions(
        '/api/v1/students/students/',
        queryParameters: {
          'is_active': true,
          if (classId != null) 'class': classId,
          if (sectionId != null) 'section': sectionId,
        },
        label: (m) => '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim(),
      );

  Future<List<(int, String)>> getSubjectOptions() => _fetchLookupOptions('/api/v1/core/subjects/', label: (m) => m['name'] as String? ?? '');

  /// The report filter labeled "Exam" (`exam_term_id`) is actually a FK to
  /// `ExamType`, not `Exam` — sourced from `GET /api/v1/exams/types/`
  /// (field `title`), matching `ExamMarkRegister.exam_term`'s real target
  /// model. Web's own config incorrectly sources this from `/exams/exams/`.
  Future<List<(int, String)>> getExamTypeOptions() => _fetchLookupOptions('/api/v1/exams/types/', label: (m) => m['title'] as String? ?? '');

  Future<List<(int, String)>> getDepartmentOptions() => _fetchLookupOptions('/api/v1/hr/departments/', label: (m) => m['name'] as String? ?? '');

  /// Designations lookup accepts `department` (NOT `department_id`) —
  /// verified against `DesignationViewSet.filterset_fields`.
  Future<List<(int, String)>> getDesignationOptions({int? departmentId}) => _fetchLookupOptions(
        '/api/v1/hr/designations/',
        queryParameters: departmentId != null ? {'department': departmentId} : null,
        label: (m) => m['name'] as String? ?? '',
      );

  /// Staff lookup accepts `department`/`designation` (NOT
  /// `department_id`/`designation_id`) — verified against
  /// `StaffViewSet.filterset_fields`. No `full_name` on this serializer
  /// either — built from first/last name.
  Future<List<(int, String)>> getStaffOptions({int? departmentId, int? designationId}) => _fetchLookupOptions(
        '/api/v1/hr/staff/',
        queryParameters: {
          if (departmentId != null) 'department': departmentId,
          if (designationId != null) 'designation': designationId,
        },
        label: (m) => '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim(),
      );

  Future<List<(int, String)>> getRouteOptions() => _fetchLookupOptions('/api/v1/core/transport-routes/', label: (m) => m['title'] as String? ?? '');

  /// No route-based filter exists server-side for vehicles
  /// (`VehicleViewSet` has none) — always the full list, unlike web's
  /// config, which assumes a route→vehicle cascade the backend can't do.
  Future<List<(int, String)>> getVehicleOptions() => _fetchLookupOptions(
        '/api/v1/core/vehicles/',
        label: (m) => [m['vehicle_no'], if (m['vehicle_model'] != null) '(${m['vehicle_model']})'].where((s) => s != null && s.toString().isNotEmpty).join(' '),
      );

  Future<List<(int, String)>> getBookOptions() => _fetchLookupOptions('/api/v1/library/books/', label: (m) => m['title'] as String? ?? '');

  Future<List<(int, String)>> getCategoryOptions() => _fetchLookupOptions('/api/v1/core/item-categories/', label: (m) => m['title'] as String? ?? '');

  Future<List<(int, String)>> getSupplierOptions() => _fetchLookupOptions('/api/v1/core/suppliers/', label: (m) => m['name'] as String? ?? '');

  Future<List<(int, String)>> getIncidentOptions() => _fetchLookupOptions('/api/v1/behaviour/incidents/', label: (m) => m['title'] as String? ?? '');
}
