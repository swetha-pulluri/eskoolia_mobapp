import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/shared_prefs.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/entities/pin_item_entity.dart';
import '../../domain/entities/recent_item_entity.dart';
import '../../domain/entities/module_entity.dart';

// Dependencies
final dashboardRemoteDataSourceProvider = Provider((ref) {
  return DashboardRemoteDataSource(ref.watch(dioClientProvider));
});

final dashboardLocalDataSourceProvider = Provider((ref) {
  return DashboardLocalDataSource(ref.watch(sharedPrefsProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    ref.watch(dashboardRemoteDataSourceProvider),
    ref.watch(dashboardLocalDataSourceProvider),
  );
});

// dioClientProvider is defined in auth_providers.dart and reused here.
final sharedPrefsProvider = Provider((ref) => SharedPrefs());

// Attention Count Provider
final attentionCountProvider = FutureProvider<int>((ref) async {
  debugPrint('[DashboardProvider] attentionCountProvider: fetching...');
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getAttentionCount();
  debugPrint('[DashboardProvider] attentionCountProvider: result=$result');
  return result;
});

// Recent Modules Provider
final recentModulesProvider = FutureProvider<List<RecentItemEntity>>((ref) async {
  debugPrint('[DashboardProvider] recentModulesProvider: fetching...');
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getRecentModules();
  debugPrint('[DashboardProvider] recentModulesProvider: result count=${result.length}');
  return result;
});

/// Records a real navigation to [path] as a "Recently Visited" entry and
/// refreshes [recentModulesProvider] so the Home screen reflects it
/// immediately — called from every tile that actually navigates
/// (QuickAccessGrid, ModuleGrid, RecentsRow), not from "Coming Soon" taps.
Future<void> recordModuleVisit(WidgetRef ref, String path) async {
  await ref.read(dashboardRepositoryProvider).recordVisit(path);
  ref.invalidate(recentModulesProvider);
}

// Pins Provider (StateNotifier for CRUD operations)
final pinsProvider = StateNotifierProvider<PinsNotifier, AsyncValue<List<PinItemEntity>>>((ref) {
  return PinsNotifier(ref.watch(dashboardRepositoryProvider));
});

class PinsNotifier extends StateNotifier<AsyncValue<List<PinItemEntity>>> {
  final DashboardRepository _repository;

  PinsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadPins();
  }

  Future<void> _loadPins() async {
    state = const AsyncValue.loading();
    debugPrint('[DashboardProvider] PinsNotifier: loading pins...');
    try {
      final pins = await _repository.getPins();
      debugPrint('[DashboardProvider] PinsNotifier: loaded ${pins.length} pins');
      state = AsyncValue.data(pins);
    } catch (e, stack) {
      debugPrint('[DashboardProvider] PinsNotifier: FAILED: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPin(PinItemEntity pin) async {
    // Check max pins
    final currentPins = state.value ?? [];
    if (currentPins.length >= 12) {
      throw Exception('Maximum 12 pins allowed');
    }

    try {
      await _repository.addPin(pin);
      await _loadPins();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removePin(String path) async {
    try {
      await _repository.removePin(path);
      await _loadPins();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadPins();
  }
}

// Module Visibility Provider
final moduleVisibilityProvider = StateNotifierProvider<ModuleVisibilityNotifier, Map<String, bool>>((ref) {
  return ModuleVisibilityNotifier(ref.watch(dashboardRepositoryProvider));
});

class ModuleVisibilityNotifier extends StateNotifier<Map<String, bool>> {
  final DashboardRepository _repository;

  ModuleVisibilityNotifier(this._repository) : super({}) {
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    try {
      final visibility = await _repository.getModuleVisibility();
      state = visibility;
    } catch (e) {
      // Set all to visible on error
      final defaultVisibility = <String, bool>{};
      for (final module in Modules.all) {
        defaultVisibility[module.id] = true;
      }
      state = defaultVisibility;
    }
  }

  Future<void> toggleVisibility(String moduleId) async {
    try {
      await _repository.toggleModuleVisibility(moduleId);
      await _loadVisibility();
    } catch (e) {
      rethrow;
    }
  }

  bool isVisible(String moduleId) {
    return state[moduleId] ?? true;
  }

  List<ModuleEntity> get visibleModules {
    return Modules.all.where((module) => isVisible(module.id)).toList();
  }
}

// Visible Modules Provider (convenience)
final visibleModulesProvider = Provider<List<ModuleEntity>>((ref) {
  final visibility = ref.watch(moduleVisibilityProvider);
  return Modules.all.where((module) => visibility[module.id] ?? true).toList();
});
