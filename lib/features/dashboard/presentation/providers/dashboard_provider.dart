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
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.getAttentionCount();
});

// Recent Modules Provider
final recentModulesProvider = FutureProvider<List<RecentItemEntity>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.getRecentModules();
});

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
    try {
      final pins = await _repository.getPins();
      state = AsyncValue.data(pins);
    } catch (e, stack) {
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
