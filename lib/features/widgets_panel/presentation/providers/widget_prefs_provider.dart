import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../data/local/shared_prefs.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart' show sharedPrefsProvider;
import '../../domain/entities/widget_def_entity.dart';

/// Per-widget on/off preference, mirroring web's `widgetStore.ts` exactly —
/// this is purely local/client-only on web too (plain `localStorage`, no
/// backend concept), so this notifier persists directly via the existing
/// [SharedPrefs] wrapper rather than adding a repository/datasource layer.
class WidgetPrefsNotifier extends StateNotifier<Map<String, bool>> {
  final SharedPrefs _prefs;

  WidgetPrefsNotifier(this._prefs) : super({}) {
    _load();
  }

  void _load() {
    final saved = _prefs.getJson(StorageKeys.widgetPrefs) ?? const {};
    final merged = <String, bool>{};
    for (final w in allWidgets) {
      final savedValue = saved[w.id];
      // Disabled widgets are always forced off on load, matching
      // `widgetStore.ts`'s own `_loadOnce` rule.
      merged[w.id] = w.disabled ? false : (savedValue is bool ? savedValue : w.defaultEnabled);
    }
    state = merged;
  }

  Future<void> toggle(String id) async {
    final widget = allWidgets.where((w) => w.id == id).firstOrNull;
    if (widget == null || widget.disabled) return;
    final next = Map<String, bool>.from(state);
    next[id] = !(state[id] ?? widget.defaultEnabled);
    state = next;
    await _prefs.setJson(StorageKeys.widgetPrefs, next);
  }

  bool isEnabled(String id) {
    final widget = allWidgets.where((w) => w.id == id).firstOrNull;
    return state[id] ?? widget?.defaultEnabled ?? false;
  }
}

final widgetPrefsProvider = StateNotifierProvider<WidgetPrefsNotifier, Map<String, bool>>((ref) {
  return WidgetPrefsNotifier(ref.watch(sharedPrefsProvider));
});

/// Current role, mirroring web's `(me?.portal_type as PortalRole) ?? 'admin'`
/// fallback — reuses the already-authenticated user, no new lookup.
final currentPortalRoleProvider = Provider<String>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.maybeWhen(authenticated: (u) => u, orElse: () => null);
  final portalType = user?.portalType;
  if (portalType == 'teacher' || portalType == 'parent' || portalType == 'student') return portalType!;
  return 'admin';
});

/// Feeds the header "Widgets" badge — count of widgets enabled for the
/// current role, excluding permanently-disabled ones.
final enabledWidgetCountProvider = Provider<int>((ref) {
  final role = ref.watch(currentPortalRoleProvider);
  final prefs = ref.watch(widgetPrefsProvider);
  return widgetsForRole(role).where((w) => !w.disabled && (prefs[w.id] ?? w.defaultEnabled)).length;
});
