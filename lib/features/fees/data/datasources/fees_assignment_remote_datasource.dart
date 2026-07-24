import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/assignment_student.dart';
import '../../domain/models/fee_assignment.dart';
import '../../domain/repositories/fees_config_repository.dart' show FeesConfigValidationException;

List<dynamic> _listData(dynamic body) {
  if (body is List) return body;
  if (body is Map<String, dynamic>) {
    final results = body['results'];
    if (results is List) return results;
  }
  return const [];
}

/// FeeAssignment's list/detail views return bare DRF errors —
/// `{field: [messages]}` — not the `{success,message,errors}` envelope used
/// by several sibling `apps/fees` endpoints. Confirmed by reading
/// `FeeAssignmentListCreateAPIView`/`FeeAssignmentDetailAPIView` directly.
Never _throwValidation(DioException e, String fallback) {
  final data = e.response?.data;
  final fieldErrors = <String, String>{};
  if (data is Map) {
    data.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        fieldErrors[key.toString()] = value.first.toString();
      } else if (value is String) {
        fieldErrors[key.toString()] = value;
      }
    });
  }
  final message = fieldErrors.values.firstOrNull ?? fallback;
  throw FeesConfigValidationException(fieldErrors, message);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

abstract class FeesAssignmentRemoteDataSource {
  Future<List<AssignmentStudent>> fetchStudents({int? academicYear});
  Future<List<FeeAssignment>> fetchAssignments({int? academicYear});
  Future<FeeAssignment> createAssignment(Map<String, dynamic> body);
  Future<FeeAssignment> updateAssignment(int id, Map<String, dynamic> body);
}

class FeesAssignmentRemoteDataSourceImpl implements FeesAssignmentRemoteDataSource {
  final Dio _dio;
  FeesAssignmentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<AssignmentStudent>> fetchStudents({int? academicYear}) async {
    final response = await _dio.get(
      ApiConstants.students,
      queryParameters: {
        'page_size': 500,
        'academic_year': ?academicYear,
      },
    );
    var rows = _listData(response.data);
    // Mirrors the source's own fallback: some tenants return zero students
    // scoped to the selected academic year — retry unscoped rather than
    // showing an empty roster.
    if (rows.isEmpty && academicYear != null) {
      final fallback = await _dio.get(ApiConstants.students, queryParameters: {'page_size': 500});
      rows = _listData(fallback.data);
    }
    return rows.map((e) => AssignmentStudent.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<FeeAssignment>> fetchAssignments({int? academicYear}) async {
    final response = await _dio.get(
      ApiConstants.feesAssignments,
      queryParameters: {
        'page_size': 10000,
        'academic_year': ?academicYear,
      },
    );
    var rows = _listData(response.data);
    if (rows.isEmpty && academicYear != null) {
      final fallback = await _dio.get(ApiConstants.feesAssignments, queryParameters: {'page_size': 10000});
      rows = _listData(fallback.data);
    }
    return rows.map((e) => FeeAssignment.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<FeeAssignment> createAssignment(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesAssignments, data: body);
      return FeeAssignment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to save fee assignment.');
    }
  }

  @override
  Future<FeeAssignment> updateAssignment(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(ApiConstants.feesAssignmentDetail(id), data: body);
      return FeeAssignment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwValidation(e, 'Failed to update fee assignment.');
    }
  }
}
