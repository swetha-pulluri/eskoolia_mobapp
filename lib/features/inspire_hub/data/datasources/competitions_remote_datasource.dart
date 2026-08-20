import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';

abstract class CompetitionsRemoteDataSource {
  Future<Map<String, dynamic>> createCompetition(Map<String, dynamic> payload);
  Future<void> bulkCreateResults(List<Map<String, dynamic>> payload);
  Future<List<dynamic>> generateReviews(List<Map<String, dynamic>> items);
}

class CompetitionsRemoteDataSourceImpl implements CompetitionsRemoteDataSource {
  final Dio _dio;
  CompetitionsRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> createCompetition(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(ApiConstants.competitions, data: payload);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to create competition.');
    }
  }

  @override
  Future<void> bulkCreateResults(List<Map<String, dynamic>> payload) async {
    try {
      await _dio.post(ApiConstants.competitionResultsBulk, data: payload);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to save results.');
    }
  }

  @override
  Future<List<dynamic>> generateReviews(List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post(ApiConstants.competitionAiReview, data: {'items': items});
      final body = response.data as Map<String, dynamic>;
      return body['results'] as List<dynamic>? ?? const [];
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to generate AI review.');
    }
  }
}
