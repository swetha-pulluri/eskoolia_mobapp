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
  // Raw ISO paid_at string, kept alongside the parsed [paidAt] DateTime so
  // callers that need the exact `YYYY-MM-DD` portion (e.g. the Collection
  // screen's ledger date) don't have to reformat a DateTime that may have
  // silently fallen back to DateTime.now() when paid_at was missing/invalid.
  final String paidAtRaw;
  // Present at runtime (read by frontend components/fees/FeesCollectionPanel.tsx
  // as `p.status`) even though it isn't declared on the frontend's own
  // `FeesPayment` TS type (that type is only ever read through `any[]`
  // state there). posted | pending_clearance | pending_reconciliation |
  // pending_verification | reversed.
  final String? status;

  const FeesPayment({
    required this.id,
    required this.assignment,
    required this.student,
    required this.amountPaid,
    required this.method,
    this.transactionReference,
    this.note,
    required this.paidAt,
    this.paidAtRaw = '',
    this.status,
  });

  factory FeesPayment.fromJson(Map<String, dynamic> json) {
    final rawPaidAt = (json['paid_at'] as String?) ?? '';
    return FeesPayment(
      id: json['id'] as int,
      assignment: json['assignment'] as int,
      student: json['student'] as int,
      amountPaid: json['amount_paid']?.toString() ?? '0',
      method: (json['method'] as String?) ?? '',
      transactionReference: json['transaction_reference'] as String?,
      note: json['note'] as String?,
      paidAt: DateTime.tryParse(rawPaidAt) ?? DateTime.now(),
      paidAtRaw: rawPaidAt,
      status: json['status'] as String?,
    );
  }
}
