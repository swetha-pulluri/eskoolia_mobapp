import '../../domain/entities/todo_item_entity.dart';
import '../../domain/repositories/todos_repository.dart';
import '../datasources/todos_remote_datasource.dart';

class TodosRepositoryImpl implements TodosRepository {
  final TodosRemoteDataSource _dataSource;

  TodosRepositoryImpl(this._dataSource);

  @override
  Future<List<TodoItemEntity>> getTodos({String? category}) => _dataSource.getTodos(category: category);

  @override
  Future<TodoItemEntity> createTodo({required String text, required String category}) =>
      _dataSource.createTodo(text: text, category: category);

  @override
  Future<TodoItemEntity> updateTodo(int id, {bool? completed}) => _dataSource.updateTodo(id, completed: completed);

  @override
  Future<void> deleteTodo(int id) => _dataSource.deleteTodo(id);
}
