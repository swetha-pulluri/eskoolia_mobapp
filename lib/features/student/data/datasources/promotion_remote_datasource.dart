import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/promotion.dart';

abstract class PromotionRemoteDataSource {
  Future<PromotionBatch> createOrGetBatch(int academicYearId, int targetYearId);
  Future<PromotionBatch> fetchBatch(int batchId);
  Future<PromotionRecord> updateRecord(int batchId, Map<String, dynamic> body);
  Future<PromotionBatch> bulkUpdate(int batchId, Map<String, dynamic> body);
  Future<String> aiRecommendation(int batchId, Map<String, dynamic> body);
  Future<PromotionBatch> confirmBatch(int batchId);
  Future<PromotionBatch> finalizeBatch(int batchId);
}

class PromotionRemoteDataSourceImpl implements PromotionRemoteDataSource {
  final Dio _dio;
  PromotionRemoteDataSourceImpl(this._dio);

  @override
  Future<PromotionBatch> createOrGetBatch(int academicYearId, int targetYearId) async {
    try {
      final response = await _dio.post(
        ApiConstants.promotionBatchCreateOrGet,
        data: {'academic_year': academicYearId, 'target_year': targetYearId},
      );
      return PromotionBatch.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load promotion batch.');
    }
  }

  @override
  Future<PromotionBatch> fetchBatch(int batchId) async {
    try {
      final response = await _dio.get('${ApiConstants.promotionBatches}$batchId/');
      return PromotionBatch.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to refresh promotion batch.');
    }
  }

  @override
  Future<PromotionRecord> updateRecord(int batchId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.promotionBatchUpdateRecord(batchId), data: body);
      return PromotionRecord.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update record.');
    }
  }

  @override
  Future<PromotionBatch> bulkUpdate(int batchId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.promotionBatchBulkUpdate(batchId), data: body);
      final data = response.data as Map<String, dynamic>;
      return PromotionBatch.fromJson(data['batch'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to apply bulk action.');
    }
  }

  @override
  Future<String> aiRecommendation(int batchId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.promotionBatchAiRecommendation(batchId), data: body);
      final data = response.data as Map<String, dynamic>;
      return (data['recommendation'] as String?) ?? (data['text'] as String?) ?? '';
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to generate recommendation.');
    }
  }

  @override
  Future<PromotionBatch> confirmBatch(int batchId) async {
    try {
      final response = await _dio.post(ApiConstants.promotionBatchConfirm(batchId));
      final data = response.data as Map<String, dynamic>;
      return PromotionBatch.fromJson(data['batch'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to confirm batch.');
    }
  }

  @override
  Future<PromotionBatch> finalizeBatch(int batchId) async {
    try {
      final response = await _dio.post(ApiConstants.promotionBatchFinalize(batchId));
      return PromotionBatch.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to finalize batch.');
    }
  }
}
