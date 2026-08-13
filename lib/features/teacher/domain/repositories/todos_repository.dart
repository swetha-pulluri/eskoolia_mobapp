import '../entities/todo_item_entity.dart';

abstract class TodosRepository {
  Future<List<TodoItemEntity>> getTodos({String? category});
  Future<TodoItemEntity> createTodo({required String text, required String category});
  Future<TodoItemEntity> updateTodo(int id, {bool? completed});
  Future<void> deleteTodo(int id);
}
