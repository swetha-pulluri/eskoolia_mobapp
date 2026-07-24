import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/student_group.dart';

abstract class StudentGroupRemoteDataSource {
  Future<List<StudentGroup>> fetchGroups({String? type, String? search});
  Future<StudentGroupStats> fetchStats();
  Future<List<GroupStudentRow>> fetchStudents({String? className, String? sectionName, String? status});
  Future<StudentGroup> createGroup(Map<String, dynamic> body);
  Future<StudentGroup> updateGroup(int id, Map<String, dynamic> body);
  Future<void> deleteGroup(int id);
  Future<void> assignHouse(int studentId, int? groupId);
  Future<void> bulkAssignHouse(List<int> studentIds, int? groupId);
  Future<List<int>> toggleClubMembership(int studentId, int clubId);
  Future<void> addToClub(int studentId, int clubId);
  Future<List<SortwellPreviewItem>> fetchSortwellPreview(String scope);
  Future<SortwellResult> runSortwell({required String method, required String scope});
}

class StudentGroupRemoteDataSourceImpl implements StudentGroupRemoteDataSource {
  final Dio _dio;
  StudentGroupRemoteDataSourceImpl(this._dio);

  @override
  Future<List<StudentGroup>> fetchGroups({String? type, String? search}) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentGroups,
        queryParameters: {
          'page_size': 200,
          if (type != null && type.isNotEmpty) 'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final body = response.data;
      final results = body is Map<String, dynamic> ? (body['results'] as List<dynamic>? ?? const []) : (body as List<dynamic>);
      return results.map((e) => StudentGroup.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load groups.');
    }
  }

  @override
  Future<StudentGroupStats> fetchStats() async {
    try {
      final response = await _dio.get(ApiConstants.studentGroupStats);
      return StudentGroupStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load group stats.');
    }
  }

  @override
  Future<List<GroupStudentRow>> fetchStudents({String? className, String? sectionName, String? status}) async {
    try {
      final response = await _dio.get(
        ApiConstants.studentGroupStudents,
        queryParameters: {
          if (className != null && className.isNotEmpty) 'class': className,
          if (sectionName != null && sectionName.isNotEmpty) 'section': sectionName,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = response.data as List<dynamic>;
      return data.map((e) => GroupStudentRow.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load students.');
    }
  }

  @override
  Future<StudentGroup> createGroup(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.studentGroups, data: body);
      return StudentGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to create group.');
    }
  }

  @override
  Future<StudentGroup> updateGroup(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(ApiConstants.studentGroupDetail(id), data: body);
      return StudentGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update group.');
    }
  }

  @override
  Future<void> deleteGroup(int id) async {
    try {
      await _dio.delete(ApiConstants.studentGroupDetail(id));
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to delete group.');
    }
  }

  @override
  Future<void> assignHouse(int studentId, int? groupId) async {
    try {
      await _dio.post(ApiConstants.studentGroupAssign, data: {'studentId': studentId, 'groupId': groupId});
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to assign house.');
    }
  }

  @override
  Future<void> bulkAssignHouse(List<int> studentIds, int? groupId) async {
    try {
      await _dio.post(ApiConstants.studentGroupBulkAssign, data: {'studentIds': studentIds, 'groupId': groupId});
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to bulk-assign house.');
    }
  }

  @override
  Future<List<int>> toggleClubMembership(int studentId, int clubId) async {
    try {
      final response = await _dio.post(
        ApiConstants.studentGroupClubToggle,
        data: {'studentId': studentId, 'clubId': clubId},
      );
      final body = response.data as Map<String, dynamic>;
      return (body['clubIds'] as List<dynamic>? ?? const []).map((e) => e as int).toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update club membership.');
    }
  }

  @override
  Future<void> addToClub(int studentId, int clubId) async {
    try {
      await _dio.post(ApiConstants.studentGroupClubAssign, data: {'studentId': studentId, 'clubId': clubId});
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to add student to club.');
    }
  }

  @override
  Future<List<SortwellPreviewItem>> fetchSortwellPreview(String scope) async {
    try {
      final response = await _dio.get(ApiConstants.studentGroupSortwellPreview, queryParameters: {'scope': scope});
      final body = response.data as Map<String, dynamic>;
      final houses = (body['houses'] as List<dynamic>? ?? const []);
      return houses.map((e) => SortwellPreviewItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load Sortwell preview.');
    }
  }

  @override
  Future<SortwellResult> runSortwell({required String method, required String scope}) async {
    try {
      final response = await _dio.post(ApiConstants.studentGroupSortwell, data: {'method': method, 'scope': scope});
      return SortwellResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to run Sortwell.');
    }
  }
}
