import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../data/local/shared_prefs.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart' show sharedPrefsProvider;
import '../../domain/entities/week_planner_entry.dart';

/// Local-only "Week Ahead" planner state, persisted via the existing
/// `SharedPrefs` wrapper — same pattern as `WidgetPrefsNotifier`
/// (`widget_prefs_provider.dart`). Matches web's own `WeekAhead.tsx`,
/// which is genuinely just a localStorage-backed planner (see
/// `week_planner_entry.dart`'s doc comment for why).
class WeekPlannerNotifier extends StateNotifier<List<WeekPlannerEntry>> {
  final SharedPrefs _prefs;

  WeekPlannerNotifier(this._prefs) : super(const []) {
    _load();
  }

  void _load() {
    final saved = _prefs.getJsonList(StorageKeys.teacherWeekPlanner) ?? const [];
    state = saved.map(WeekPlannerEntry.fromJson).toList();
  }

  Future<void> addEntry({required String date, required String text}) async {
    if (text.trim().isEmpty) return;
    final entry = WeekPlannerEntry(id: DateTime.now().microsecondsSinceEpoch.toString(), date: date, text: text.trim());
    state = [...state, entry];
    await _persist();
  }

  Future<void> removeEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _persist();
  }

  Future<void> _persist() async {
    await _prefs.setJsonList(StorageKeys.teacherWeekPlanner, state.map((e) => e.toJson()).toList());
  }
}

final weekPlannerProvider = StateNotifierProvider<WeekPlannerNotifier, List<WeekPlannerEntry>>((ref) {
  return WeekPlannerNotifier(ref.watch(sharedPrefsProvider));
});
