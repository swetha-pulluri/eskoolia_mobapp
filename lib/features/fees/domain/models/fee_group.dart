/// GET/POST/PATCH/DELETE /api/v1/fees/groups/ — apps/fees::FeesGroup +
/// FeesGroupSerializer. `applicableClasses` must be non-empty if provided
/// (`validate_applicable_classes` rejects an explicit empty list); `name` is
/// unique per `academicYear`.
class FeesGroup {
  final int id;
  final int academicYear;
  final String name;
  final String description;
  final List<int> applicableClasses;
  final bool isActive;

  const FeesGroup({
    required this.id,
    required this.academicYear,
    required this.name,
    this.description = '',
    this.applicableClasses = const [],
    this.isActive = true,
  });

  factory FeesGroup.fromJson(Map<String, dynamic> json) {
    return FeesGroup(
      id: json['id'] as int,
      academicYear: json['academic_year'] as int,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      applicableClasses: ((json['applicable_classes'] as List<dynamic>?) ?? const [])
          .map((e) => e as int)
          .toList(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
