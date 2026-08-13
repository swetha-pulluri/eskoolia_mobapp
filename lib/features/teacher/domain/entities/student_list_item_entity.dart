/// Mirrors one entry of `build_students_list()`'s response
/// (`GET /api/v1/teacher/students/?class_id=&section_id=`). `avgScore` is
/// always `null` server-side today (no results integration yet — disclosed,
/// not upgraded into a fabricated value).
class StudentListItemEntity {
  final int id;
  final String studentId;
  final String name;
  final String rollNo;
  final String admissionNo;
  final String gender;
  final String? photoUrl;
  final double? attendancePct;
  final double? avgScore;

  const StudentListItemEntity({
    required this.id,
    required this.studentId,
    required this.name,
    required this.rollNo,
    required this.admissionNo,
    required this.gender,
    this.photoUrl,
    this.attendancePct,
    this.avgScore,
  });

  factory StudentListItemEntity.fromJson(Map<String, dynamic> json) => StudentListItemEntity(
        id: json['id'] as int,
        studentId: (json['student_id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        rollNo: (json['roll_no'] as String?) ?? '',
        admissionNo: (json['admission_no'] as String?) ?? '',
        gender: (json['gender'] as String?) ?? '',
        photoUrl: json['photo_url'] as String?,
        attendancePct: (json['attendance_pct'] as num?)?.toDouble(),
        avgScore: (json['avg_score'] as num?)?.toDouble(),
      );
}
