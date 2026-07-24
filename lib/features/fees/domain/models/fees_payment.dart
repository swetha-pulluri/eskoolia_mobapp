/// GET /api/v1/fees/payments/ item.
/// Reference: backend/apps/fees/models.py::Payment, serializers.py::PaymentSerializer,
/// frontend lib/fees-api.ts::FeesPayment.
class FeesPayment {
  final int id;
  final int assignment;
  final int student;
  final String amountPaid;
  final String method; // cash | bank | online | wallet | cheque
  final String? transactionReference;
  final String? note;
  final DateTime paidAt;

  const FeesPayment({
    required this.id,
    required this.assignment,
    required this.student,
    required this.amountPaid,
    required this.method,
    this.transactionReference,
    this.note,
    required this.paidAt,
  });

  factory FeesPayment.fromJson(Map<String, dynamic> json) {
    return FeesPayment(
      id: json['id'] as int,
      assignment: json['assignment'] as int,
      student: json['student'] as int,
      amountPaid: json['amount_paid']?.toString() ?? '0',
      method: (json['method'] as String?) ?? '',
      transactionReference: json['transaction_reference'] as String?,
      note: json['note'] as String?,
      paidAt: DateTime.tryParse(json['paid_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
