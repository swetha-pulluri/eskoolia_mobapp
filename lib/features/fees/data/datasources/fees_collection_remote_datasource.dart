import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/fees_payment.dart';
import '../../domain/models/fees_reconciliation.dart';
import '../../domain/models/school_header_info.dart';

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

abstract class FeesCollectionRemoteDataSource {
  Future<FeesPayment> createPayment(Map<String, dynamic> body);
  Future<List<FeesReconciliation>> fetchReconciliations();
  Future<FeesReconciliation> createReconciliation(Map<String, dynamic> body);
  Future<SchoolHeaderInfo> fetchMySchoolInfo();
}

class FeesCollectionRemoteDataSourceImpl implements FeesCollectionRemoteDataSource {
  final Dio _dio;
  FeesCollectionRemoteDataSourceImpl(this._dio);

  @override
  Future<FeesPayment> createPayment(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesPayments, data: body);
      return FeesPayment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Payment failed. Please try again.');
    }
  }

  @override
  Future<List<FeesReconciliation>> fetchReconciliations() async {
    final response = await _dio.get(
      ApiConstants.feesReconciliations,
      queryParameters: {'page_size': 200},
    );
    return _listData(response.data).map((e) => FeesReconciliation.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<FeesReconciliation> createReconciliation(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.feesReconciliations, data: body);
      return FeesReconciliation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to save. Please try again.');
    }
  }

  @override
  Future<SchoolHeaderInfo> fetchMySchoolInfo() async {
    final response = await _dio.get(ApiConstants.tenancyMySchoolInfo);
    return SchoolHeaderInfo.fromJson(response.data as Map<String, dynamic>);
  }
}
