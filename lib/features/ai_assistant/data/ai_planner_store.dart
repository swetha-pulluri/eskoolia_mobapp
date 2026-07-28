import '../../../data/local/shared_prefs.dart';

/// SharedPrefs-backed planner writer — mirrors AIBot.tsx's own
/// `localStorage.setItem('eskoolia_week_events_v2_{mondayDate}', ...)`
/// exactly (same key format, same event shape). Write-only: the frontend's
/// consuming "Week Ahead" widget has no Flutter equivalent in this app, so
/// — same as web's own bot, which also never reads this data back itself —
/// this only persists the event and reports success; nothing in this app
/// currently displays it.
class AiPlannerStore {
  Future<void> addEvent({required int dayIndex, required String time, required String title}) async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final wk = '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    final key = 'eskoolia_week_events_v2_$wk';
    final existing = SharedPrefs().getJsonList(key) ?? [];
    existing.add({
      'id': 'bot-${DateTime.now().millisecondsSinceEpoch}',
      'dayIndex': dayIndex,
      'time': time,
      'title': title,
      'category': 'meeting',
      'aiGenerated': true,
    });
    await SharedPrefs().setJsonList(key, existing);
  }
}
