import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../administration/domain/entities/paginated_result.dart';
import '../../domain/entities/attendance_entities.dart';

/// Attendance Remote Data Source — Student Attendance module.
/// Calls the real backend endpoints under `apps/attendance` and
/// `apps/core`, matching the recovered real `StudentAttendancePage`
/// implementation on `main` (the branch actually served by the running
/// frontend dev server).
class AttendanceRemoteDataSource {
  final DioClient _dioClient;

  AttendanceRemoteDataSource(this._dioClient);

  /// Loops pages until every row is collected — same rationale as
  /// Admissions' `_fetchAllPages` (superuser accounts merge every school's
  /// rows, and a single 100-row page can starve the target school's own
  /// tail-end rows).
  Future<List<T>> _fetchAllPages<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic> baseParams = const {},
    int pageSize = 100,
    int maxPages = 20,
  }) async {
    final all = <T>[];
    var page = 1;
    while (page <= maxPages) {
      final response = await _dioClient.get(path, queryParameters: {...baseParams, 'page': page, 'page_size': pageSize});
      final result = PaginatedResult.fromJson(response.data, fromJson);
      all.addAll(result.results);
      if (all.length >= result.count || result.results.isEmpty) break;
      page++;
    }
    return all;
  }

  // ─── Classes / Sections (apps.core) ────────────────────────────────────
  Future<List<ClassInfoEntity>> getClasses() async {
    try {
      return await _fetchAllPages('/api/v1/core/classes/', ClassInfoEntity.fromJson, pageSize: 100);
    } catch (e) {
      AppLogger.error('Get attendance classes error', e);
      rethrow;
    }
  }

  /// `GET /api/v1/core/sections/?class=<id>` — matches the import dialog's
  /// class-scoped section fetch.
  Future<List<SectionSummaryEntity>> getSectionsForClass(int classId) async {
    try {
      final response = await _dioClient.get('/api/v1/core/sections/', queryParameters: {'class': classId, 'page_size': 200});
      return PaginatedResult.fromJson(response.data, SectionSummaryEntity.fromJson).results;
    } catch (e) {
      AppLogger.error('Get sections for class error', e);
      rethrow;
    }
  }

  // ─── Dashboard summaries ────────────────────────────────────────────────
  Future<KpiDataEntity> getDailySummary(String date) async {
    try {
      final response = await _dioClient.get('/api/v1/attendance/student-attendance/daily-summary/', queryParameters: {'date': date});
      return KpiDataEntity.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get daily summary error', e);
      rethrow;
    }
  }

  Future<List<ClassSummaryTileEntity>> getClassSummary(String date) async {
    try {
      final response = await _dioClient.get('/api/v1/attendance/student-attendance/class-summary/', queryParameters: {'date': date});
      final map = response.data as Map<String, dynamic>;
      final classes = map['classes'] as List? ?? const [];
      return classes.map((e) => ClassSummaryTileEntity.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.error('Get class summary error', e);
      rethrow;
    }
  }

  // ─── Daily grid ─────────────────────────────────────────────────────────
  Future<List<AttendanceStudentEntity>> searchStudents({required int classId, required int sectionId, required String date}) async {
    try {
      final response = await _dioClient.post(
        '/api/v1/attendance/student-attendance/student-search/',
        data: {'class_id': classId, 'section_id': sectionId, 'attendance_date': date},
      );
      final map = response.data as Map<String, dynamic>;
      final students = map['students'] as List? ?? const [];
      return students.map((e) => AttendanceStudentEntity.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.error('Search students error', e);
      rethrow;
    }
  }

  /// `POST student-attendance/store/` — the one real bulk-mark endpoint.
  /// `ids` and the per-student maps only need to cover the students
  /// actually being written this call (matches web's own incremental
  /// per-action submits) — the backend's "full coverage" rule only
  /// requires every id present in `ids` to have a status in `attendance`,
  /// not that the whole class roster be included every time.
  Future<void> storeAttendance({
    required String date,
    required int classId,
    required int sectionId,
    int? academicYearId,
    required List<int> ids,
    required Map<int, String> attendance,
    Map<int, String>? note,
    Map<int, String>? arrivalTime,
    Map<int, String>? signInTime,
    Map<int, String>? signOutTime,
    Map<int, String>? pickupTime,
    Map<int, String>? pickupBy,
    Map<int, bool>? lunch,
    bool lockAttendance = false,
  }) async {
    String k(int id) => id.toString();
    final body = <String, dynamic>{
      'date': date,
      'class_id': classId,
      'section_id': sectionId,
      if (academicYearId != null) 'academic_year_id': academicYearId,
      'id': ids,
      'attendance': {for (final e in attendance.entries) k(e.key): e.value},
      if (note != null) 'note': {for (final e in note.entries) k(e.key): e.value},
      if (arrivalTime != null) 'arrival_time': {for (final e in arrivalTime.entries) k(e.key): e.value},
      if (signInTime != null) 'sign_in_time': {for (final e in signInTime.entries) k(e.key): e.value},
      if (signOutTime != null) 'sign_out_time': {for (final e in signOutTime.entries) k(e.key): e.value},
      if (pickupTime != null) 'pickup_time': {for (final e in pickupTime.entries) k(e.key): e.value},
      if (pickupBy != null) 'pickup_by': {for (final e in pickupBy.entries) k(e.key): e.value},
      if (lunch != null) 'lunch': {for (final e in lunch.entries) k(e.key): e.value},
      'lock_attendance': lockAttendance,
    };
    await _dioClient.post('/api/v1/attendance/student-attendance/store/', data: body);
  }

  // ─── Monthly report ─────────────────────────────────────────────────────
  Future<List<MonthlyReportRowEntity>> getMonthlyReport({
    required int classId,
    required int sectionId,
    required int month,
    required int year,
    String? academicYear,
  }) async {
    final response = await _dioClient.get('/api/v1/attendance/student-attendance/report/', queryParameters: {
      'class_id': classId,
      'section_id': sectionId,
      'month': month,
      'year': year,
      if (academicYear != null) 'academic_year': academicYear,
      'page_size': 100,
    });
    return PaginatedResult.fromJson(response.data, MonthlyReportRowEntity.fromJson).results;
  }

  Future<ReportInsightsEntity> getReportInsights({
    required int month,
    required int year,
    int? classId,
    int? sectionId,
    String? academicYear,
  }) async {
    final response = await _dioClient.get('/api/v1/attendance/student-attendance/report-insights/', queryParameters: {
      'month': month,
      'year': year,
      if (classId != null) 'class_id': classId,
      if (sectionId != null) 'section_id': sectionId,
      if (academicYear != null) 'academic_year': academicYear,
    });
    return ReportInsightsEntity.fromJson(response.data as Map<String, dynamic>);
  }

  /// Bare list endpoint — used only to build the report's week-by-week
  /// donut cards client-side (matches web's own documented workaround).
  Future<List<DailyAttendanceRecordEntity>> getRawRecordsForReport({
    required int month,
    required int year,
    int? classId,
    int? sectionId,
    String? academicYear,
  }) async {
    return _fetchAllPages(
      '/api/v1/attendance/student-attendance/',
      DailyAttendanceRecordEntity.fromJson,
      baseParams: {
        'month': month,
        'year': year,
        if (classId != null) 'class_id': classId,
        if (sectionId != null) 'section_id': sectionId,
        if (academicYear != null) 'academic_year': academicYear,
      },
      pageSize: 100,
    );
  }

  // ─── Download / Export / Import ────────────────────────────────────────
  Future<Uint8List> downloadSample() async {
    final response = await _dioClient.get(
      '/api/v1/attendance/student-attendance/download-sample/',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  Future<Uint8List> exportAttendance({
    String fmt = 'xlsx',
    int? classId,
    int? sectionId,
    int? month,
    int? year,
    String? academicYear,
    String? date,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dioClient.get(
      '/api/v1/attendance/student-attendance/export/',
      queryParameters: {
        'fmt': fmt,
        if (classId != null) 'class_id': classId,
        if (sectionId != null) 'section_id': sectionId,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
        if (academicYear != null) 'academic_year': academicYear,
        if (date != null) 'date': date,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  /// `GET student-attendance/import/` — the import dialog's own
  /// criteria-form class list (distinct from `/core/classes/`).
  Future<List<Map<String, dynamic>>> getImportClasses() async {
    final response = await _dioClient.get('/api/v1/attendance/student-attendance/import/');
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    final map = data as Map<String, dynamic>;
    final list = (map['classes'] ?? map['results'] ?? const []) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> bulkImport({
    required int classId,
    required int sectionId,
    required String attendanceDate,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'class': classId.toString(),
      'section': sectionId.toString(),
      'attendance_date': attendanceDate,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await _dioClient.post('/api/v1/attendance/student-attendance/bulk-store/', data: formData);
    return response.data as Map<String, dynamic>;
  }
}
