/// Role — from `/api/v1/access-control/roles/`, used as the role picker
/// in ID Card / Certificate template forms and Generate & Print screens.
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
