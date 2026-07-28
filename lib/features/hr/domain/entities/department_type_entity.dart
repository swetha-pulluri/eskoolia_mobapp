/// Mirrors `GET /api/v1/hr/department-types/` on the real `DepartmentTypeViewSet`
/// (verified read-only on `demo`/`mobile`/`BugFix`'s `apps/hr/views.py`):
/// returns the 5 fixed predefined types (`id: null`) plus the school's own
/// custom types (`id: <int>`) created via `POST .../department-types/`.
class DepartmentTypeEntity {
  final int? id;
  final String name;
  final bool isPredefined;

  const DepartmentTypeEntity({
    this.id,
    required this.name,
    this.isPredefined = false,
  });

  factory DepartmentTypeEntity.fromJson(Map<String, dynamic> json) {
    return DepartmentTypeEntity(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      isPredefined: json['is_predefined'] as bool? ?? false,
    );
  }
}
