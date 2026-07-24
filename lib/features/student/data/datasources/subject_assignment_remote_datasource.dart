import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/subject_assignment.dart';

/// Backend serialises optional subjects as a flat, order-significant list
/// (`opt_subs[0]`→lang2, `[1]`→lang3, `[2]`→sport, `[3]`→art — see
/// `StudentViewSet._serialize_assignment_student` /
/// `StudentSubjectAssignmentViewSet.upsert_optional`), so
/// [upsertOptionalSubjects] must send subject names in that same order.
abstract class SubjectAssignmentRemoteDataSource {
  Future<SubjectAssignmentStats> fetchStats();
  Future<List<AssignmentClassNode>> fetchClassSectionTree();
  Future<AssignmentSectionPage> fetchSectionStudents({
    required int classId,
    required int sectionId,
    required int page,
    required int pageSize,
  });
  Future<void> upsertOptionalSubjects(int studentId, List<String> subjectNames);
}

class SubjectAssignmentRemoteDataSourceImpl implements SubjectAssignmentRemoteDataSource {
  final Dio _dio;
  SubjectAssignmentRemoteDataSourceImpl(this._dio);

  @override
  Future<SubjectAssignmentStats> fetchStats() async {
    try {
      final response = await _dio.get(ApiConstants.subjectAssignmentStats);
      return SubjectAssignmentStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load stats.');
    }
  }

  @override
  Future<List<AssignmentClassNode>> fetchClassSectionTree() async {
    try {
      final response = await _dio.get(
        ApiConstants.subjectAssignmentClassSectionTree,
        queryParameters: {'page_size': 10},
      );
      final data = response.data as List<dynamic>;
      return data.map((e) => AssignmentClassNode.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load classes.');
    }
  }

  @override
  Future<AssignmentSectionPage> fetchSectionStudents({
    required int classId,
    required int sectionId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.subjectAssignmentSectionStudents,
        queryParameters: {'class_id': classId, 'section_id': sectionId, 'page': page, 'page_size': pageSize},
      );
      return AssignmentSectionPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load students.');
    }
  }

  @override
  Future<void> upsertOptionalSubjects(int studentId, List<String> subjectNames) async {
    try {
      await _dio.post(
        ApiConstants.subjectAssignmentUpsertOptional,
        data: {'student_id': studentId, 'subject_names': subjectNames},
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to save subject assignment.');
    }
  }
}
