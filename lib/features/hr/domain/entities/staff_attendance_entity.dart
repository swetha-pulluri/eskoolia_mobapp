/// Mirrors the real `StaffAttendance` model / `StaffAttendanceSerializer` on
/// `origin/demo` (confirmed the actual live backend for HR features this
/// session) — `staff`, `attendance_date`, `attendance_type`, `note`,
/// `arrival_time`, `sign_in_time`, `sign_out_time`, `lunch` all exist as
/// real fields there. (`main` lacks the last four — an earlier pass checked
/// only that stale branch and wrongly concluded they didn't exist anywhere.)
class StaffAttendanceEntity {
  final int id;
  final int staffId;
  final String staffName;
  final String attendanceDate; // yyyy-MM-dd
  final String attendanceType; // P, A, L, F, H
  final String note;
  final String? arrivalTime; // HH:mm
  final String? signInTime; // HH:mm
  final String? signOutTime; // HH:mm
  final bool lunch;

  const StaffAttendanceEntity({
    this.id = 0,
    required this.staffId,
    this.staffName = '',
    required this.attendanceDate,
    this.attendanceType = 'P',
    this.note = '',
    this.arrivalTime,
    this.signInTime,
    this.signOutTime,
    this.lunch = false,
  });

  factory StaffAttendanceEntity.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceEntity(
      id: json['id'] as int? ?? 0,
      staffId: json['staff'] as int? ?? 0,
      staffName: json['staff_name'] as String? ?? '',
      attendanceDate: json['attendance_date'] as String? ?? '',
      attendanceType: json['attendance_type'] as String? ?? 'P',
      note: json['note'] as String? ?? '',
      arrivalTime: json['arrival_time'] as String?,
      signInTime: json['sign_in_time'] as String?,
      signOutTime: json['sign_out_time'] as String?,
      lunch: json['lunch'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff': staffId,
      'attendance_date': attendanceDate,
      'attendance_type': attendanceType,
      'note': note,
      'arrival_time': arrivalTime,
      'sign_in_time': signInTime,
      'sign_out_time': signOutTime,
      'lunch': lunch,
    };
  }

  StaffAttendanceEntity copyWith({
    int? id,
    String? attendanceType,
    String? note,
    Object? arrivalTime = _unset,
    Object? signInTime = _unset,
    Object? signOutTime = _unset,
    bool? lunch,
  }) {
    return StaffAttendanceEntity(
      id: id ?? this.id,
      staffId: staffId,
      staffName: staffName,
      attendanceDate: attendanceDate,
      attendanceType: attendanceType ?? this.attendanceType,
      note: note ?? this.note,
      arrivalTime: arrivalTime == _unset ? this.arrivalTime : arrivalTime as String?,
      signInTime: signInTime == _unset ? this.signInTime : signInTime as String?,
      signOutTime: signOutTime == _unset ? this.signOutTime : signOutTime as String?,
      lunch: lunch ?? this.lunch,
    );
  }
}

const _unset = Object();

/// Matches the real `StaffAttendanceViewSet.report` action's response
/// exactly: `{total, by_type: {P, A, L, F, H}}`.
class AttendanceReportEntity {
  final int total;
  final Map<String, int> byType;

  const AttendanceReportEntity({this.total = 0, this.byType = const {}});

  factory AttendanceReportEntity.fromJson(Map<String, dynamic> json) {
    final rawByType = (json['by_type'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AttendanceReportEntity(
      total: json['total'] as int? ?? 0,
      byType: rawByType.map((k, v) => MapEntry(k, v as int? ?? 0)),
    );
  }

  int countOf(String code) => byType[code] ?? 0;
}
