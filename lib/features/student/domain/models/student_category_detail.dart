/// Full Student Category record for the Categories management screen —
/// Source: frontend components/students/StudentCategoryManagerPanel.tsx.
/// Backend: apps/students — StudentCategorySerializer (fields: id, name,
/// description, code, status, is_active, students_count, created_at).
/// Distinct from the lightweight `StudentCategory` (academic_year.dart)
/// used only for the Enroll form's dropdown, which doesn't need these
/// extra management fields.
class StudentCategoryDetail {
  final int id;
  final String name;
  final String description;
  final String code;
  final String status; // 'active' | 'inactive'
  final int studentsCount;
  final DateTime? createdAt;

  const StudentCategoryDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.status,
    required this.studentsCount,
    this.createdAt,
  });

  bool get isActive => status == 'active';

  factory StudentCategoryDetail.fromJson(Map<String, dynamic> json) {
    return StudentCategoryDetail(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'active',
      studentsCount: json['students_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// GET /categories/summary/ response.
class StudentCategorySummary {
  final int totalCount;
  final int activeCount;

  const StudentCategorySummary({required this.totalCount, required this.activeCount});

  factory StudentCategorySummary.fromJson(Map<String, dynamic> json) {
    return StudentCategorySummary(
      totalCount: json['total_count'] as int? ?? 0,
      activeCount: json['active_count'] as int? ?? 0,
    );
  }
}
