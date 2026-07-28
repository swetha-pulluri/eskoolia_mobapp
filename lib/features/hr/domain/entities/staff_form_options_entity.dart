import 'department_entity.dart';
import 'designation_entity.dart';
import 'role_entity.dart';

/// Matches `GET /api/v1/hr/staff/form-options/`'s
/// `{success, message, data: {roles, departments, designations}}`.
class StaffFormOptionsEntity {
  final List<RoleEntity> roles;
  final List<DepartmentEntity> departments;
  final List<DesignationEntity> designations;

  const StaffFormOptionsEntity({
    this.roles = const [],
    this.departments = const [],
    this.designations = const [],
  });

  factory StaffFormOptionsEntity.fromJson(Map<String, dynamic> json) {
    return StaffFormOptionsEntity(
      roles: (json['roles'] as List? ?? const [])
          .map((e) => RoleEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      departments: (json['departments'] as List? ?? const [])
          .map((e) => DepartmentEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      designations: (json['designations'] as List? ?? const [])
          .map((e) => DesignationEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
