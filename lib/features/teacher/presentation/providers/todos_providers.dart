import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/todos_remote_datasource.dart';
import '../../data/repositories/todos_repository_impl.dart';
import '../../domain/entities/todo_item_entity.dart';
import '../../domain/repositories/todos_repository.dart';

final todosRemoteDataSourceProvider = Provider<TodosRemoteDataSource>((ref) {
  return TodosRemoteDataSource(ref.watch(dioClientProvider));
});

final todosRepositoryProvider = Provider<TodosRepository>((ref) {
  return TodosRepositoryImpl(ref.watch(todosRemoteDataSourceProvider));
});

/// `'all'` (the default UI tab) means "no category filter" — matches web's
/// own `SmartTodoList.tsx` (`?category=` is only appended when the active
/// tab isn't `all`).
final selectedTodoCategoryProvider = StateProvider.autoDispose<String>((ref) => 'all');

final todosProvider = FutureProvider.autoDispose<List<TodoItemEntity>>((ref) {
  final category = ref.watch(selectedTodoCategoryProvider);
  return ref.watch(todosRepositoryProvider).getTodos(category: category == 'all' ? null : category);
});

// Every mutation below follows the same shape: `finally { ref.invalidate(...) }`,
// not a plain sequential `await ...; ref.invalidate(...)`. If the request
// throws (network hiccup, or — for create/update — the response body
// failing to parse even though the row was actually written server-side),
// a plain sequential call skipped the invalidate entirely: the backend
// change could be real, but the list never refetched to show it. The
// refetch must always run so a genuine change still shows up; the
// exception still propagates to the caller afterward so a real failure
// isn't silently hidden either.

Future<void> createTodo(WidgetRef ref, {required String text, required String category}) async {
  try {
    await ref.read(todosRepositoryProvider).createTodo(text: text, category: category);
  } finally {
    ref.invalidate(todosProvider);
  }
}

Future<void> toggleTodoCompleted(WidgetRef ref, TodoItemEntity todo) async {
  try {
    await ref.read(todosRepositoryProvider).updateTodo(todo.id, completed: !todo.completed);
  } finally {
    ref.invalidate(todosProvider);
  }
}

Future<void> deleteTodoItem(WidgetRef ref, int id) async {
  try {
    await ref.read(todosRepositoryProvider).deleteTodo(id);
  } finally {
    ref.invalidate(todosProvider);
  }
}
