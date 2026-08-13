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

Future<void> createTodo(WidgetRef ref, {required String text, required String category}) async {
  await ref.read(todosRepositoryProvider).createTodo(text: text, category: category);
  ref.invalidate(todosProvider);
}

Future<void> toggleTodoCompleted(WidgetRef ref, TodoItemEntity todo) async {
  await ref.read(todosRepositoryProvider).updateTodo(todo.id, completed: !todo.completed);
  ref.invalidate(todosProvider);
}

Future<void> deleteTodoItem(WidgetRef ref, int id) async {
  await ref.read(todosRepositoryProvider).deleteTodo(id);
  ref.invalidate(todosProvider);
}
