/// Lite Role projection — matches `/api/v1/hr/staff/form-options/`'s
/// `roles: [{id, name}]` and `/api/v1/access-control/roles/`'s list.
class RoleEntity {
  final int id;
  final String name;

  const RoleEntity({required this.id, required this.name});

  factory RoleEntity.fromJson(Map<String, dynamic> json) {
    return RoleEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}
