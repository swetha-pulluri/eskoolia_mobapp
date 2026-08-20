import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';

/// Notes Remote Data Source — calls the real, wired `apps.notes` Django
/// endpoints (`NoteViewSet`, `pagination_class = None`) at
/// [ApiConstants.notesBasePath]. Unlike HR's endpoints, list/create/update
/// responses are bare objects/arrays with no `{success,data}` envelope, so
/// there is no `_unwrap` step here.
class NotesRemoteDataSource {
  final DioClient _dioClient;

  NotesRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String) throw NotesApiException(rawMessage);
      if (rawMessage != null) throw NotesApiException(rawMessage.toString());
    }
    throw NotesApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  // `silent` covers the header note-badge's background poll (`route` set,
  // called from `notesForCurrentRouteProvider` every navigation) — when the
  // session expires mid-use, this can fire the instant before `GlobalAppShell`
  // unmounts it, hitting a 401 that's already silently swallowed by the
  // badge's own `.maybeWhen(orElse: () => 0)`. Not used for the "All Notes"
  // sheet's own explicit fetch, where a failure should still surface normally.
  Future<List<NoteEntity>> getNotes({String? route, bool? pinned, bool? archived, bool silent = false}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.notes,
        queryParameters: {
          'route': ?route,
          'pinned': ?pinned,
          'archived': ?archived,
        },
        silent: silent,
      );
      final list = response.data as List;
      return list.map((e) => NoteEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (!silent) AppLogger.error('Get notes error', e);
      _throwApiException(e);
    }
  }

  Future<NoteEntity> createNote({required String route, required String color}) async {
    try {
      final response = await _dioClient.post(ApiConstants.notes, data: {'route': route, 'color': color});
      return NoteEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<NoteEntity> updateNote(int id, {String? text, bool? pinned, bool? archived}) async {
    try {
      final response = await _dioClient.patch(
        ApiConstants.noteDetail(id),
        data: {
          'text': ?text,
          'pinned': ?pinned,
          'archived': ?archived,
        },
      );
      return NoteEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _dioClient.delete(ApiConstants.noteDetail(id));
    } on DioException catch (e) {
      _throwApiException(e);
    }
  }
}
