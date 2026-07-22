import '../../../../core/constants/storage_keys.dart';
import '../../../../data/local/shared_prefs.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/pin_item_entity.dart';
import '../../domain/entities/recent_item_entity.dart';
import '../../domain/entities/module_entity.dart';

/// Dashboard Local Data Source
class DashboardLocalDataSource {
  final SharedPrefs _sharedPrefs;

  DashboardLocalDataSource(this._sharedPrefs);

  // Pins Management
  Future<List<PinItemEntity>> getPins() async {
    try {
      final pinsJson = _sharedPrefs.getJsonList(StorageKeys.pinnedModules);
      
      if (pinsJson == null || pinsJson.isEmpty) {
        // Return default pins on first launch
        await savePins(DefaultPins.all);
        return DefaultPins.all;
      }
      
      return pinsJson.map((json) => PinItemEntity.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Get pins error', e);
      return DefaultPins.all;
    }
  }

  Future<void> savePins(List<PinItemEntity> pins) async {
    try {
      final pinsJson = pins.map((pin) => pin.toJson()).toList();
      await _sharedPrefs.setJsonList(StorageKeys.pinnedModules, pinsJson);
    } catch (e) {
      AppLogger.error('Save pins error', e);
    }
  }

  Future<void> addPin(PinItemEntity pin) async {
    try {
      final currentPins = await getPins();
      
      // Check if pin already exists
      if (currentPins.any((p) => p.path == pin.path)) {
        return;
      }
      
      currentPins.add(pin);
      await savePins(currentPins);
    } catch (e) {
      AppLogger.error('Add pin error', e);
    }
  }

  Future<void> removePin(String path) async {
    try {
      final currentPins = await getPins();
      currentPins.removeWhere((pin) => pin.path == path);
      await savePins(currentPins);
    } catch (e) {
      AppLogger.error('Remove pin error', e);
    }
  }

  // Module Visibility
  Future<Map<String, bool>> getModuleVisibility() async {
    try {
      final visibilityJson = _sharedPrefs.getJson(StorageKeys.moduleVisibility);
      
      if (visibilityJson == null) {
        // All modules visible by default
        final defaultVisibility = <String, bool>{};
        for (final module in Modules.all) {
          defaultVisibility[module.id] = true;
        }
        await saveModuleVisibility(defaultVisibility);
        return defaultVisibility;
      }
      
      return visibilityJson.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      AppLogger.error('Get module visibility error', e);
      final defaultVisibility = <String, bool>{};
      for (final module in Modules.all) {
        defaultVisibility[module.id] = true;
      }
      return defaultVisibility;
    }
  }

  Future<void> saveModuleVisibility(Map<String, bool> visibility) async {
    try {
      await _sharedPrefs.setJson(StorageKeys.moduleVisibility, visibility);
    } catch (e) {
      AppLogger.error('Save module visibility error', e);
    }
  }

  Future<void> toggleModuleVisibility(String moduleId) async {
    try {
      final visibility = await getModuleVisibility();
      visibility[moduleId] = !(visibility[moduleId] ?? true);
      await saveModuleVisibility(visibility);
    } catch (e) {
      AppLogger.error('Toggle module visibility error', e);
    }
  }

  // Recent Modules (local storage as fallback)
  Future<List<RecentItemEntity>> getLocalRecentModules() async {
    try {
      final recentsJson = _sharedPrefs.getJsonList(StorageKeys.recentModules);
      
      if (recentsJson == null) {
        return [];
      }
      
      return recentsJson
          .map((json) => RecentItemEntity.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Get local recent modules error', e);
      return [];
    }
  }

  Future<void> saveLocalRecentModules(List<RecentItemEntity> recents) async {
    try {
      final recentsJson = recents.map((r) => r.toJson()).toList();
      await _sharedPrefs.setJsonList(StorageKeys.recentModules, recentsJson);
    } catch (e) {
      AppLogger.error('Save local recent modules error', e);
    }
  }
}
