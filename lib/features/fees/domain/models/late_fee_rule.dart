/// GET/POST/PATCH/DELETE /api/v1/fees/late-fee-rules/ —
/// apps/fees::LateFeeRule + LateFeeRuleSerializer. `penaltyRule` is a plain
/// free-text description (e.g. "Rs. 50 daily") — not JSON, not a fixed
/// enum; the backend only scrapes the first number out of it via regex for
/// its own dues-reminder preview math. `capAmount` null means uncapped.
class LateFeeRule {
  final int id;
  final int? academicYear;
  final String name;
  final int gracePeriodDays;
  final String penaltyRule;
  final String? capAmount;
  final String status;

  const LateFeeRule({
    required this.id,
    this.academicYear,
    required this.name,
    this.gracePeriodDays = 0,
    this.penaltyRule = '',
    this.capAmount,
    this.status = 'Active',
  });

  factory LateFeeRule.fromJson(Map<String, dynamic> json) {
    return LateFeeRule(
      id: json['id'] as int,
      academicYear: json['academic_year'] as int?,
      name: (json['name'] as String?) ?? '',
      gracePeriodDays: json['grace_period_days'] as int? ?? 0,
      penaltyRule: (json['penalty_rule'] as String?) ?? '',
      capAmount: json['cap_amount']?.toString(),
      status: (json['status'] as String?) ?? 'Active',
    );
  }
}
