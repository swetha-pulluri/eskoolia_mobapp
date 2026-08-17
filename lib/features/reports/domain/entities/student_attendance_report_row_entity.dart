/// One row of `GET /api/v1/reports/students/attendance/` — mirrors the
/// real backend's `StudentAttendanceRowSerializer` field names exactly
/// (`backend/apps/reports/serializers.py`): `student_name`/`class_name`/
/// `section_name` (not `full_name`/`class`/`section`), and `attendance_type`
/// as a single-letter code (no separate `status` field).
class StudentAttendanceReportRowEntity {
  final int attendanceId;
  final String attendanceDate;
  final String attendanceType; // P | A | L | F | H
  final String admissionNo;
  final String studentName;
  final String className;
  final String sectionName;
  final String notes;

  const StudentAttendanceReportRowEntity({
    required this.attendanceId,
    required this.attendanceDate,
    required this.attendanceType,
    required this.admissionNo,
    required this.studentName,
    required this.className,
    required this.sectionName,
    required this.notes,
  });

  factory StudentAttendanceReportRowEntity.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceReportRowEntity(
      attendanceId: json['attendance_id'] as int? ?? 0,
      attendanceDate: json['attendance_date'] as String? ?? '',
      attendanceType: json['attendance_type'] as String? ?? '',
      admissionNo: json['admission_no'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}
