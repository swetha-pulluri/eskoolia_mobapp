import '../entities/pin_item_entity.dart';
import '../entities/recent_item_entity.dart';

/// Dashboard Repository Interface
abstract class DashboardRepository {
  // Attention count
  Future<int> getAttentionCount();
  
  // Recent modules
  Future<List<RecentItemEntity>> getRecentModules({int limit = 8});
  
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
