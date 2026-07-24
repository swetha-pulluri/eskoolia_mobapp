// ClassSubjectEntry — Source: components/academics/foundation/panes/SubjectsPane.tsx.
// Backend: apps/academics — ClassSubjectEntry model/ClassSubjectEntryViewSet,
// GET/POST/PATCH/DELETE /api/v1/academics/class-subject-entries/, plus
// custom actions POST .../reset-class/ (create() itself is also custom,
// fanning a single subject out to several class_ids at once).
class ClassSubjectEntry {
  final int id;
  final int schoolClassId;
  final String name;
  final String code;
  final String subjectType; // core | co_curricular | optional
  final int periodsPerWeek;
  final bool activeStatus;

  const ClassSubjectEntry({
    required this.id,
    required this.schoolClassId,
    required this.name,
    required this.code,
    required this.subjectType,
    this.periodsPerWeek = 5,
    this.activeStatus = true,
  });

  factory ClassSubjectEntry.fromJson(Map<String, dynamic> json) {
    return ClassSubjectEntry(
      id: json['id'] as int,
      schoolClassId: json['school_class'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      subjectType: (json['subject_type'] as String?) ?? 'core',
      periodsPerWeek: json['periods_per_week'] as int? ?? 5,
      activeStatus: json['active_status'] as bool? ?? true,
    );
  }
}

/// Mirrors SubjectsPane.tsx's `TYPE_CHIP` labels.
const List<(String value, String label)> subjectTypeOptions = [
  ('core', 'Core'),
  ('co_curricular', 'Co-curricular'),
  ('optional', 'Optional'),
];

/// Mirrors SubjectsPane.tsx's `DEF_SUBJECTS` (verbatim, 9-item "Load Defaults" seed).
const List<(String name, String code, String type, int periods)> foundationDefaultSubjects = [
  ('Mathematics', 'MATH', 'core', 5),
  ('English', 'ENG', 'core', 5),
  ('Science', 'SCI', 'core', 4),
  ('Social Studies', 'SS', 'core', 4),
  ('Hindi', 'HIN', 'core', 4),
  ('Physical Education', 'PE', 'co_curricular', 2),
  ('Art and Craft', 'ART', 'co_curricular', 2),
  ('Music', 'MUS', 'co_curricular', 1),
  ('Computer Science', 'CS', 'optional', 2),
];
