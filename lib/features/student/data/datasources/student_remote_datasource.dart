import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/academic_year.dart';
import '../../domain/models/school_class.dart';
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

  /// GET /api/v1/students/students/?current_class=&current_section=&search=&is_active=&deleted_only=&include_deleted=true&page=&page_size=
  Future<StudentsPage> fetchStudents({
    int? classId,
    int? sectionId,
    String? search,
    bool? isActive,
    bool deletedOnly = false,
    required int page,
    required int pageSize,
  });

  /// GET /api/v1/students/students/{id}/
  Future<StudentData> fetchStudentDetail(int id);

  /// GET /api/v1/students/students/next-admission-no/
  Future<String> fetchNextAdmissionNo();

  /// POST /api/v1/students/students/{id}/set-status/
  Future<void> setStudentStatus(int id, {required bool isActive, required String reason});

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
}

class StudentRemoteDataSourceImpl implements StudentRemoteDataSource {
  final Dio _dio;

  StudentRemoteDataSourceImpl(this._dio);

  @override
  Future<StudentStats> fetchStats() async {
    try {
      final response = await _dio.get(ApiConstants.studentsSummary);
      final body = response.data as Map<String, dynamic>;
      return StudentStats.fromJson(body['data'] as Map<String, dynamic>? ?? const {});
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
      return results.map((e) => SchoolClass.fromJson(e as Map<String, dynamic>)).toList();
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
      return results.map((e) => AcademicYear.fromJson(e as Map<String, dynamic>)).toList();
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
      return results.map((e) => StudentCategory.fromJson(e as Map<String, dynamic>)).toList();
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
          if (classId != null) 'current_class': classId,
          if (sectionId != null) 'current_section': sectionId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (isActive != null) 'is_active': isActive.toString(),
          if (deletedOnly) 'deleted_only': 'true',
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
  Future<void> setStudentStatus(int id, {required bool isActive, required String reason}) async {
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
      return ((body['full_name'] as String?) ?? '', (body['phone'] as String?) ?? '');
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
  Future<StudentData> updateStudent(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(ApiConstants.studentDetail(id), data: body);
      final responseBody = response.data as Map<String, dynamic>;
      return StudentData.fromJson(responseBody['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update student.');
    }
  }
}
