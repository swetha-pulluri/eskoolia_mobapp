/// GET/POST/PATCH /api/v1/fees/assignments/ — apps/fees::FeeAssignment.
/// One row per (student, fees_type) — the unit FeesAssignmentPanel.tsx
/// reads/writes when assigning a fee group to a student (one assignment
/// per fee type in that group's schedule).
class FeeAssignment {
  final int id;
  final int academicYear;
  final int student;
  final int feesType;
  final String? feesTypeName;
  final String dueDate;
  final String amount;
  final String discountAmount;
  final String concessionAmount;
  final String status; // unpaid | partial | paid
  // Present on list/detail responses read by the Collection screen — net
  // amount still owed after posted payments (amount - discount - concession
  // - posted payments). Absent from the create/update payload this app
  // sends, so it stays nullable; falls back to `amount` when absent.
  final String? netDue;

  const FeeAssignment({
    required this.id,
    required this.academicYear,
    required this.student,
    required this.feesType,
    this.feesTypeName,
    this.dueDate = '',
    required this.amount,
    this.discountAmount = '0.00',
    this.concessionAmount = '0.00',
    this.status = 'unpaid',
    this.netDue,
  });

  factory FeeAssignment.fromJson(Map<String, dynamic> json) {
    return FeeAssignment(
      id: json['id'] as int,
      academicYear: json['academic_year'] as int,
      student: json['student'] as int,
      feesType: json['fees_type'] as int,
      feesTypeName: json['fees_type_name'] as String?,
      dueDate: (json['due_date'] as String?) ?? '',
      amount: json['amount']?.toString() ?? '0',
      discountAmount: json['discount_amount']?.toString() ?? '0.00',
      concessionAmount: json['concession_amount']?.toString() ?? '0.00',
      status: (json['status'] as String?) ?? 'unpaid',
      netDue: json['net_due']?.toString(),
    );
  }
}
