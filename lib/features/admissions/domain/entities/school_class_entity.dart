/// Section — mirrors backend `core.Section` / `SectionSerializer`
/// (`fields = ["id", "school_class", "name", "capacity", "student_count", "created_at"]`).
class SectionEntity {
  final int id;
  final int schoolClass;
  final String name;
  final int capacity;

  const SectionEntity({
    required this.id,
    required this.schoolClass,
    required this.name,
    this.capacity = 40,
  });

  factory SectionEntity.fromJson(Map<String, dynamic> json) {
    return SectionEntity(
      id: json['id'] as int,
      schoolClass: json['school_class'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 40,
    );
  }
}

/// School class — mirrors backend `core.Class` / `ClassSerializer`
/// (`GET /api/v1/core/classes/`), which nests `sections` directly.
class SchoolClassEntity {
  final int id;
  /// Owning school id (`ClassSerializer`'s read-only `school` field). Used
  /// to client-side re-scope results for accounts where
  /// `ClassViewSet.get_queryset()` skips school filtering (`is_superuser`
  /// bypass merges every school's classes together — confirmed directly:
  /// a superuser test account sees "Nursery"/"Grade 1"/etc. repeated once
  /// per school).
  final int? schoolId;
  final String name;
  final List<SectionEntity> sections;

  const SchoolClassEntity({
    required this.id,
    this.schoolId,
    required this.name,
    this.sections = const [],
  });

  factory SchoolClassEntity.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List? ?? const [];
    return SchoolClassEntity(
      id: json['id'] as int,
      schoolId: json['school'] as int?,
      name: json['name'] as String? ?? '',
      sections: sectionsJson.map((e) => SectionEntity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Per-class pipeline summary — mirrors frontend `ClassConfig`, computed
/// client-side from inquiries + classes (not a separate API model).
class ClassConfigEntity {
  final int id;
  final String name;
  final int capacity;
  final List<SectionEntity> sections;
  final int pipelineCount;
  final int enrolledCount;
  final int overdueCount;
  /// "urgent" | "active" | "healthy" | "quiet"
  final String healthStatus;

  const ClassConfigEntity({
    required this.id,
    required this.name,
    required this.capacity,
    required this.sections,
    required this.pipelineCount,
    required this.enrolledCount,
    required this.overdueCount,
    required this.healthStatus,
  });
}
