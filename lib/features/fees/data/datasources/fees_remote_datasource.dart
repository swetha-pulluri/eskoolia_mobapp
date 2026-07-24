import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/fees_home_data.dart';
import '../../domain/models/fees_payment.dart';
import '../../domain/models/fees_student_ref.dart';
import '../../domain/models/fees_summary.dart';

abstract class FeesRemoteDataSource {
  Future<FeesSummary> fetchAssignmentsSummary();
  Future<FeesHomeData> fetchHomeDashboard();
  Future<List<FeesPayment>> fetchPayments();
  Future<List<FeesStudentRef>> fetchStudents();
}

/// Extracts a list from either a bare array or a paginated
/// `{count, next, previous, results}` body — mirrors frontend
/// lib/fees-api.ts::listData().
List<dynamic> _listData(dynamic body) {
  if (body is List) return body;
  if (body is Map<String, dynamic>) {
    final results = body['results'];
    if (results is List) return results;
    final data = body['data'];
    if (data is List) return data;
  }
  return const [];
}

class FeesRemoteDataSourceImpl implements FeesRemoteDataSource {
  final Dio _dio;
  FeesRemoteDataSourceImpl(this._dio);

  @override
  Future<FeesSummary> fetchAssignmentsSummary() async {
    try {
      final response = await _dio.get(ApiConstants.feesAssignmentsSummary);
      return FeesSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load fees summary.');
    }
  }

  @override
  Future<FeesHomeData> fetchHomeDashboard() async {
    try {
      final response = await _dio.get(ApiConstants.feesHome);
      return FeesHomeData.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      // No `/fees/home/` route exists on the backend yet — matches the web
      // app's `.catch(console.error)`, which silently leaves this empty.
      return const FeesHomeData();
    }
  }

  @override
  Future<List<FeesPayment>> fetchPayments() async {
    try {
      final response = await _dio.get(
        ApiConstants.feesPayments,
        queryParameters: {'page_size': 1000},
      );
      return _listData(response.data)
          .map((e) => FeesPayment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load payments.');
    }
  }

  @override
  Future<List<FeesStudentRef>> fetchStudents() async {
    try {
      final response = await _dio.get(
        ApiConstants.students,
        queryParameters: {'page_size': 500},
      );
      return _listData(response.data)
          .map((e) => FeesStudentRef.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load students.');
    }
  }
}
