import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/entities/pin_item_entity.dart';
import '../../domain/entities/recent_item_entity.dart';
import '../../domain/models/kpi_data.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../../../../core/utils/logger.dart';

/// Dashboard Repository Implementation
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;
  final DashboardLocalDataSource _localDataSource;

  DashboardRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<KpiData> getKpis() async {
    try {
      return await _remoteDataSource.getKpis();
    } catch (e) {
      AppLogger.error('Get KPIs error', e);
      // All-null KpiData renders every card as "—", same honest-empty
      // convention already used for individual missing fields, rather than
      // showing stale/fake numbers on a real fetch failure.
      return const KpiData();
    }
  }

  @override
  Future<int> getAttentionCount() async {
    try {
      return await _remoteDataSource.getAttentionCount();
    } catch (e) {
      // NOTE: Backend endpoint /api/dashboard/attention-count/ doesn't exist yet.
      // Return 0 to gracefully handle missing endpoint (like web frontend does).
      return 0;
    }
  }

  @override
  Future<List<RecentItemEntity>> getRecentModules({int limit = 8}) async {
    // NOTE: Backend has NO /api/user/recents/ endpoint.
    // Web frontend uses localStorage ONLY.
    // Use local storage directly.
    return await _localDataSource.getLocalRecentModules();
  }

  @override
  Future<void> recordVisit(String path) async {
    await _localDataSource.recordVisit(path);
  }

  @override
  Future<List<PinItemEntity>> getPins() async {
    return await _localDataSource.getPins();
  }

  @override
  Future<void> addPin(PinItemEntity pin) async {
    await _localDataSource.addPin(pin);
  }

  @override
  Future<void> removePin(String path) async {
    await _localDataSource.removePin(path);
  }

  @override
  Future<void> savePins(List<PinItemEntity> pins) async {
    await _localDataSource.savePins(pins);
  }

  @override
  Future<Map<String, bool>> getModuleVisibility() async {
    return await _localDataSource.getModuleVisibility();
  }

  @override
  Future<void> toggleModuleVisibility(String moduleId) async {
    await _localDataSource.toggleModuleVisibility(moduleId);
  }

  @override
  Future<void> saveModuleVisibility(Map<String, bool> visibility) async {
    await _localDataSource.saveModuleVisibility(visibility);
  }
}
