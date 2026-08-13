/// Mirrors `build_my_classes()`'s response (`GET /api/v1/teacher/my-classes/`)
/// field-for-field — one entry per class+section the teacher is assigned to,
/// either as class teacher or subject teacher.
class MyClassEntity {
  final int classId;
  final String className;
  final int sectionId;
  final String sectionName;
  final bool isClassTeacher;
  final List<String> subjects;
  final int studentCount;

  const MyClassEntity({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.isClassTeacher,
    this.subjects = const [],
    required this.studentCount,
  });

  factory MyClassEntity.fromJson(Map<String, dynamic> json) => MyClassEntity(
        classId: json['class_id'] as int,
        className: (json['class_name'] as String?) ?? '',
        sectionId: json['section_id'] as int,
        sectionName: (json['section_name'] as String?) ?? '',
        isClassTeacher: json['is_class_teacher'] as bool? ?? false,
        subjects: ((json['subjects'] as List?) ?? const []).map((e) => e.toString()).toList(),
        studentCount: json['student_count'] as int? ?? 0,
      );
}
