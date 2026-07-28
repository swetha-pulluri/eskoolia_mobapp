/// GET/POST /api/v1/fees/reconciliations/ item — apps/fees Reconciliation.
/// Reference: frontend lib/fees-api.ts::FeesReconciliation.
class FeesReconciliation {
  final int? id;
  final String reference;
  final String amount;
  final String method; // bank | online | cheque | wallet | cash
  final String date; // YYYY-MM-DD
  final String status; // matched | review | needs_mapping
  final String? matchNote;
  final int score;
  final String? notes;
  final String? createdAt;

  const FeesReconciliation({
    this.id,
    required this.reference,
    required this.amount,
    required this.method,
    required this.date,
    required this.status,
    this.matchNote,
    this.score = 0,
    this.notes,
    this.createdAt,
  });

  factory FeesReconciliation.fromJson(Map<String, dynamic> json) {
    return FeesReconciliation(
      id: json['id'] as int?,
      reference: (json['reference'] as String?) ?? '',
      amount: json['amount']?.toString() ?? '0',
      method: (json['method'] as String?) ?? 'bank',
      date: (json['date'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'review',
      matchNote: json['match_note'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'reference': reference,
        'amount': amount,
        'method': method,
        'date': date,
        'status': status,
        'match_note': matchNote ?? '',
        'notes': notes ?? '',
        'score': score,
      };
}
