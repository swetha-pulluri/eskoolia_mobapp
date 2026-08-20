import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_remote_datasource.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesRemoteDataSource _dataSource;

  NotesRepositoryImpl(this._dataSource);

  @override
  Future<List<NoteEntity>> getNotes({String? route, bool? pinned, bool? archived, bool silent = false}) =>
      _dataSource.getNotes(route: route, pinned: pinned, archived: archived, silent: silent);

  @override
  Future<NoteEntity> createNote({required String route, required String color}) =>
      _dataSource.createNote(route: route, color: color);

  @override
  Future<NoteEntity> updateNote(int id, {String? text, bool? pinned, bool? archived}) =>
      _dataSource.updateNote(id, text: text, pinned: pinned, archived: archived);

  @override
  Future<void> deleteNote(int id) => _dataSource.deleteNote(id);
}
