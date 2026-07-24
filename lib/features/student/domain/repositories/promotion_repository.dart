import '../models/promotion.dart';

abstract class PromotionRepository {
  Future<PromotionBatch> createOrGetBatch({required int academicYearId, required int targetYearId});

  Future<PromotionBatch> fetchBatch(int batchId);

  Future<PromotionRecord> updateRecord(
    int batchId, {
    required int recordId,
    required String status,
    String? retentionReason,
    String? notes,
    int? toClassId,
    int? toSectionId,
  });

  /// Returns the refreshed batch (the bulk-update endpoint conveniently
  /// returns it directly).
  Future<PromotionBatch> bulkUpdate(
    int batchId, {
    required String action, // 'promote' | 'skip' | 'reset'
    required String scope, // 'class' | 'section' | 'selection'
    int? classId,
    int? sectionId,
    List<int>? recordIds,
  });

  Future<String> aiRecommendation(int batchId, {required int recordId, String? reason});

  Future<PromotionBatch> confirmBatch(int batchId);

  Future<PromotionBatch> finalizeBatch(int batchId);
}
