/// GET/POST /api/v1/fees/dues/interactions/ item.
/// Reference: frontend lib/fees-api.ts::DueInteraction.
class DueInteraction {
  final int id;
  final String student;
  final String interactionType; // always "note" from this screen
  final String note;
  final String? agreedAmount;
  final String? agreedDate;
  final bool isResolved;
  final int createdBy;
  final String createdByName;
  final String createdAt; // ISO datetime

  const DueInteraction({
    required this.id,
    required this.student,
    required this.interactionType,
    required this.note,
    this.agreedAmount,
    this.agreedDate,
    this.isResolved = false,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  factory DueInteraction.fromJson(Map<String, dynamic> json) {
    return DueInteraction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      student: json['student']?.toString() ?? '',
      interactionType: (json['interaction_type'] as String?) ?? 'note',
      note: (json['note'] as String?) ?? '',
      agreedAmount: json['agreed_amount'] as String?,
      agreedDate: json['agreed_date'] as String?,
      isResolved: (json['is_resolved'] as bool?) ?? false,
      createdBy: (json['created_by'] as num?)?.toInt() ?? 0,
      createdByName: (json['created_by_name'] as String?) ?? '',
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }
}
