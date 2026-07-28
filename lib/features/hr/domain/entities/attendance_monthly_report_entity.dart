/// One entry per attendance row in the selected month — matches the real
/// `StaffAttendanceViewSet.monthly_report` action's `records` list
/// (`origin/demo`'s `apps/hr/views.py`), used client-side to compute the
/// week-donut cards exactly like the real web's `StaffMonthlyReport.tsx`.
class AttendanceMonthlyRecordEntity {
  final int staffId;
  final String attendanceDate; // yyyy-MM-dd
  final String attendanceType;

  const AttendanceMonthlyRecordEntity({required this.staffId, required this.attendanceDate, required this.attendanceType});

  factory AttendanceMonthlyRecordEntity.fromJson(Map<String, dynamic> json) {
    return AttendanceMonthlyRecordEntity(
      staffId: json['staff'] as int? ?? 0,
      attendanceDate: json['attendance_date'] as String? ?? '',
      attendanceType: json['attendance_type'] as String? ?? '',
    );
  }
}

/// Per-staff monthly totals — matches `monthly_report`'s `rows` list.
class AttendanceMonthlyRowEntity {
  final int staffId;
  final String name;
  final String staffNo;
  final String departmentName;
  final int present;
  final int absent;
  final int leave;
  final int halfDay;
  final int holiday;

  const AttendanceMonthlyRowEntity({
    required this.staffId,
    required this.name,
    required this.staffNo,
    required this.departmentName,
    this.present = 0,
    this.absent = 0,
    this.leave = 0,
    this.halfDay = 0,
    this.holiday = 0,
  });

  factory AttendanceMonthlyRowEntity.fromJson(Map<String, dynamic> json) {
    return AttendanceMonthlyRowEntity(
      staffId: json['staff_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      staffNo: json['staff_no'] as String? ?? '',
      departmentName: json['department_name'] as String? ?? '',
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      leave: json['leave'] as int? ?? 0,
      halfDay: json['half_day'] as int? ?? 0,
      holiday: json['holiday'] as int? ?? 0,
    );
  }
}

/// A single ranked reason mined from attendance notes — matches
/// `monthly_report`'s `insights.top_absent_reasons`/`top_leave_reasons`.
class AttendanceReasonInsightEntity {
  final String reason;
  final int count;

  const AttendanceReasonInsightEntity({required this.reason, required this.count});

  factory AttendanceReasonInsightEntity.fromJson(Map<String, dynamic> json) {
    return AttendanceReasonInsightEntity(reason: json['reason'] as String? ?? '', count: json['count'] as int? ?? 0);
  }
}

/// Full `GET /api/v1/hr/staff-attendance/monthly-report/` response —
/// `{records, rows, insights: {top_absent_reasons, top_leave_reasons}}`.
class AttendanceMonthlyReportEntity {
  final List<AttendanceMonthlyRecordEntity> records;
  final List<AttendanceMonthlyRowEntity> rows;
  final List<AttendanceReasonInsightEntity> topAbsentReasons;
  final List<AttendanceReasonInsightEntity> topLeaveReasons;

  const AttendanceMonthlyReportEntity({
    this.records = const [],
    this.rows = const [],
    this.topAbsentReasons = const [],
    this.topLeaveReasons = const [],
  });

  factory AttendanceMonthlyReportEntity.fromJson(Map<String, dynamic> json) {
    final insights = (json['insights'] as Map<String, dynamic>?) ?? const {};
    return AttendanceMonthlyReportEntity(
      records: ((json['records'] as List?) ?? const []).map((e) => AttendanceMonthlyRecordEntity.fromJson(e as Map<String, dynamic>)).toList(),
      rows: ((json['rows'] as List?) ?? const []).map((e) => AttendanceMonthlyRowEntity.fromJson(e as Map<String, dynamic>)).toList(),
      topAbsentReasons: ((insights['top_absent_reasons'] as List?) ?? const []).map((e) => AttendanceReasonInsightEntity.fromJson(e as Map<String, dynamic>)).toList(),
      topLeaveReasons: ((insights['top_leave_reasons'] as List?) ?? const []).map((e) => AttendanceReasonInsightEntity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
