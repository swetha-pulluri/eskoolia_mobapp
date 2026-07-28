import '../../../data/local/shared_prefs.dart';
import '../domain/models/ai_todo_item.dart';

const _todosKey = 'eskoolia_todos';

/// SharedPrefs-backed to-do store — mirrors AIBot.tsx's own
/// `localStorage.getItem/setItem('eskoolia_todos')` persistence exactly,
/// reusing the same [SharedPrefs] singleton already used by the Dashboard's
/// pins/recents store.
class AiTodoStore {
  Future<List<AiTodoItem>> load() async {
    final raw = SharedPrefs().getJsonList(_todosKey);
    if (raw == null) return [];
    return raw.map(AiTodoItem.fromJson).toList();
  }

  Future<void> save(List<AiTodoItem> todos) async {
    await SharedPrefs().setJsonList(_todosKey, todos.map((t) => t.toJson()).toList());
  }
}
