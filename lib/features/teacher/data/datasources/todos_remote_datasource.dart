import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/todo_item_entity.dart';
import '../../domain/repositories/teacher_api_exception.dart';

/// Calls the real, implemented `apps.todos` endpoints (`TodoItemViewSet`,
/// bare JSON array responses, no pagination envelope — same convention as
/// Notes). Shared between Admin and Teacher (the backend scopes by
/// school+user, not role).
class TodosRemoteDataSource {
  final DioClient _dioClient;

  TodosRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String) throw TeacherApiException(rawMessage);
      if (rawMessage != null) throw TeacherApiException(rawMessage.toString());
    }
    throw TeacherApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  Future<List<TodoItemEntity>> getTodos({String? category}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.todos,
        queryParameters: {'category': ?category},
      );
      final list = response.data as List;
      return list.map((e) => TodoItemEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get todos error', e);
      _throwApiException(e);
    }
  }

  Future<TodoItemEntity> createTodo({required String text, required String category}) async {
    try {
      final response = await _dioClient.post(ApiConstants.todos, data: {'text': text, 'category': category});
      return TodoItemEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<TodoItemEntity> updateTodo(int id, {bool? completed}) async {
    try {
      final response = await _dioClient.patch(
        ApiConstants.todoDetail(id),
        data: {'completed': ?completed},
      );
      return TodoItemEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _dioClient.delete(ApiConstants.todoDetail(id));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }
}
