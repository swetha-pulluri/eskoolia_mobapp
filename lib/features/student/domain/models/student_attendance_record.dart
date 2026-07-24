/// A single day's attendance record for one student — Source: frontend
/// StudentListPanel.tsx's drawer Attendance tab (`drawerAttendance` state).
/// Backend: GET /api/v1/attendance/student-attendance/?student_id=&date_from=
/// &date_to= (apps/attendance). The backend field is a letter code
/// (`attendance_type`: P/A/L/F/H) — normalised here into the same full-word
/// statuses the frontend maps to (`present`/`absent`/`late`/`holiday`), via
/// the identical P→present, A→absent, L→late, F→absent, H→holiday mapping.
class StudentAttendanceRecord {
  final DateTime date;
  final String status;
  final String? remarks;

  const StudentAttendanceRecord({
    required this.date,
    required this.status,
    this.remarks,
  });

  static const Map<String, String> _typeMap = {
    'P': 'present',
    'A': 'absent',
    'L': 'late',
    'F': 'absent',
    'H': 'holiday',
  };

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawType = (json['attendance_type'] as String? ?? json['status'] as String? ?? '').toUpperCase();
    final status = _typeMap[rawType] ?? (json['status'] as String? ?? '').toLowerCase();
    return StudentAttendanceRecord(
      date: DateTime.parse(json['attendance_date'] as String),
      status: status,
      remarks: json['remarks'] as String?,
    );
  }

  /// `yyyy-MM-dd`, matching the backend's own date string format — used as
  /// a map key the same way the frontend keys `attMap` by raw date string.
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
