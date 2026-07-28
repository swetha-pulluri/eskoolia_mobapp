/// Matches the real `StaffAttendanceViewSet.daily_summary` action's
/// response exactly (`origin/demo`'s `apps/hr/views.py`) — the actual
/// source for the Attendance page's KPI row, including the "Late Arrivals"
/// card and the correct active-staff total (school-scoped, not whatever
/// page-size a generic staff list happens to return).
class AttendanceDailySummaryEntity {
  final int totalStaff;
  final int present;
  final int absent;
  final int leave;
  final int halfDay;
  final int holiday;
  final int lateArrivals;
  final int marked;
  final int presentPct;

  const AttendanceDailySummaryEntity({
    this.totalStaff = 0,
    this.present = 0,
    this.absent = 0,
    this.leave = 0,
    this.halfDay = 0,
    this.holiday = 0,
    this.lateArrivals = 0,
    this.marked = 0,
    this.presentPct = 0,
  });

  factory AttendanceDailySummaryEntity.fromJson(Map<String, dynamic> json) {
    return AttendanceDailySummaryEntity(
      totalStaff: json['total_staff'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      leave: json['leave'] as int? ?? 0,
      halfDay: json['half_day'] as int? ?? 0,
      holiday: json['holiday'] as int? ?? 0,
      lateArrivals: json['late_arrivals'] as int? ?? 0,
      marked: json['marked'] as int? ?? 0,
      presentPct: json['present_pct'] as int? ?? 0,
    );
  }
}
