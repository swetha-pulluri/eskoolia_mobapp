import '../../domain/models/promotion.dart';
import '../../domain/repositories/promotion_repository.dart';
import '../datasources/promotion_remote_datasource.dart';

class PromotionRepositoryImpl implements PromotionRepository {
  final PromotionRemoteDataSource _remote;
  PromotionRepositoryImpl(this._remote);

  @override
  Future<PromotionBatch> createOrGetBatch({required int academicYearId, required int targetYearId}) =>
      _remote.createOrGetBatch(academicYearId, targetYearId);

  @override
  Future<PromotionBatch> fetchBatch(int batchId) => _remote.fetchBatch(batchId);

  @override
  Future<PromotionRecord> updateRecord(
    int batchId, {
    required int recordId,
    required String status,
    String? retentionReason,
    String? notes,
    int? toClassId,
    int? toSectionId,
  }) {
    return _remote.updateRecord(batchId, {
      'record_id': recordId,
      'status': status,
      'retention_reason': ?retentionReason,
      'notes': ?notes,
      'to_class': ?toClassId,
      'to_section': ?toSectionId,
    });
  }

  @override
  Future<PromotionBatch> bulkUpdate(
    int batchId, {
    required String action,
    required String scope,
    int? classId,
    int? sectionId,
    List<int>? recordIds,
  }) {
    return _remote.bulkUpdate(batchId, {
      'action': action,
      'scope': scope,
      'class_id': ?classId,
      'section_id': ?sectionId,
      'record_ids': ?recordIds,
    });
  }

  @override
  Future<String> aiRecommendation(int batchId, {required int recordId, String? reason}) {
    return _remote.aiRecommendation(batchId, {'record_id': recordId, 'reason': ?reason});
  }

  @override
  Future<PromotionBatch> confirmBatch(int batchId) => _remote.confirmBatch(batchId);

  @override
  Future<PromotionBatch> finalizeBatch(int batchId) => _remote.finalizeBatch(batchId);
}
