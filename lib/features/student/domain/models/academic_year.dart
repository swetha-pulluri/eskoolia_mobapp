/// Academic Year model — Source: StudentAddPanel.tsx AcademicYear type +
/// components/academics/foundation/types.ts's richer shape (board,
/// number_of_terms, start_date, end_date, is_active) — one shared model
/// since both features read the exact same backend resource
/// (apps/core — AcademicYearSerializer). Backend: GET/POST/PATCH/DELETE
/// /api/v1/core/academic-years/.
class AcademicYear {
  final int id;
  final String name;
  final bool isCurrent;
  final String? board;
  final String? numberOfTerms;
  final String startDate;
  final String endDate;
  final bool isActive;

  const AcademicYear({
    required this.id,
    required this.name,
    this.isCurrent = false,
    this.board,
    this.numberOfTerms,
    this.startDate = '',
    this.endDate = '',
    this.isActive = true,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
      board: json['board'] as String?,
      numberOfTerms: json['number_of_terms'] as String?,
      startDate: (json['start_date'] as String?) ?? '',
      endDate: (json['end_date'] as String?) ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Student Category model — Source: StudentAddPanel.tsx StudentCategory type
/// (e.g. General, OBC, SC, ST, EWS — used by the admission-type/category
/// selects on the Academic Placement step).
/// Backend: GET /api/v1/students/categories/ (apps/students —
/// StudentCategorySerializer). Categories are free-text rows the school
/// creates, not a fixed enum — General/OBC/SC/ST/EWS are just typical values.
class StudentCategory {
  final int id;
  final String name;

  const StudentCategory({required this.id, required this.name});

  factory StudentCategory.fromJson(Map<String, dynamic> json) {
    return StudentCategory(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
    );
  }
}
