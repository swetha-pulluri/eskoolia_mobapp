/// One row of `FeeSchedule.term_breakdown` — a passthrough JSON list with no
/// server-side schema (apps/fees::FeeSchedule.term_breakdown is a bare
/// `JSONField(default=list)`). Field names mirror the shape the frontend
/// actually writes: `term_number`/`term_name`/`amount`/`due_date`.
class TermBreakdownSlot {
  final int termNumber;
  final String termName;
  final String amount;
  final String dueDate;

  const TermBreakdownSlot({
    required this.termNumber,
    required this.termName,
    this.amount = '',
    this.dueDate = '',
  });

  factory TermBreakdownSlot.fromJson(Map<String, dynamic> json) {
    return TermBreakdownSlot(
      termNumber: json['term_number'] as int? ?? 0,
      termName: (json['term_name'] as String?) ?? '',
      amount: json['amount']?.toString() ?? '',
      dueDate: (json['due_date'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'term_number': termNumber,
        'term_name': termName,
        'amount': amount,
        'due_date': dueDate,
      };

  TermBreakdownSlot copyWith({String? termName, String? amount, String? dueDate}) {
    return TermBreakdownSlot(
      termNumber: termNumber,
      termName: termName ?? this.termName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

/// GET/POST/PUT/PATCH/DELETE /api/v1/fees/schedules/ — apps/fees::FeeSchedule
/// + FeeScheduleSerializer. `collectionFrequency`/`status` are returned
/// display-cased ("Monthly"/"Term-wise"/etc., "Active"/"Inactive") and
/// accepted back the same way. DELETE on this resource is a soft delete.
class FeeSchedule {
  final int id;
  final int academicYear;
  final String? academicYearName;
  final int? feeGroup;
  final String? feeGroupName;
  final int feeType;
  final String? feeTypeName;
  final String amount;
  final String collectionFrequency;
  final String dueDate;
  final bool lateFeeApplicable;
  final int gracePeriod;
  final String lateFeeRule;
  final List<TermBreakdownSlot> termBreakdown;
  final String status;

  const FeeSchedule({
    required this.id,
    required this.academicYear,
    this.academicYearName,
    this.feeGroup,
    this.feeGroupName,
    required this.feeType,
    this.feeTypeName,
    required this.amount,
    required this.collectionFrequency,
    required this.dueDate,
    this.lateFeeApplicable = false,
    this.gracePeriod = 0,
    this.lateFeeRule = '',
    this.termBreakdown = const [],
    this.status = 'active',
  });

  factory FeeSchedule.fromJson(Map<String, dynamic> json) {
    return FeeSchedule(
      id: json['id'] as int,
      academicYear: json['academic_year'] as int,
      academicYearName: json['academic_year_name'] as String?,
      feeGroup: json['fee_group'] as int?,
      feeGroupName: json['fee_group_name'] as String?,
      feeType: json['fee_type'] as int,
      feeTypeName: json['fee_type_name'] as String?,
      amount: json['amount']?.toString() ?? '0',
      collectionFrequency: (json['collection_frequency'] as String?) ?? '',
      dueDate: (json['due_date'] as String?) ?? '',
      lateFeeApplicable: json['late_fee_applicable'] as bool? ?? false,
      gracePeriod: json['grace_period'] as int? ?? 0,
      lateFeeRule: (json['late_fee_rule'] as String?) ?? '',
      termBreakdown: ((json['term_breakdown'] as List<dynamic>?) ?? const [])
          .map((e) => TermBreakdownSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: (json['status'] as String?) ?? 'active',
    );
  }
}
