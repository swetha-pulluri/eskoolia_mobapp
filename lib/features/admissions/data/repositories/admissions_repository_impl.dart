import '../../../administration/domain/entities/admin_setup_entity.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/entities/school_class_entity.dart';
import '../../domain/entities/analytics_data_entity.dart';
import '../../domain/repositories/admissions_repository.dart';
import '../datasources/admissions_remote_datasource.dart';

/// Keeps a lightweight cache of the last-fetched inquiries so
/// [updateInquiry]'s functional-update signature — `(id, current => next)`
/// — can resolve "current" the same way the module's widgets already
/// expect, without every call site needing to pass its own copy of the
/// record. Populated by [getInquiries]; individual mutations patch it
/// in place with the server's real response.
class AdmissionsRepositoryImpl implements AdmissionsRepository {
  final AdmissionsRemoteDataSource _remote;
  List<InquiryEntity> _cache = const [];

  AdmissionsRepositoryImpl(this._remote);

  @override
  Future<List<InquiryEntity>> getInquiries() async {
    final result = await _remote.getInquiries();
    _cache = result.results;
    return _cache;
  }

  @override
  Future<InquiryEntity> createInquiry(InquiryEntity draft) async {
    final created = await _remote.createInquiry(draft.toJson());
    _cache = [created, ..._cache];
    return created;
  }

  @override
  Future<InquiryEntity> updateInquiry(int id, InquiryEntity Function(InquiryEntity current) update) async {
    final current = _cache.where((i) => i.id == id).firstOrNull ?? InquiryEntity(id: id, fullName: '', phone: '');
    final next = update(current);
    final saved = await _remote.updateInquiry(id, next.toJson());
    final index = _cache.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _cache = List.of(_cache)..[index] = saved;
    } else {
      _cache = [saved, ..._cache];
    }
    return saved;
  }

  @override
  Future<void> deleteInquiry(int id) async {
    await _remote.deleteInquiry(id);
    _cache = _cache.where((i) => i.id != id).toList();
  }

  @override
  Future<InquiryEntity> mergeInquiries({required int keepId, required int absorbId}) async {
    final kept = await _remote.mergeInquiry(keepId, absorbId);
    final index = _cache.indexWhere((i) => i.id == keepId);
    _cache = [
      for (final i in _cache)
        if (i.id == keepId)
          kept
        else if (i.id != absorbId)
          i,
    ];
    if (index < 0) _cache = [kept, ..._cache];
    return kept;
  }

  @override
  Future<List<SchoolClassEntity>> getClasses() => _remote.getClasses().then((r) => r.results);

  @override
  Future<void> updateSectionCapacity(int sectionId, int capacity) => _remote.updateSectionCapacity(sectionId, capacity);

  @override
  Future<List<AdminSetupEntity>> getSources() => _remote.getAdminSetupOptions('3');

  @override
  Future<List<AdminSetupEntity>> getReferences() => _remote.getAdminSetupOptions('4');

  @override
  Future<AnalyticsDataEntity> getAnalyticsOverview({required String period}) => _remote.getAnalyticsOverview(period: period);

  @override
  Future<Map<String, dynamic>> generateAiMessage(int leadId) => _remote.generateAiMessage(leadId);

  @override
  Future<void> sendInquiryAction(int id, String channel, Map<String, dynamic> body) => _remote.sendInquiryAction(id, channel, body);
}
