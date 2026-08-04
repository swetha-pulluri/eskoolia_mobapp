/// Mirrors the backend `Designation` model / `DesignationSerializer`
/// (`apps/hr/models.py`, `apps/hr/serializers.py`) — `department`, `name`,
/// `short_code`, `is_active` are all real, writable fields there.
/// `role_template`/`employment_type`/`reports_to`/`grade_level`/
/// `sort_order` also exist on the backend but aren't collected by the
/// mobile form (matching the web reference's actual routed form,
/// `InlineDesigForm` in `app/(dashboard)/hr/setup/page.tsx`, which only
/// edits department/name/short_code/is_active).
class DesignationEntity {
  final int id;
  final int schoolId;
  final int departmentId;
  final String name;
  final String shortCode;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DesignationEntity({
    this.id = 0,
    this.schoolId = 0,
    required this.departmentId,
    required this.name,
    this.shortCode = '',
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
      shortCode: json['short_code'] as String? ?? '',
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
      'short_code': shortCode,
      'is_active': isActive,
    };
  }
}
