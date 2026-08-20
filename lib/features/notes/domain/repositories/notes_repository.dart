import '../entities/note_entity.dart';

abstract class NotesRepository {
  Future<List<NoteEntity>> getNotes({String? route, bool? pinned, bool? archived, bool silent = false});
  Future<NoteEntity> createNote({required String route, required String color});
  Future<NoteEntity> updateNote(int id, {String? text, bool? pinned, bool? archived});
  Future<void> deleteNote(int id);
}

class NotesApiException implements Exception {
  final String message;
  const NotesApiException(this.message);

  @override
  String toString() => message;
}
