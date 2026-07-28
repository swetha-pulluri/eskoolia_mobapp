/// Matches the real `StaffAttendanceImportBulkAPIView`'s response shape
/// (`apps/hr/attendance_endpoints.py` on `origin/demo`) —
/// `{success, message, data: {imported, failed, errors}}`.
class AttendanceImportResultEntity {
  final int imported;
  final int failed;
  final List<String> errors;

  const AttendanceImportResultEntity({this.imported = 0, this.failed = 0, this.errors = const []});

  factory AttendanceImportResultEntity.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    final rawErrors = (data['errors'] as List?) ?? const [];
    return AttendanceImportResultEntity(
      imported: data['imported'] as int? ?? 0,
      failed: data['failed'] as int? ?? 0,
      errors: rawErrors.map((e) => e is Map ? '${e['row'] != null ? 'Row ${e['row']}: ' : ''}${e['message'] ?? e.toString()}' : e.toString()).toList(),
    );
  }
}
