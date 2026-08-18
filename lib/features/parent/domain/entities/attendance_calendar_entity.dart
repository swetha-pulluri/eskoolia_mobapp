/// Mirrors `ChildAttendanceCalendarView`'s real response
/// (`GET /api/v1/parent/attendance/?child_id=<id>&month=YYYY-MM`) — daily
/// attendance records for one child/month, plus school holidays and a
/// month summary. See web's `lib/api/parent.ts`'s `AttendanceCalendar`.
class AttendanceCalendarEntity {
  final int year;
  final int month;
  final int childId;
  final String childName;
  final List<AttendanceDayEntity> days;
  final List<HolidayEntity> holidays;
  final AttendanceCalendarSummaryEntity summary;

  const AttendanceCalendarEntity({
    required this.year,
    required this.month,
    required this.childId,
    required this.childName,
    this.days = const [],
    this.holidays = const [],
    required this.summary,
  });

  factory AttendanceCalendarEntity.fromJson(Map<String, dynamic> json) => AttendanceCalendarEntity(
        year: json['year'] as int,
        month: json['month'] as int,
        childId: json['child_id'] as int? ?? 0,
        childName: (json['child_name'] as String?) ?? '',
        days: ((json['days'] as List?) ?? const [])
            .map((e) => AttendanceDayEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        holidays: ((json['holidays'] as List?) ?? const [])
            .map((e) => HolidayEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        summary: json['summary'] != null
            ? AttendanceCalendarSummaryEntity.fromJson(json['summary'] as Map<String, dynamic>)
            : const AttendanceCalendarSummaryEntity(present: 0, absent: 0, late: 0, halfDay: 0, total: 0, pct: null),
      );
}

/// `type` is one of 'P' (present) | 'A' (absent) | 'L' (late) | 'F' (half
/// day) | 'H' (holiday), matching `StudentAttendance.attendance_type` verbatim.
class AttendanceDayEntity {
  final String date;
  final String type;
  const AttendanceDayEntity({required this.date, required this.type});

  factory AttendanceDayEntity.fromJson(Map<String, dynamic> json) => AttendanceDayEntity(
        date: (json['date'] as String?) ?? '',
        type: (json['type'] as String?) ?? '',
      );
}

class HolidayEntity {
  final String date;
  final String title;
  const HolidayEntity({required this.date, required this.title});

  factory HolidayEntity.fromJson(Map<String, dynamic> json) => HolidayEntity(
        date: (json['date'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
      );
}

class AttendanceCalendarSummaryEntity {
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int total;
  final double? pct;

  const AttendanceCalendarSummaryEntity({
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.total,
    this.pct,
  });

  factory AttendanceCalendarSummaryEntity.fromJson(Map<String, dynamic> json) => AttendanceCalendarSummaryEntity(
        present: json['present'] as int? ?? 0,
        absent: json['absent'] as int? ?? 0,
        late: json['late'] as int? ?? 0,
        halfDay: json['half_day'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        pct: (json['pct'] as num?)?.toDouble(),
      );
}
