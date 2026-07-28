/// Minimal projection of the (80+ field) `Staff` serializer — only what the
/// Department Head/Deputy Head pickers, the "Staff Assigned" KPI, and the
/// per-department "Assigned staff" count on each `HrDepartmentCard` need.
class StaffLiteEntity {
  final int id;
  final String displayName;
  final String status;
  final int? departmentId;

  const StaffLiteEntity({
    required this.id,
    required this.displayName,
    this.status = 'active',
    this.departmentId,
  });

  factory StaffLiteEntity.fromJson(Map<String, dynamic> json) {
    final fullName = json['full_name'] as String?;
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    final staffNo = json['staff_no'] as String? ?? '';
    final composed = '$firstName $lastName'.trim();
    return StaffLiteEntity(
      id: json['id'] as int? ?? 0,
      displayName: (fullName != null && fullName.isNotEmpty) ? fullName : (composed.isNotEmpty ? composed : staffNo),
      status: json['status'] as String? ?? 'active',
      departmentId: json['department'] as int?,
    );
  }
}
