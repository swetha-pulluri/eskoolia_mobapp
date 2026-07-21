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

  const StudentCategoryEntity({
    this.id,
    required this.name,
    this.code,
    this.description,
    this.status = 'active',
    this.studentsCount,
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
    );
  }
}
