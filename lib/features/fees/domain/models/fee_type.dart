/// GET/POST/PATCH/DELETE /api/v1/fees/types/ — apps/fees::FeesType +
/// FeesTypeSerializer. The API always returns display-cased strings —
/// `taxable`: "Yes"/"No", `default_structure`: "Monthly"/"Quarterly"/
/// "Term-wise"/"Yearly"/"Custom", `status`: "Active"/"Inactive" — and
/// accepts the same casing back on write (server lowercases/normalizes
/// internally), so these are plain strings here, not enums.
class FeesType {
  final int id;
  final int? academicYear;
  final int? feesGroup;
  final String name;
  final String glCode;
  final String taxable;
  final String defaultStructure;
  final String status;

  const FeesType({
    required this.id,
    this.academicYear,
    this.feesGroup,
    required this.name,
    required this.glCode,
    this.taxable = 'No',
    this.defaultStructure = 'Term-wise',
    this.status = 'Active',
  });

  factory FeesType.fromJson(Map<String, dynamic> json) {
    return FeesType(
      id: json['id'] as int,
      academicYear: json['academic_year'] as int?,
      feesGroup: json['fees_group'] as int?,
      name: (json['name'] as String?) ?? '',
      glCode: (json['gl_code'] as String?) ?? '',
      taxable: (json['taxable'] as String?) ?? 'No',
      defaultStructure: (json['default_structure'] as String?) ?? 'Term-wise',
      status: (json['status'] as String?) ?? 'Active',
    );
  }
}
