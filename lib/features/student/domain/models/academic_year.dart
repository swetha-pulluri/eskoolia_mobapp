/// Academic Year model — Source: StudentAddPanel.tsx AcademicYear type.
/// Backend: GET /api/v1/core/academic-years/ (apps/core — AcademicYearSerializer).
class AcademicYear {
  final int id;
  final String name;
  final bool isCurrent;

  const AcademicYear({
    required this.id,
    required this.name,
    this.isCurrent = false,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
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
