/// Role — from `/api/v1/access-control/roles/`, used as the role picker
/// in ID Card / Certificate template forms and Generate & Print screens.
///
/// `schoolId` (real `school_id` column on the `roles` table, confirmed
/// directly against live data) is used to re-scope this list client-side —
/// `RoleViewSet`/`generate-setup` skip school filtering for superusers, so
/// an unscoped fetch genuinely returns every school's roles merged.
class RoleEntity {
  final int id;
  final String name;
  final int? schoolId;

  const RoleEntity({required this.id, required this.name, this.schoolId});

  factory RoleEntity.fromJson(Map<String, dynamic> json) {
    return RoleEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      schoolId: json['school_id'] as int? ?? json['school'] as int?,
    );
  }
}
