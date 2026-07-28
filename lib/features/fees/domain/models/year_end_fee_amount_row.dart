/// One row of GET /api/v1/fees/year-end/group-amounts/'s `fee_types` array
/// — the "Edit Fee Amounts" modal's per-fee-type staged next-year amount.
/// Reference: frontend lib/fees-api.ts::YearEndFeeAmountRow.
class YearEndFeeAmountRow {
  final int id;
  final String name;
  final String breakdown;
  final String currentTotal;
  final String scheduleType; // term_wise | monthly | quarterly | half_yearly | yearly | one_time
  final String newAmount;
  final bool isDeleted;

  const YearEndFeeAmountRow({
    required this.id,
    required this.name,
    required this.breakdown,
    required this.currentTotal,
    required this.scheduleType,
    required this.newAmount,
    this.isDeleted = false,
  });

  factory YearEndFeeAmountRow.fromJson(Map<String, dynamic> json) {
    return YearEndFeeAmountRow(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      breakdown: (json['breakdown'] as String?) ?? '',
      currentTotal: json['current_total']?.toString() ?? '0',
      scheduleType: (json['schedule_type'] as String?) ?? '',
      newAmount: json['new_amount']?.toString() ?? '0',
      isDeleted: (json['is_deleted'] as bool?) ?? false,
    );
  }

  YearEndFeeAmountRow copyWith({String? newAmount}) {
    return YearEndFeeAmountRow(
      id: id,
      name: name,
      breakdown: breakdown,
      currentTotal: currentTotal,
      scheduleType: scheduleType,
      newAmount: newAmount ?? this.newAmount,
      isDeleted: isDeleted,
    );
  }
}
