/// Student Category — mirrors backend `StudentCategory` /
/// `/api/v1/students/categories/`. Surfaced under System Config on the
/// web (reusing the Students module's own `StudentCategoryManagerPanel`).
class StudentCategoryEntity {
  final int? id;
  final String name;
  final String? code;
  final String? description;
  final String status; // 'active' | 'inactive'
  final int? studentsCount;
  final String? createdAt;
  final String? updatedBy;

  const StudentCategoryEntity({
    this.id,
    required this.name,
    this.code,
    this.description,
    this.status = 'active',
    this.studentsCount,
    this.createdAt,
    this.updatedBy,
  });

  bool get isActive => status == 'active';

  factory StudentCategoryEntity.fromJson(Map<String, dynamic> json) {
    return StudentCategoryEntity(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      studentsCount: json['students_count'] as int?,
      createdAt: json['created_at'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (code != null && code!.isNotEmpty) 'code': code,
        if (description != null) 'description': description,
        'status': status,
      };

  StudentCategoryEntity copyWith({String? status}) {
    return StudentCategoryEntity(
      id: id,
      name: name,
      code: code,
      description: description,
      status: status ?? this.status,
      studentsCount: studentsCount,
      createdAt: createdAt,
      updatedBy: updatedBy,
    );
  }
}

/// Mirrors the web's `/api/v1/students/categories/summary/` response shape,
/// backing the 3 summary cards (Total Categories / Students by Category /
/// Recent Activity) on `StudentCategoryManagerPanel.tsx`.
class StudentCategorySummary {
  final int totalCount;
  final int activeCount;
  final int inactiveCount;
  final int attentionCount;
  final int topTotalStudents;
  final List<({int id, String name, int studentsCount})> topCategories;
  final List<({int id, String name, String action, DateTime at})> recentActivity;

  const StudentCategorySummary({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.attentionCount,
    required this.topTotalStudents,
    required this.topCategories,
    this.recentActivity = const [],
  });
}
