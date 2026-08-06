import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/notes_remote_datasource.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';

final notesRemoteDataSourceProvider = Provider<NotesRemoteDataSource>((ref) {
  return NotesRemoteDataSource(ref.watch(dioClientProvider));
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepositoryImpl(ref.watch(notesRemoteDataSourceProvider));
});

/// Notes for whatever screen the user is currently on — auto-refetches on
/// navigation since it watches [currentRoutePathProvider].
final notesForCurrentRouteProvider = FutureProvider.autoDispose<List<NoteEntity>>((ref) {
  final path = ref.watch(currentRoutePathProvider);
  return ref.watch(notesRepositoryProvider).getNotes(route: path, archived: false);
});

/// All of the current user's notes (any route), for the "All Notes" sheet.
final allNotesProvider = FutureProvider.autoDispose<List<NoteEntity>>((ref) {
  return ref.watch(notesRepositoryProvider).getNotes();
});

Future<void> createNoteForCurrentRoute(WidgetRef ref, String color) async {
  final path = ref.read(currentRoutePathProvider);
  await ref.read(notesRepositoryProvider).createNote(route: path, color: color);
  ref.invalidate(notesForCurrentRouteProvider);
  ref.invalidate(allNotesProvider);
}

Future<void> updateNote(WidgetRef ref, int id, {String? text, bool? pinned, bool? archived}) async {
  await ref.read(notesRepositoryProvider).updateNote(id, text: text, pinned: pinned, archived: archived);
  ref.invalidate(notesForCurrentRouteProvider);
  ref.invalidate(allNotesProvider);
}

Future<void> deleteNote(WidgetRef ref, int id) async {
  await ref.read(notesRepositoryProvider).deleteNote(id);
  ref.invalidate(notesForCurrentRouteProvider);
  ref.invalidate(allNotesProvider);
}
