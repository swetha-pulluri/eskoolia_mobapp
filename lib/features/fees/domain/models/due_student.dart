/// One row of GET /api/v1/fees/dues/by-class/'s `students` array.
/// Reference: frontend lib/fees-api.ts::DueStudent.
class DueStudent {
  final String id;
  final String name;
  final String admNo;
  final String cls;
  final String amountDue; // numeric string, e.g. "12500.00"
  final int daysOverdue;
  final String? lastReminder; // ISO date or null
  // "Overdue" | "Payment Watch" | "Escalated" | "Defaulter" — largely unused
  // client-side; the UI computes its own tier status from [daysOverdue] via
  // `tierStatus()` instead (see fees_dues_format.dart) — this raw field is
  // only ever displayed verbatim in the Late Fee Calculator preview card.
  final String status;
  final bool isResolved;

  const DueStudent({
    required this.id,
    required this.name,
    required this.admNo,
    required this.cls,
    required this.amountDue,
    required this.daysOverdue,
    this.lastReminder,
    required this.status,
    this.isResolved = false,
  });

  factory DueStudent.fromJson(Map<String, dynamic> json) {
    return DueStudent(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      admNo: (json['admNo'] as String?) ?? '',
      cls: (json['cls'] as String?) ?? '',
      amountDue: json['amount_due']?.toString() ?? '0',
      daysOverdue: (json['days_overdue'] as num?)?.toInt() ?? 0,
      lastReminder: json['last_reminder'] as String?,
      status: (json['status'] as String?) ?? 'Overdue',
      isResolved: (json['is_resolved'] as bool?) ?? false,
    );
  }
}
