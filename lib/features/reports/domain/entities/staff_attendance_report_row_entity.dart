/// One row of `GET /api/v1/reports/hr/staff-attendance/` — mirrors the
/// real backend's `HrStaffAttendanceRowSerializer` field names exactly
/// (`backend/apps/reports/serializers.py`): `staff_name` (not `name`),
/// `note` (singular), and `attendance_type` as a single-letter code (no
/// separate `status` field).
class StaffAttendanceReportRowEntity {
  final int attendanceId;
  final String attendanceDate;
  final String attendanceType; // P | A | L | F | H
  final String staffNo;
  final String staffName;
  final String department;
  final String designation;
  final String note;

  const StaffAttendanceReportRowEntity({
    required this.attendanceId,
    required this.attendanceDate,
    required this.attendanceType,
    required this.staffNo,
    required this.staffName,
    required this.department,
    required this.designation,
    required this.note,
  });

  factory StaffAttendanceReportRowEntity.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceReportRowEntity(
      attendanceId: json['attendance_id'] as int? ?? 0,
      attendanceDate: json['attendance_date'] as String? ?? '',
      attendanceType: json['attendance_type'] as String? ?? '',
      staffNo: json['staff_no'] as String? ?? '',
      staffName: json['staff_name'] as String? ?? '',
      department: json['department'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}
