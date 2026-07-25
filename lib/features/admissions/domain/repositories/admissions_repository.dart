import '../../../administration/domain/entities/admin_setup_entity.dart';
import '../entities/inquiry_entity.dart';
import '../entities/school_class_entity.dart';
import '../entities/analytics_data_entity.dart';

/// Admissions Repository — Command Center + Analytics data access.
/// `updateInquiry`/`createInquiry` accept a functional-update pattern so
/// call sites keep working with the same `(current) => current.copyWith(...)`
/// shape already established across the module's modals, backed by a
/// lightweight in-memory cache (populated by [getInquiries]) instead of a
/// permanent empty local store.
abstract class AdmissionsRepository {
  Future<List<InquiryEntity>> getInquiries();
  Future<InquiryEntity> createInquiry(InquiryEntity draft);
  Future<InquiryEntity> updateInquiry(int id, InquiryEntity Function(InquiryEntity current) update);
  Future<void> deleteInquiry(int id);
  Future<InquiryEntity> mergeInquiries({required int keepId, required int absorbId});

  Future<List<SchoolClassEntity>> getClasses();
  Future<void> updateSectionCapacity(int sectionId, int capacity);

  Future<List<AdminSetupEntity>> getSources();
  Future<List<AdminSetupEntity>> getReferences();

  Future<AnalyticsDataEntity> getAnalyticsOverview({required String period});

  Future<Map<String, dynamic>> generateAiMessage(int leadId);
  Future<void> sendInquiryAction(int id, String channel, Map<String, dynamic> body);
}
