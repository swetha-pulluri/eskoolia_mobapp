/// Shared exception type for the Reports feature slice's repository — same
/// shape as `HrApiException`/`SchoolTenancyApiException` elsewhere in the
/// app.
class ReportsApiException implements Exception {
  final String message;
  const ReportsApiException(this.message);

  @override
  String toString() => message;
}
