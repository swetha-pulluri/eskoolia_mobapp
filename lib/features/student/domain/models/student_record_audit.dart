/// One row of the Deleted/Restore screen's "Audit Log" tab — Source:
/// frontend StudentDeleteRecordPanel.tsx's Audit Log table. Backend:
/// GET /api/v1/students/record-audits/ (apps/students —
/// StudentRecordAuditSerializer, read-only).
class StudentRecordAudit {
  final int id;
  final String studentName;
  final String studentAdmissionNo;
  final String action;
  final String performedByName;
  final String? note;
  final DateTime createdAt;

  const StudentRecordAudit({
    required this.id,
    required this.studentName,
    required this.studentAdmissionNo,
    required this.action,
    required this.performedByName,
    this.note,
    required this.createdAt,
  });

  /// Mirrors the frontend's action-label mapping (`soft_delete`→"Deleted",
  /// `restore`→"Restored", `permanent_delete`→"Permanently deleted",
  /// `update`→"Updated").
  String get actionLabel {
    switch (action) {
      case 'soft_delete':
        return 'Deleted';
      case 'restore':
        return 'Restored';
      case 'permanent_delete':
        return 'Permanently deleted';
      case 'update':
        return 'Updated';
      default:
        return action;
    }
  }

  factory StudentRecordAudit.fromJson(Map<String, dynamic> json) {
    return StudentRecordAudit(
      id: json['id'] as int,
      studentName: (json['student_name'] as String?) ?? '-',
      studentAdmissionNo: (json['student_admission_no'] as String?) ?? '-',
      action: (json['action'] as String?) ?? '',
      performedByName: (json['performed_by_name'] as String?) ?? '-',
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
