import '../entities/pin_item_entity.dart';
import '../entities/recent_item_entity.dart';
import '../models/kpi_data.dart';

/// Dashboard Repository Interface
abstract class DashboardRepository {
  // KPIs
  Future<KpiData> getKpis();

  // Attention count
  Future<int> getAttentionCount();

  // Recent modules
  Future<List<RecentItemEntity>> getRecentModules({int limit = 8});
  Future<void> recordVisit(String path);

  // Pins management
  Future<List<PinItemEntity>> getPins();
  Future<void> addPin(PinItemEntity pin);
  Future<void> removePin(String path);
  Future<void> savePins(List<PinItemEntity> pins);
  
  // Module visibility
  Future<Map<String, bool>> getModuleVisibility();
  Future<void> toggleModuleVisibility(String moduleId);
  Future<void> saveModuleVisibility(Map<String, bool> visibility);
}
