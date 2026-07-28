import 'due_student.dart';

/// GET /api/v1/fees/dues/by-class/ item — one class's overdue-students group.
/// Reference: frontend lib/fees-api.ts::DuesClassGroup.
class DuesClassGroup {
  final String cls;
  final int totalStudents;
  final int assignedStudents;
  final List<DueStudent> students;

  const DuesClassGroup({
    required this.cls,
    required this.totalStudents,
    required this.assignedStudents,
    required this.students,
  });

  factory DuesClassGroup.fromJson(Map<String, dynamic> json) {
    final rows = json['students'];
    return DuesClassGroup(
      cls: (json['cls'] as String?) ?? '',
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      assignedStudents: (json['assigned_students'] as num?)?.toInt() ?? 0,
      students: rows is List ? rows.map((e) => DueStudent.fromJson(e as Map<String, dynamic>)).toList() : const [],
    );
  }
}
