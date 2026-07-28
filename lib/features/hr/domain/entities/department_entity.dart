/// Mirrors the real, migrated `Department` model / `DepartmentSerializer`
/// that actually powers the live web app — verified read-only against
/// `apps/hr/models.py` (migrations `0014_department_dept_type`,
/// `0015_department_type_model`, `0016_department_head_deputy_head`,
/// `0025_department_short_code`, `0026_add_email_to_department`,
/// `0027_add_dept_status_working_days`) and `apps/hr/serializers.py` on the
/// `demo`/`mobile`/`BugFix` branches (identical for this model; `main` is
/// stale here). `is_active` is a real column but the serializer keeps it in
/// sync with `status` server-side (`active` -> true, `inactive`/`archived`
/// -> false) — the app never needs to send it directly.
class DepartmentEntity {
  static const statusActive = 'active';
  static const statusInactive = 'inactive';
  static const statusArchived = 'archived';

  static const workingDaysMonFri = 'Monday - Friday';
  static const workingDaysMonSat = 'Monday - Saturday';
  static const workingDaysAll7 = 'All 7 days';

  final int id;
  final int schoolId;
  final String name;
  final String shortCode;
  final String deptType;
  final String status;
  final String workingDays;
  final int? headId;
  final int? deputyHeadId;
  final String? headName;
  final String? deputyHeadName;
  final String description;
  final String email;
  final bool isActive;
  final int staffCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DepartmentEntity({
    this.id = 0,
    this.schoolId = 0,
    required this.name,
    this.shortCode = '',
    this.deptType = '',
    this.status = statusActive,
    this.workingDays = workingDaysMonFri,
    this.headId,
    this.deputyHeadId,
    this.headName,
    this.deputyHeadName,
    this.description = '',
    this.email = '',
    this.isActive = true,
    this.staffCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory DepartmentEntity.fromJson(Map<String, dynamic> json) {
    return DepartmentEntity(
      id: json['id'] as int? ?? 0,
      schoolId: json['school'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      shortCode: json['short_code'] as String? ?? '',
      deptType: json['dept_type'] as String? ?? '',
      status: json['status'] as String? ?? statusActive,
      workingDays: json['working_days'] as String? ?? workingDaysMonFri,
      headId: json['head_id'] as int?,
      deputyHeadId: json['deputy_head_id'] as int?,
      headName: json['head_name'] as String?,
      deputyHeadName: json['deputy_head_name'] as String?,
      description: json['description'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      staffCount: json['staff_count'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  /// Sent on create/update — matches `DepartmentSerializer`'s writable
  /// fields exactly. `is_active` is deliberately omitted: the backend
  /// derives it from `status` regardless of what's sent.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'short_code': shortCode,
      'dept_type': deptType,
      'status': status,
      'working_days': workingDays,
      'description': description,
      'email': email,
      'head_id': headId,
      'deputy_head_id': deputyHeadId,
    };
  }
}
