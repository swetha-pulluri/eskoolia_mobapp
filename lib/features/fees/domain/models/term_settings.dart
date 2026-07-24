/// GET/POST(single-or-bulk)/PUT/PATCH/DELETE /api/v1/fees/term-settings/ —
/// apps/fees::TermSettings + TermSettingsSerializer.
///
/// IMPORTANT: a bulk (array-body) POST to this endpoint REPLACES every term
/// for that academic year — any existing `term_number` missing from the
/// posted array is deleted server-side. Callers must always send the full
/// desired term list for the year, never a partial diff.
class TermSettings {
  final int? id;
  final int academicYear;
  final String? academicYearName;
  final int termNumber;
  final String termName;
  final String startDate;
  final String endDate;
  final String defaultDueDate;

  const TermSettings({
    this.id,
    required this.academicYear,
    this.academicYearName,
    required this.termNumber,
    required this.termName,
    required this.startDate,
    required this.endDate,
    required this.defaultDueDate,
  });

  factory TermSettings.fromJson(Map<String, dynamic> json) {
    return TermSettings(
      id: json['id'] as int?,
      academicYear: json['academic_year'] as int,
      academicYearName: json['academic_year_name'] as String?,
      termNumber: json['term_number'] as int,
      termName: (json['term_name'] as String?) ?? '',
      startDate: (json['start_date'] as String?) ?? '',
      endDate: (json['end_date'] as String?) ?? '',
      defaultDueDate: (json['default_due_date'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'academic_year': academicYear,
      'term_number': termNumber,
      'term_name': termName,
      'start_date': startDate,
      'end_date': endDate,
      'default_due_date': defaultDueDate,
    };
  }
}
