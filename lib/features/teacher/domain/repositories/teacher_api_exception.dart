/// Shared exception type for the Teacher feature slice's repositories
/// (Teacher Me, Todos, Broadcast) — same shape as `HrApiException`/
/// `NotesApiException` elsewhere in the app.
class TeacherApiException implements Exception {
  final String message;
  const TeacherApiException(this.message);

  @override
  String toString() => message;
}
