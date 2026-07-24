import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../student/domain/models/academic_year.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/holiday_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/staff_assignment_entities.dart';
import '../../domain/entities/subject_entry.dart';

/// Extracts a list from either a raw JSON array or a DRF-paginated
/// `{results: [...]}` envelope — several endpoints in this feature return
/// one shape or the other depending on whether `pagination_class` is set,
/// mirroring the reference frontend's own defensive `extractList` helpers.
List<Map<String, dynamic>> _list(dynamic data) {
  if (data is List) return data.cast<Map<String, dynamic>>();
  if (data is Map<String, dynamic>) {
    final results = data['results'] as List<dynamic>?;
    if (results != null) return results.cast<Map<String, dynamic>>();
  }
  return const [];
}

abstract class AcademicsRemoteDataSource {
  Future<List<AcademicYear>> fetchAcademicYears();
  Future<AcademicYear> createAcademicYear(Map<String, dynamic> body);
  Future<AcademicYear> updateAcademicYear(int id, Map<String, dynamic> body);
  Future<void> deleteAcademicYear(int id);

  Future<List<Holiday>> fetchHolidays({int? academicYearId});
  Future<void> createHoliday(Map<String, dynamic> body);
  Future<void> updateHoliday(int id, Map<String, dynamic> body);
  Future<void> deleteHoliday(int id);
  Future<({int created, int skipped})> copyHolidaysFromYear(Map<String, dynamic> body);

  Future<List<FoundationClass>> fetchClasses();
  Future<void> createClass(Map<String, dynamic> body);
  Future<void> updateClass(int id, Map<String, dynamic> body);
  Future<void> deleteClass(int id);
  Future<void> toggleClassActive(int id, bool isActive);

  Future<List<StreamDetail>> fetchStreams();
  Future<StreamDetail> createStream(String name);

  Future<({int created, int deleted})> replaceSections(Map<String, dynamic> body);
  Future<void> renameSection(int id, String name);
  Future<void> deleteSection(int id);
  Future<int> bulkDeleteSections(List<int> ids);

  Future<List<ClassSubjectEntry>> fetchClassSubjectEntries();
  Future<List<String>> fetchGlobalSubjectNames();
  Future<Map<String, dynamic>> createSubjectEntry(Map<String, dynamic> body);
  Future<ClassSubjectEntry> updateSubjectEntry(int id, Map<String, dynamic> body);
  Future<void> deleteSubjectEntry(int id);
  Future<void> resetClassSubjects(int classId);

  Future<List<FoundationRoom>> fetchRooms();
  Future<void> createRoom(Map<String, dynamic> body);
  Future<void> updateRoom(int id, Map<String, dynamic> body);
  Future<void> deleteRoom(int id);

  // ── Staff Assignment ─────────────────────────────────────────────────
  Future<List<StaffTeacher>> fetchStaffTeachers();
  Future<List<CTAssignment>> fetchClassTeacherAssignments({int? academicYearId});
  Future<Map<String, dynamic>> createClassTeacherAssignment(Map<String, dynamic> body);
  Future<void> lockClassTeacher(int ctId);
  Future<Map<String, dynamic>> unlockClassTeacher(int ctId, Map<String, dynamic> body);
  Future<List<StaffSubjectRow>> fetchStaffSubjectRows({int? academicYearId, int? classId, int? sectionId});
  Future<Map<String, dynamic>> updateSubjectAssignmentTeacher(int rowId, Map<String, dynamic> body);
  Future<StaffKpi> fetchStaffKpi({int? academicYearId});
  Future<List<StaffWorkloadEntry>> fetchStaffWorkload({int? academicYearId});
  Future<List<StaffAuditLogEntry>> fetchStaffAuditLog();
}

class AcademicsRemoteDataSourceImpl implements AcademicsRemoteDataSource {
  final Dio _dio;
  AcademicsRemoteDataSourceImpl(this._dio);

  Exception _err(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['detail'];
      if (msg is String && msg.isNotEmpty) return Exception(msg);
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final flat = errors.values.expand((v) => v is List ? v : [v]).join(' ');
        if (flat.isNotEmpty) return Exception(flat);
      }
    }
    return Exception(e.error ?? fallback);
  }

  // ── Academic Years ─────────────────────────────────────────────────
  @override
  Future<List<AcademicYear>> fetchAcademicYears() async {
    try {
      final res = await _dio.get(ApiConstants.coreAcademicYears, queryParameters: {'page_size': 200});
      return _list(res.data).map(AcademicYear.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load academic years.');
    }
  }

  @override
  Future<AcademicYear> createAcademicYear(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(ApiConstants.coreAcademicYears, data: body);
      return AcademicYear.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save academic year.');
    }
  }

  @override
  Future<AcademicYear> updateAcademicYear(int id, Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch('${ApiConstants.coreAcademicYears}$id/', data: body);
      return AcademicYear.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save academic year.');
    }
  }

  @override
  Future<void> deleteAcademicYear(int id) async {
    try {
      await _dio.delete('${ApiConstants.coreAcademicYears}$id/');
    } on DioException catch (e) {
      throw _err(e, 'Failed to delete.');
    }
  }

  // ── Holidays ────────────────────────────────────────────────────────
  @override
  Future<List<Holiday>> fetchHolidays({int? academicYearId}) async {
    try {
      final res = await _dio.get(ApiConstants.coreHolidays, queryParameters: {
        'page_size': 200,
        'academic_year': ?academicYearId,
      });
      return _list(res.data).map(Holiday.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load holidays.');
    }
  }

  @override
  Future<void> createHoliday(Map<String, dynamic> body) async {
    try {
      await _dio.post(ApiConstants.coreHolidays, data: body);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save holiday.');
    }
  }

  @override
  Future<void> updateHoliday(int id, Map<String, dynamic> body) async {
    try {
      await _dio.patch('${ApiConstants.coreHolidays}$id/', data: body);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save holiday.');
    }
  }

  @override
  Future<void> deleteHoliday(int id) async {
    try {
      await _dio.delete('${ApiConstants.coreHolidays}$id/');
    } on DioException catch (e) {
      throw _err(e, 'Failed to delete holiday.');
    }
  }

  @override
  Future<({int created, int skipped})> copyHolidaysFromYear(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(ApiConstants.coreHolidaysCopyFromYear, data: body);
      final data = res.data as Map<String, dynamic>;
      return (created: data['created'] as int? ?? 0, skipped: data['skipped'] as int? ?? 0);
    } on DioException catch (e) {
      throw _err(e, 'Failed to copy holidays.');
    }
  }

  // ── Classes / Streams ───────────────────────────────────────────────
  @override
  Future<List<FoundationClass>> fetchClasses() async {
    try {
      final res = await _dio.get(ApiConstants.coreClasses, queryParameters: {'page_size': 200});
      return _list(res.data).map(FoundationClass.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load classes.');
    }
  }

  @override
  Future<void> createClass(Map<String, dynamic> body) async {
    try {
      await _dio.post(ApiConstants.coreClasses, data: body);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save class.');
    }
  }

  @override
  Future<void> updateClass(int id, Map<String, dynamic> body) async {
    try {
      await _dio.patch('${ApiConstants.coreClasses}$id/', data: body);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save class.');
    }
  }

  @override
  Future<void> deleteClass(int id) async {
    try {
      await _dio.delete('${ApiConstants.coreClasses}$id/');
    } on DioException catch (e) {
      throw _err(e, 'Failed to delete class.');
    }
  }

  @override
  Future<void> toggleClassActive(int id, bool isActive) async {
    try {
      await _dio.patch('${ApiConstants.coreClasses}$id/', data: {'is_active': isActive});
    } on DioException catch (e) {
      throw _err(e, 'Failed to update.');
    }
  }

  @override
  Future<List<StreamDetail>> fetchStreams() async {
    try {
      final res = await _dio.get(ApiConstants.coreStreams, queryParameters: {'page_size': 200});
      return _list(res.data).map(StreamDetail.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load streams.');
    }
  }

  @override
  Future<StreamDetail> createStream(String name) async {
    try {
      final res = await _dio.post(ApiConstants.coreStreams, data: {'name': name});
      return StreamDetail.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e, 'Failed to add stream.');
    }
  }

  // ── Sections ────────────────────────────────────────────────────────
  @override
  Future<({int created, int deleted})> replaceSections(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(ApiConstants.coreSectionsReplace, data: body);
      final data = res.data as Map<String, dynamic>;
      return (created: data['created'] as int? ?? 0, deleted: data['deleted'] as int? ?? 0);
    } on DioException catch (e) {
      throw _err(e, 'Failed to create sections.');
    }
  }

  @override
  Future<void> renameSection(int id, String name) async {
    try {
      await _dio.patch('${ApiConstants.coreSections}$id/', data: {'name': name});
    } on DioException catch (e) {
      throw _err(e, 'Failed to rename section.');
    }
  }

  @override
  Future<void> deleteSection(int id) async {
    try {
      await _dio.delete('${ApiConstants.coreSections}$id/');
    } on DioException catch (e) {
      throw _err(e, 'Failed to delete section.');
    }
  }

  @override
  Future<int> bulkDeleteSections(List<int> ids) async {
    try {
      final res = await _dio.post(ApiConstants.coreSectionsBulkDelete, data: {'ids': ids});
      final data = res.data as Map<String, dynamic>;
      return data['deleted'] as int? ?? 0;
    } on DioException catch (e) {
      throw _err(e, 'Failed to delete sections.');
    }
  }

  // ── Subjects / Class-Subject Entries ────────────────────────────────
  @override
  Future<List<ClassSubjectEntry>> fetchClassSubjectEntries() async {
    try {
      final res = await _dio.get(ApiConstants.academicsClassSubjectEntries, queryParameters: {'page_size': 1000});
      return _list(res.data).map(ClassSubjectEntry.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load subjects.');
    }
  }

  @override
  Future<List<String>> fetchGlobalSubjectNames() async {
    try {
      final res = await _dio.get(ApiConstants.coreSubjects, queryParameters: {'page_size': 200});
      return _list(res.data).map((e) => (e['name'] as String?) ?? '').where((n) => n.isNotEmpty).toList();
    } on DioException {
      return const []; // best-effort autocomplete source — never blocks the pane
    }
  }

  @override
  Future<Map<String, dynamic>> createSubjectEntry(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(ApiConstants.academicsClassSubjectEntries, data: body);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e, 'Failed to add subject.');
    }
  }

  @override
  Future<ClassSubjectEntry> updateSubjectEntry(int id, Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch('${ApiConstants.academicsClassSubjectEntries}$id/', data: body);
      return ClassSubjectEntry.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save subject.');
    }
  }

  @override
  Future<void> deleteSubjectEntry(int id) async {
    try {
      await _dio.delete('${ApiConstants.academicsClassSubjectEntries}$id/');
    } on DioException catch (e) {
      throw _err(e, 'Failed to remove subject.');
    }
  }

  @override
  Future<void> resetClassSubjects(int classId) async {
    try {
      await _dio.post(ApiConstants.academicsClassSubjectEntriesResetClass, data: {'class_id': classId});
    } on DioException catch (e) {
      throw _err(e, 'Failed to reset class subjects.');
    }
  }

  // ── Rooms ───────────────────────────────────────────────────────────
  @override
  Future<List<FoundationRoom>> fetchRooms() async {
    try {
      final res = await _dio.get(ApiConstants.coreClassRooms, queryParameters: {'page_size': 200});
      return _list(res.data).map(FoundationRoom.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load rooms.');
    }
  }

  @override
  Future<void> createRoom(Map<String, dynamic> body) async {
    try {
      await _dio.post(ApiConstants.coreClassRooms, data: body);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save room.');
    }
  }

  @override
  Future<void> updateRoom(int id, Map<String, dynamic> body) async {
    try {
      await _dio.patch('${ApiConstants.coreClassRooms}$id/', data: body);
    } on DioException catch (e) {
      throw _err(e, 'Failed to save room.');
    }
  }

  @override
  Future<void> deleteRoom(int id) async {
    try {
      await _dio.delete('${ApiConstants.coreClassRooms}$id/');
    } on DioException catch (e) {
      throw _err(e, 'Failed to delete room.');
    }
  }

  // ── Staff Assignment ────────────────────────────────────────────────
  @override
  Future<List<StaffTeacher>> fetchStaffTeachers() async {
    try {
      final res = await _dio.get(ApiConstants.staffTeachers);
      return _list(res.data).map(StaffTeacher.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load teachers.');
    }
  }

  @override
  Future<List<CTAssignment>> fetchClassTeacherAssignments({int? academicYearId}) async {
    try {
      final res = await _dio.get(ApiConstants.staffClassTeachers, queryParameters: {'academic_year_id': ?academicYearId});
      return _list(res.data).map(CTAssignment.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load class teacher assignments.');
    }
  }

  @override
  Future<Map<String, dynamic>> createClassTeacherAssignment(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(ApiConstants.staffClassTeachers, data: body);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e, 'Failed to assign class teacher.');
    }
  }

  @override
  Future<void> lockClassTeacher(int ctId) async {
    try {
      await _dio.post('${ApiConstants.staffClassTeachers}$ctId/lock/');
    } on DioException catch (e) {
      throw _err(e, 'Failed to lock class teacher.');
    }
  }

  @override
  Future<Map<String, dynamic>> unlockClassTeacher(int ctId, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('${ApiConstants.staffClassTeachers}$ctId/unlock/', data: body);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e, 'Failed to update class teacher.');
    }
  }

  @override
  Future<List<StaffSubjectRow>> fetchStaffSubjectRows({int? academicYearId, int? classId, int? sectionId}) async {
    try {
      final res = await _dio.get(ApiConstants.staffSubjectAssignments, queryParameters: {
        'academic_year_id': ?academicYearId,
        'class_id': ?classId,
        'section_id': ?sectionId,
      });
      return _list(res.data).map(StaffSubjectRow.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load subject assignments.');
    }
  }

  @override
  Future<Map<String, dynamic>> updateSubjectAssignmentTeacher(int rowId, Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch('${ApiConstants.staffSubjectAssignments}$rowId/', data: body);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _err(e, 'Failed to save.');
    }
  }

  @override
  Future<StaffKpi> fetchStaffKpi({int? academicYearId}) async {
    try {
      final res = await _dio.get(ApiConstants.staffKpi, queryParameters: {'academic_year_id': ?academicYearId});
      return StaffKpi.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e, 'Failed to load summary.');
    }
  }

  @override
  Future<List<StaffWorkloadEntry>> fetchStaffWorkload({int? academicYearId}) async {
    try {
      final res = await _dio.get(ApiConstants.staffWorkload, queryParameters: {'academic_year_id': ?academicYearId});
      return _list(res.data).map(StaffWorkloadEntry.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load workload data.');
    }
  }

  @override
  Future<List<StaffAuditLogEntry>> fetchStaffAuditLog() async {
    try {
      final res = await _dio.get(ApiConstants.staffAuditLog);
      return _list(res.data).map(StaffAuditLogEntry.fromJson).toList();
    } on DioException catch (e) {
      throw _err(e, 'Failed to load audit log.');
    }
  }
}
