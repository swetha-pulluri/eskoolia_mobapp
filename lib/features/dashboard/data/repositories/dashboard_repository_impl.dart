import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/entities/pin_item_entity.dart';
import '../../domain/entities/recent_item_entity.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../datasources/dashboard_local_datasource.dart';

/// Dashboard Repository Implementation
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;
  final DashboardLocalDataSource _localDataSource;

  DashboardRepositoryImpl(this._remoteDataSource, this._localDataSource);

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
