/// A student row as returned by GET /api/v1/students/students/ for the Fee
/// Assignment screen — apps/students::StudentListSerializer. Distinct from
/// fees_student_ref.dart's narrower `FeesStudentRef` (Fees Home only needs
/// first/last name); this screen also needs the student's current class to
/// group the roster, matching FeesAssignmentPanel.tsx's `CLASS_DATA` build.
class AssignmentStudent {
  final int id;
  final String firstName;
  final String lastName;
  final String admissionNo;
  final int? currentClassId;
  final String? currentClassName;

  const AssignmentStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.admissionNo,
    this.currentClassId,
    this.currentClassName,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AssignmentStudent.fromJson(Map<String, dynamic> json) {
    return AssignmentStudent(
      id: json['id'] as int,
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      admissionNo: (json['admission_no'] as String?) ?? '',
      currentClassId: json['current_class'] as int?,
      currentClassName: json['current_class_name'] as String?,
    );
  }
}
