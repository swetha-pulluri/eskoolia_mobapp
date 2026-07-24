/// GET/POST/PATCH/DELETE /api/v1/fees/concession-rules/ —
/// apps/fees::ConcessionRule + ConcessionRuleSerializer. `appliesTo` is a
/// plain free-text label (e.g. "Tuition Fee"), not a reference to a real
/// FeesType. `name` is unique per academic year (case-insensitive).
class ConcessionRule {
  final int id;
  final int? academicYear;
  final String name;
  final String appliesTo;
  final String discountPercentage;
  final String status;

  const ConcessionRule({
    required this.id,
    this.academicYear,
    required this.name,
    this.appliesTo = '',
    this.discountPercentage = '0',
    this.status = 'Active',
  });

  factory ConcessionRule.fromJson(Map<String, dynamic> json) {
    return ConcessionRule(
      id: json['id'] as int,
      academicYear: json['academic_year'] as int?,
      name: (json['name'] as String?) ?? '',
      appliesTo: (json['applies_to'] as String?) ?? '',
      discountPercentage: json['discount_percentage']?.toString() ?? '0',
      status: (json['status'] as String?) ?? 'Active',
    );
  }
}
