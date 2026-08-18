/// Shared exception type for the Parent feature slice's repository, same
/// shape as `TeacherApiException`/`HrApiException` elsewhere in the app.
class ParentApiException implements Exception {
  final String message;
  const ParentApiException(this.message);

  @override
  String toString() => message;
}
