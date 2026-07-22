/// Section — mirrors backend `core.Section` / frontend `ApiSection`.
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
}

/// School class — mirrors backend `core.Class` / frontend `ApiSchoolClass`.
class SchoolClassEntity {
  final int id;
  final String name;
  final List<SectionEntity> sections;

  const SchoolClassEntity({
    required this.id,
    required this.name,
    this.sections = const [],
  });
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
