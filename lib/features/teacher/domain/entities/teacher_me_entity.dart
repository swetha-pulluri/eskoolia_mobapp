/// Mirrors `TeacherMeView`'s real response (`GET /api/v1/teacher/me/`)
/// field-for-field. `pendingItems` deliberately keeps web's own (disclosed,
/// not-a-real-count) semantics: `attendancePending` is a plain boolean
/// (`bool(class_teacher_for)` server-side) and `homeworkToReview` is always
/// `0` — this entity does not upgrade either into a fabricated real count.
class TeacherMeEntity {
  // `staff.staff_no` is a `CharField` (e.g. "20260001"), not a numeric PK —
  // matches web's `TeacherMe.staff_id: string` in `lib/api/teacher.ts`.
  final String staffId;
  final String name;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? designation;
  final int? designationId;
  final String? department;
  final int? departmentId;
  final String? photoUrl;
  final TeacherClassRefEntity? classTeacherFor;
  final List<TeacherSubjectAssignmentEntity> subjectAssignments;
  final List<TeacherPeriodEntity> todaysPeriods;
  final TeacherPendingItemsEntity pendingItems;

  const TeacherMeEntity({
    required this.staffId,
    required this.name,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.designation,
    this.designationId,
    this.department,
    this.departmentId,
    this.photoUrl,
    this.classTeacherFor,
    this.subjectAssignments = const [],
    this.todaysPeriods = const [],
    this.pendingItems = const TeacherPendingItemsEntity(homeworkToReview: 0, attendancePending: false),
  });

  factory TeacherMeEntity.fromJson(Map<String, dynamic> json) {
    return TeacherMeEntity(
      staffId: json['staff_id']?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      designation: json['designation'] as String?,
      designationId: json['designation_id'] as int?,
      department: json['department'] as String?,
      departmentId: json['department_id'] as int?,
      photoUrl: json['photo_url'] as String?,
      classTeacherFor: json['class_teacher_for'] != null
          ? TeacherClassRefEntity.fromJson(json['class_teacher_for'] as Map<String, dynamic>)
          : null,
      subjectAssignments: ((json['subject_assignments'] as List?) ?? const [])
          .map((e) => TeacherSubjectAssignmentEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      todaysPeriods: ((json['todays_periods'] as List?) ?? const [])
          .map((e) => TeacherPeriodEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingItems: json['pending_items'] != null
          ? TeacherPendingItemsEntity.fromJson(json['pending_items'] as Map<String, dynamic>)
          : const TeacherPendingItemsEntity(homeworkToReview: 0, attendancePending: false),
    );
  }
}

class TeacherClassRefEntity {
  final int classId;
  final String className;
  final int sectionId;
  final String sectionName;
  final int studentCount;

  const TeacherClassRefEntity({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.studentCount,
  });

  factory TeacherClassRefEntity.fromJson(Map<String, dynamic> json) => TeacherClassRefEntity(
        classId: json['class_id'] as int,
        className: (json['class_name'] as String?) ?? '',
        sectionId: json['section_id'] as int,
        sectionName: (json['section_name'] as String?) ?? '',
        studentCount: json['student_count'] as int? ?? 0,
      );
}

class TeacherSubjectAssignmentEntity {
  final int subjectId;
  final String subjectName;
  final int totalSections;
  final int totalStudents;
  final List<TeacherClassRefEntity> sections;

  const TeacherSubjectAssignmentEntity({
    required this.subjectId,
    required this.subjectName,
    required this.totalSections,
    required this.totalStudents,
    this.sections = const [],
  });

  factory TeacherSubjectAssignmentEntity.fromJson(Map<String, dynamic> json) => TeacherSubjectAssignmentEntity(
        subjectId: json['subject_id'] as int,
        subjectName: (json['subject_name'] as String?) ?? '',
        totalSections: json['total_sections'] as int? ?? 0,
        totalStudents: json['total_students'] as int? ?? 0,
        sections: ((json['sections'] as List?) ?? const [])
            .map((e) => TeacherClassRefEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TeacherPeriodEntity {
  final String period;
  final String subject;
  final String className;
  final String sectionName;
  final String? room;
  final String from;
  final String to;
  final bool isNow;
  final bool isDone;

  const TeacherPeriodEntity({
    required this.period,
    required this.subject,
    required this.className,
    required this.sectionName,
    this.room,
    required this.from,
    required this.to,
    this.isNow = false,
    this.isDone = false,
  });

  factory TeacherPeriodEntity.fromJson(Map<String, dynamic> json) => TeacherPeriodEntity(
        period: (json['period'] as String?) ?? '',
        subject: (json['subject'] as String?) ?? '',
        className: (json['class_name'] as String?) ?? '',
        sectionName: (json['section_name'] as String?) ?? '',
        room: json['room'] as String?,
        from: (json['from'] as String?) ?? '',
        to: (json['to'] as String?) ?? '',
        isNow: json['is_now'] as bool? ?? false,
        isDone: json['is_done'] as bool? ?? false,
      );
}

/// `homeworkToReview` is hardcoded to `0` server-side and `attendancePending`
/// is `bool(class_teacher_for)`, not a real count — see class doc comment.
class TeacherPendingItemsEntity {
  final int homeworkToReview;
  final bool attendancePending;

  const TeacherPendingItemsEntity({required this.homeworkToReview, required this.attendancePending});

  factory TeacherPendingItemsEntity.fromJson(Map<String, dynamic> json) => TeacherPendingItemsEntity(
        homeworkToReview: json['homework_to_review'] as int? ?? 0,
        attendancePending: json['attendance_pending'] as bool? ?? false,
      );
}
