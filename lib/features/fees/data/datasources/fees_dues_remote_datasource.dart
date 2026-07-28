import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/due_interaction.dart';
import '../../domain/models/dues_class_group.dart';
import '../../domain/models/dues_summary.dart';

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

abstract class FeesDuesRemoteDataSource {
  Future<List<DuesClassGroup>> fetchByClass({required int tier});
  Future<DuesSummary> fetchSummary();
  Future<List<DueInteraction>> fetchInteractions(String studentId);
  Future<DueInteraction> createInteraction(Map<String, dynamic> body);
  Future<DueInteraction> resolveDue(Map<String, dynamic> body);
  Future<int> sendReminders(Map<String, dynamic> body);
  Future<List<int>> exportCsv();
}

class FeesDuesRemoteDataSourceImpl implements FeesDuesRemoteDataSource {
  final Dio _dio;
  FeesDuesRemoteDataSourceImpl(this._dio);

  @override
  Future<List<DuesClassGroup>> fetchByClass({required int tier}) async {
    final response = await _dio.get(ApiConstants.feesDuesByClass, queryParameters: {'tier': tier.toString()});
    return _listData(response.data).map((e) => DuesClassGroup.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<DuesSummary> fetchSummary() async {
    final response = await _dio.get(ApiConstants.feesDuesSummary);
    return DuesSummary.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<DueInteraction>> fetchInteractions(String studentId) async {
    final response = await _dio.get(ApiConstants.feesDuesInteractions, queryParameters: {'student': studentId});
    return _listData(response.data).map((e) => DueInteraction.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<DueInteraction> createInteraction(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.feesDuesInteractions, data: body);
    return DueInteraction.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DueInteraction> resolveDue(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.feesDuesResolve, data: body);
    return DueInteraction.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<int> sendReminders(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.feesDuesSendReminder, data: body);
    final data = response.data;
    if (data is Map<String, dynamic>) return (data['sent'] as num?)?.toInt() ?? 0;
    return 0;
  }

  @override
  Future<List<int>> exportCsv() async {
    final response = await _dio.get<List<int>>(
      ApiConstants.feesDuesExportCsv,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }
}
