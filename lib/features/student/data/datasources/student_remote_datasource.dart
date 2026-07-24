import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/academic_year.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_attendance_record.dart';
import '../../domain/models/student_data.dart';
import '../../domain/models/student_stats.dart';

/// Remote datasource for the Students API — mirrors the shape established by
/// role_remote_datasource.dart: list endpoints parse `response.data` directly
/// into a page/list model, single-resource endpoints unwrap one envelope key
/// first, every method wraps `DioException` into a plain `Exception` whose
/// message is the interceptor-supplied human string (`e.error`).
abstract class StudentRemoteDataSource {
  /// GET /api/v1/students/students/summary/
  Future<StudentStats> fetchStats();

  /// GET /api/v1/core/classes/?page_size=200 — sections come nested per
  /// class in this same response (ClassSerializer), so no separate
  /// /core/sections/ call is needed for the List/Enroll screens.
  Future<List<SchoolClass>> fetchClasses();

  /// GET /api/v1/core/academic-years/?page_size=200
  Future<List<AcademicYear>> fetchAcademicYears();

  /// GET /api/v1/students/categories/?status=active&page_size=200
  Future<List<StudentCategory>> fetchCategories();

  /// GET /api/v1/students/students/?current_class=&current_section=&search=&is_active=&deleted_only=&include_deleted=true&unassigned=&page=&page_size=
  Future<StudentsPage> fetchStudents({
    int? classId,
    int? sectionId,
    String? search,
    bool? isActive,
    bool deletedOnly = false,
    bool? unassigned,
    required int page,
    required int pageSize,
  });

  /// GET /api/v1/students/students/{id}/
  Future<StudentData> fetchStudentDetail(int id);

  /// GET /api/v1/students/students/next-admission-no/
  Future<String> fetchNextAdmissionNo();

  /// POST /api/v1/students/students/{id}/set-status/
  Future<void> setStudentStatus(
    int id, {
    required bool isActive,
    required String reason,
  });

  /// POST /api/v1/students/students/{id}/soft-delete/
  Future<void> archiveStudent(int id, {required String reason});

  /// POST /api/v1/students/guardians/ — returns the created guardian's id.
  Future<int> createGuardian({
    required String fullName,
    required String relation,
    required String phone,
  });

  /// GET /api/v1/students/guardians/{id}/ — the Profile page's Contact
  /// section needs the guardian's name/phone, but `Student.guardian` is
  /// just a raw FK id (no nested object on the student detail response).
  Future<(String fullName, String phone)> fetchGuardianDetail(int id);

  /// POST /api/v1/students/students/
  Future<StudentData> createStudent(Map<String, dynamic> body);

  /// PUT /api/v1/students/students/{id}/
  Future<StudentData> updateStudent(int id, Map<String, dynamic> body);

  /// PATCH /api/v1/students/students/{id}/ — a raw partial update for the
  /// handful of call sites that only ever touch a couple of fields directly
  /// (Disabled screen's "Enable", Unassigned screen's "Assign class"), the
  /// same way the reference frontend does, rather than round-tripping a
  /// full StudentData draft through [updateStudent].
  Future<void> patchStudentFields(int id, Map<String, dynamic> fields);

  /// POST /api/v1/students/students/{id}/restore/
  Future<void> restoreStudent(int id);

  /// DELETE /api/v1/students/students/{id}/permanent-delete/ (superuser-only
  /// server-side).
  Future<void> permanentDeleteStudent(int id);

  /// GET /api/v1/students/record-audits/?student=&action=&class=&section=&search=
  Future<List<Map<String, dynamic>>> fetchRecordAudits({
    int? studentId,
    String? action,
    int? classId,
    int? sectionId,
    String? search,
  });

  /// GET /api/v1/attendance/student-attendance/?student_id=&date_from=&date_to=&page_size=1000
  Future<List<StudentAttendanceRecord>> fetchStudentAttendance(
    int studentId, {
    required DateTime from,
    required DateTime to,
  });

  /// GET /api/v1/students/students/export-xlsx/?current_class=&current_section=&is_active=
  /// — returns the raw .xlsx file bytes. This is the ONLY real
  /// backend-wired export for students (fixed 8 columns: Admission No,
  /// Student, Class, Section, Guardian, Phone, DOB, Status) — see
  /// student_export_page.dart's doc comment for why the reference
  /// frontend's own CSV/PDF/column-picker UI isn't reproduced here.
  Future<List<int>> exportStudentsXlsx({int? classId, int? sectionId, bool? isActive});

  /// POST /api/v1/students/students/upload-photo/ (multipart, field `photo`)
  /// — returns the uploaded photo's URL.
  Future<String> uploadStudentPhoto({required List<int> bytes, required String filename});

  /// POST /api/v1/students/documents/upload_document/ (multipart, fields
  /// `student_id`, `document_type`, `file`).
  Future<void> uploadStudentDocument({
    required int studentId,
    required String documentType,
    required List<int> bytes,
    required String filename,
  });
}

class StudentRemoteDataSourceImpl implements StudentRemoteDataSource {
  final Dio _dio;

  StudentRemoteDataSourceImpl(this._dio);

  @override
  Future<StudentStats> fetchStats() async {
    try {
      final response = await _dio.get(ApiConstants.studentsSummary);
      final body = response.data as Map<String, dynamic>;
      return StudentStats.fromJson(
        body['data'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load student stats.');
    }
  }

  @override
  Future<List<SchoolClass>> fetchClasses() async {
    try {
      final response = await _dio.get(
        ApiConstants.coreClasses,
        queryParameters: {'page_size': 200},
      );
      final body = response.data as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>? ?? const [];
      return results
          .map((e) => SchoolClass.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load classes.');
    }
  }

  @override
  Future<List<AcademicYear>> fetchAcademicYears() async {
    try {
      final response = await _dio.get(
        ApiConstants.coreAcademicYears,
        queryParameters: {'page_size': 200},
      );
      final body = response.data as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>? ?? const [];
      return results
          .map((e) => AcademicYear.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load academic years.');
    }
  }

  @override
  Future<List<StudentCategory>> fetchCategories() async {
    try {
      final response = await _dio.get(
        ApiConstants.studentCategories,
        queryParameters: {'status': 'active', 'page_size': 200},
      );
      final body = response.data as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>? ?? const [];
      return results
          .map((e) => StudentCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load categories.');
    }
  }

  @override
  Future<StudentsPage> fetchStudents({
    int? classId,
    int? sectionId,
    String? search,
    bool? isActive,
    bool deletedOnly = false,
    bool? unassigned,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.students,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'include_deleted': 'true',
          'current_class': ?classId,
          'current_section': ?sectionId,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (isActive != null) 'is_active': isActive.toString(),
          if (deletedOnly) 'deleted_only': 'true',
          if (unassigned == true) 'unassigned': 'true',
        },
      );
      return StudentsPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load students.');
    }
  }

  @override
  Future<StudentData> fetchStudentDetail(int id) async {
    try {
      final response = await _dio.get(ApiConstants.studentDetail(id));
      return StudentData.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load student.');
    }
  }

  @override
  Future<String> fetchNextAdmissionNo() async {
    try {
      final response = await _dio.get(ApiConstants.studentNextAdmissionNo);
      final body = response.data as Map<String, dynamic>;
      return (body['admission_no'] as String?) ?? '';
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to generate admission number.');
    }
  }

  @override
  Future<void> setStudentStatus(
    int id, {
    required bool isActive,
    required String reason,
  }) async {
    try {
      await _dio.post(
        ApiConstants.studentSetStatus(id),
        data: {'is_active': isActive, 'reason': reason},
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update student status.');
    }
  }

  @override
  Future<void> archiveStudent(int id, {required String reason}) async {
    try {
      await _dio.post(
        ApiConstants.studentSoftDelete(id),
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to archive student.');
    }
  }

  @override
  Future<int> createGuardian({
    required String fullName,
    required String relation,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.guardians,
        data: {
          'full_name': fullName,
          'relation': relation,
          'phone': phone,
          'email': '',
          'occupation': '',
        },
      );
      final body = response.data as Map<String, dynamic>;
      return body['id'] as int;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to save guardian.');
    }
  }

  @override
  Future<(String, String)> fetchGuardianDetail(int id) async {
    try {
      final response = await _dio.get(ApiConstants.guardianDetail(id));
      final body = response.data as Map<String, dynamic>;
      return (
        (body['full_name'] as String?) ?? '',
        (body['phone'] as String?) ?? '',
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load guardian.');
    }
  }

  @override
  Future<StudentData> createStudent(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.students, data: body);
      final responseBody = response.data as Map<String, dynamic>;
      return StudentData.fromJson(responseBody['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to enroll student.');
    }
  }

  @override
  Future<void> patchStudentFields(int id, Map<String, dynamic> fields) async {
    try {
      await _dio.patch(ApiConstants.studentDetail(id), data: fields);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update student.');
    }
  }

  @override
  Future<void> restoreStudent(int id) async {
    try {
      await _dio.post(ApiConstants.studentRestore(id));
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to restore student.');
    }
  }

  @override
  Future<void> permanentDeleteStudent(int id) async {
    try {
      await _dio.delete(ApiConstants.studentPermanentDelete(id));
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to permanently delete student.');
    }
  }

  @override
  Future<List<int>> exportStudentsXlsx({int? classId, int? sectionId, bool? isActive}) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentExportXlsx,
        queryParameters: {
          'current_class': ?classId,
          'current_section': ?sectionId,
          if (isActive != null) 'is_active': isActive.toString(),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to export students.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecordAudits({
    int? studentId,
    String? action,
    int? classId,
    int? sectionId,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentRecordAudits,
        queryParameters: {
          'student_id': ?studentId,
          if (action != null && action.isNotEmpty) 'action': action,
          'class': ?classId,
          'section': ?sectionId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'page_size': 200,
        },
      );
      final data = response.data;
      final raw = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['results'] as List<dynamic>? ?? const [])
              : const [];
      return raw.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load audit log.');
    }
  }

  @override
  Future<StudentData> updateStudent(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(
        ApiConstants.studentDetail(id),
        data: body,
      );
      final responseBody = response.data as Map<String, dynamic>;
      return StudentData.fromJson(responseBody['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update student.');
    }
  }

  @override
  Future<List<StudentAttendanceRecord>> fetchStudentAttendance(
    int studentId, {
    required DateTime from,
    required DateTime to,
  }) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      final response = await _dio.get(
        ApiConstants.studentAttendance,
        queryParameters: {
          'student_id': studentId,
          'date_from': fmt(from),
          'date_to': fmt(to),
          'page_size': 1000,
        },
      );
      final data = response.data;
      final raw = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['results'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? const [])
              : const [];
      return raw
          .cast<Map<String, dynamic>>()
          .map(StudentAttendanceRecord.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load attendance.');
    }
  }

  @override
  Future<String> uploadStudentPhoto({required List<int> bytes, required String filename}) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post(ApiConstants.studentUploadPhoto, data: formData);
      final body = response.data as Map<String, dynamic>;
      final url = (body['data'] as Map<String, dynamic>?)?['photo'] as String?;
      if (url == null || url.isEmpty) throw Exception('Photo upload failed.');
      return url;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to upload photo.');
    }
  }

  @override
  Future<void> uploadStudentDocument({
    required int studentId,
    required String documentType,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'student_id': studentId.toString(),
        'document_type': documentType,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      await _dio.post(ApiConstants.studentDocumentUpload, data: formData);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to upload document.');
    }
  }
}
