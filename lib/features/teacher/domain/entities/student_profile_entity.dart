/// Mirrors `build_student_profile()`'s response
/// (`GET /api/v1/teacher/students/<id>/`) field-for-field.
class StudentProfileEntity {
  /// Which tabs the server says should render — order here is NOT the
  /// display order; the UI iterates its own fixed tab order and checks
  /// membership in this list (matches web's `ALL_TABS`/`sections_available`
  /// pattern exactly).
  final List<String> sectionsAvailable;
  final StudentOverviewEntity overview;
  final List<ExamMarkEntity>? academicMarks;
  final List<AttendanceRecordEntity>? attendanceRecords;
  final AttendanceSummaryEntity? attendanceSummary;
  final List<BehaviourRecordEntity>? behaviourRecords;
  final int? behaviourTotalPoints;

  const StudentProfileEntity({
    required this.sectionsAvailable,
    required this.overview,
    this.academicMarks,
    this.attendanceRecords,
    this.attendanceSummary,
    this.behaviourRecords,
    this.behaviourTotalPoints,
  });

  factory StudentProfileEntity.fromJson(Map<String, dynamic> json) {
    final academic = json['academic'] as Map<String, dynamic>?;
    final attendance = json['attendance'] as Map<String, dynamic>?;
    final behaviour = json['behaviour'] as Map<String, dynamic>?;
    return StudentProfileEntity(
      sectionsAvailable: ((json['sections_available'] as List?) ?? const []).map((e) => e.toString()).toList(),
      overview: StudentOverviewEntity.fromJson(json['overview'] as Map<String, dynamic>),
      academicMarks: (academic?['marks'] as List?)
          ?.map((e) => ExamMarkEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      attendanceRecords: (attendance?['records'] as List?)
          ?.map((e) => AttendanceRecordEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      attendanceSummary:
          attendance?['summary'] != null ? AttendanceSummaryEntity.fromJson(attendance!['summary'] as Map<String, dynamic>) : null,
      behaviourRecords: (behaviour?['records'] as List?)
          ?.map((e) => BehaviourRecordEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      behaviourTotalPoints: behaviour?['total_points'] as int?,
    );
  }
}

class StudentOverviewEntity {
  final int id;
  final String studentId;
  final String name;
  final String rollNo;
  final String admissionNo;
  final String gender;
  final String? photoUrl;
  final String? dateOfBirth;
  final String bloodGroup;
  final String phone;
  final String email;
  final String className;
  final String sectionName;
  final int? classId;
  final int? sectionId;
  // '' fallback here (never null) — confirmed in `build_student_profile()`.
  // The sibling `/credentials/` endpoint uses a DIFFERENT (nullable)
  // convention for the same underlying field — see StudentCredentialsEntity.
  final String guardianName;
  final String guardianPhone;
  final String guardianRelation;

  const StudentOverviewEntity({
    required this.id,
    required this.studentId,
    required this.name,
    required this.rollNo,
    required this.admissionNo,
    required this.gender,
    this.photoUrl,
    this.dateOfBirth,
    required this.bloodGroup,
    required this.phone,
    required this.email,
    required this.className,
    required this.sectionName,
    this.classId,
    this.sectionId,
    required this.guardianName,
    required this.guardianPhone,
    required this.guardianRelation,
  });

  factory StudentOverviewEntity.fromJson(Map<String, dynamic> json) => StudentOverviewEntity(
        id: json['id'] as int,
        studentId: (json['student_id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        rollNo: (json['roll_no'] as String?) ?? '',
        admissionNo: (json['admission_no'] as String?) ?? '',
        gender: (json['gender'] as String?) ?? '',
        photoUrl: json['photo_url'] as String?,
        dateOfBirth: json['date_of_birth'] as String?,
        bloodGroup: (json['blood_group'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        className: (json['class_name'] as String?) ?? '',
        sectionName: (json['section_name'] as String?) ?? '',
        classId: json['class_id'] as int?,
        sectionId: json['section_id'] as int?,
        guardianName: (json['guardian_name'] as String?) ?? '',
        guardianPhone: (json['guardian_phone'] as String?) ?? '',
        guardianRelation: (json['guardian_relation'] as String?) ?? '',
      );
}

class ExamMarkEntity {
  final String examName;
  final String term;
  final String subject;
  final double obtained;
  final double fullMarks;
  final double passMarks;
  final bool absent;
  final String? examDate;

  const ExamMarkEntity({
    required this.examName,
    required this.term,
    required this.subject,
    required this.obtained,
    required this.fullMarks,
    required this.passMarks,
    required this.absent,
    this.examDate,
  });

  factory ExamMarkEntity.fromJson(Map<String, dynamic> json) => ExamMarkEntity(
        examName: (json['exam_name'] as String?) ?? '',
        term: (json['term'] as String?) ?? '',
        subject: (json['subject'] as String?) ?? '',
        obtained: (json['obtained'] as num?)?.toDouble() ?? 0,
        fullMarks: (json['full_marks'] as num?)?.toDouble() ?? 100,
        passMarks: (json['pass_marks'] as num?)?.toDouble() ?? 33,
        absent: json['absent'] as bool? ?? false,
        examDate: json['exam_date'] as String?,
      );
}

class AttendanceRecordEntity {
  final String date;
  final String status;
  final String label;
  final String notes;

  const AttendanceRecordEntity({required this.date, required this.status, required this.label, this.notes = ''});

  factory AttendanceRecordEntity.fromJson(Map<String, dynamic> json) => AttendanceRecordEntity(
        date: (json['date'] as String?) ?? '',
        status: (json['status'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
      );
}

class AttendanceSummaryEntity {
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int holiday;
  final double? attendancePct;

  const AttendanceSummaryEntity({
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.holiday,
    this.attendancePct,
  });

  factory AttendanceSummaryEntity.fromJson(Map<String, dynamic> json) => AttendanceSummaryEntity(
        present: json['present'] as int? ?? 0,
        absent: json['absent'] as int? ?? 0,
        late: json['late'] as int? ?? 0,
        halfDay: json['half_day'] as int? ?? 0,
        holiday: json['holiday'] as int? ?? 0,
        attendancePct: (json['attendance_pct'] as num?)?.toDouble(),
      );
}

class BehaviourRecordEntity {
  final String title;
  final int point;
  final String description;
  final String assignedBy;
  final String date;

  const BehaviourRecordEntity({
    required this.title,
    required this.point,
    this.description = '',
    this.assignedBy = '',
    required this.date,
  });

  factory BehaviourRecordEntity.fromJson(Map<String, dynamic> json) => BehaviourRecordEntity(
        title: (json['title'] as String?) ?? '',
        point: json['point'] as int? ?? 0,
        description: (json['description'] as String?) ?? '',
        assignedBy: (json['assigned_by'] as String?) ?? '',
        date: (json['date'] as String?) ?? '',
      );
}
