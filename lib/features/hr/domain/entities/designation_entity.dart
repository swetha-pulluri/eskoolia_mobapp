/// Mirrors the ACTUAL currently-running backend `Designation` model /
/// `DesignationSerializer` — only `department`, `name`, `is_active` exist.
/// No `short_code`/`role_template`/`employment_type`/`reports_to`/
/// `grade_level`/`sort_order` — those only exist on the unmerged `demo`
/// branch, which is explicitly NOT the API this app talks to.
class DesignationEntity {
  final int id;
  final int schoolId;
  final int departmentId;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DesignationEntity({
    this.id = 0,
    this.schoolId = 0,
    required this.departmentId,
    required this.name,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory DesignationEntity.fromJson(Map<String, dynamic> json) {
    return DesignationEntity(
      id: json['id'] as int? ?? 0,
      schoolId: json['school'] as int? ?? 0,
      departmentId: json['department'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  /// Sent on create/update — matches `DesignationSerializer`'s real fields.
  Map<String, dynamic> toJson() {
    return {
      'department': departmentId,
      'name': name,
      'is_active': isActive,
    };
  }
}
