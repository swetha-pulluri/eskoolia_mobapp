import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/year_end_fee_amount_row.dart';

abstract class FeesYearEndRemoteDataSource {
  Future<List<YearEndFeeAmountRow>> fetchGroupAmounts(int groupId);
  Future<void> saveGroupAmounts(Map<String, dynamic> body);
  Future<List<int>> fetchReportCsv(String reportType);
}

class FeesYearEndRemoteDataSourceImpl implements FeesYearEndRemoteDataSource {
  final Dio _dio;
  FeesYearEndRemoteDataSourceImpl(this._dio);

  @override
  Future<List<YearEndFeeAmountRow>> fetchGroupAmounts(int groupId) async {
    final response = await _dio.get(ApiConstants.feesYearEndGroupAmounts, queryParameters: {'group_id': groupId});
    final data = response.data;
    final feeTypes = data is Map<String, dynamic> ? data['fee_types'] : null;
    if (feeTypes is! List) return const [];
    return feeTypes.map((e) => YearEndFeeAmountRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveGroupAmounts(Map<String, dynamic> body) async {
    await _dio.post(ApiConstants.feesYearEndGroupAmounts, data: body);
  }

  @override
  Future<List<int>> fetchReportCsv(String reportType) async {
    final response = await _dio.get<List<int>>(
      ApiConstants.feesYearEndReport,
      queryParameters: {'report_type': reportType},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }
}
