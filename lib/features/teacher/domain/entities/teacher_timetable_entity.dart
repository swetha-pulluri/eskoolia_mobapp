/// Mirrors `build_weekly_timetable()`'s response
/// (`GET /api/v1/teacher/timetable/`) field-for-field.
class TeacherTimetableEntity {
  final String weekOf;
  final List<TimetableDayEntity> days;
  final TimetableKpisEntity kpis;

  const TeacherTimetableEntity({required this.weekOf, this.days = const [], required this.kpis});

  factory TeacherTimetableEntity.fromJson(Map<String, dynamic> json) => TeacherTimetableEntity(
        weekOf: (json['week_of'] as String?) ?? '',
        days: ((json['days'] as List?) ?? const []).map((e) => TimetableDayEntity.fromJson(e as Map<String, dynamic>)).toList(),
        kpis: TimetableKpisEntity.fromJson(json['kpis'] as Map<String, dynamic>? ?? const {}),
      );
}

class TimetableDayEntity {
  final String day;
  final String dayKey;
  final bool isToday;
  final List<TimetableSlotEntity> periods;

  const TimetableDayEntity({required this.day, required this.dayKey, required this.isToday, this.periods = const []});

  factory TimetableDayEntity.fromJson(Map<String, dynamic> json) => TimetableDayEntity(
        day: (json['day'] as String?) ?? '',
        dayKey: (json['day_key'] as String?) ?? '',
        isToday: json['is_today'] as bool? ?? false,
        periods: ((json['periods'] as List?) ?? const [])
            .map((e) => TimetableSlotEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// `period` is genuinely nullable at the DB layer
/// (`ClassRoutineSlot.class_period_id` is a plain
/// `PositiveIntegerField(null=True)`, cast straight through — an int, NOT
/// a string). Kept as its own type here rather than reusing the Home
/// dashboard's `TeacherPeriodEntity` (`teacher_me_entity.dart`), which
/// mistypes this same field as `String` — a pre-existing bug out of scope
/// for this module (see plan notes / follow-up report to the user).
class TimetableSlotEntity {
  final int? period;
  final String subject;
  final String className;
  final String sectionName;
  final String room;
  final String from;
  final String to;
  final bool isBreak;
  final bool isNow;
  final bool isDone;

  const TimetableSlotEntity({
    this.period,
    required this.subject,
    required this.className,
    required this.sectionName,
    this.room = '',
    required this.from,
    required this.to,
    this.isBreak = false,
    this.isNow = false,
    this.isDone = false,
  });

  factory TimetableSlotEntity.fromJson(Map<String, dynamic> json) => TimetableSlotEntity(
        period: json['period'] as int?,
        subject: (json['subject'] as String?) ?? '',
        className: (json['class_name'] as String?) ?? '',
        sectionName: (json['section_name'] as String?) ?? '',
        room: (json['room'] as String?) ?? '',
        from: (json['from'] as String?) ?? '',
        to: (json['to'] as String?) ?? '',
        isBreak: json['is_break'] as bool? ?? false,
        isNow: json['is_now'] as bool? ?? false,
        isDone: json['is_done'] as bool? ?? false,
      );
}

/// `freePeriods`/`coverAssignments` are hardcoded to `0` server-side today
/// (`cover_count` never incremented; `free_periods` has a stale "calculated
/// after period grid is known" comment but no actual calculation) — kept
/// as the real, disclosed API value here, not upgraded into a fabricated
/// count.
class TimetableKpisEntity {
  final int totalPeriods;
  final int freePeriods;
  final int coverAssignments;
  final int teachingDays;

  const TimetableKpisEntity({
    required this.totalPeriods,
    required this.freePeriods,
    required this.coverAssignments,
    required this.teachingDays,
  });

  factory TimetableKpisEntity.fromJson(Map<String, dynamic> json) => TimetableKpisEntity(
        totalPeriods: json['total_periods'] as int? ?? 0,
        freePeriods: json['free_periods'] as int? ?? 0,
        coverAssignments: json['cover_assignments'] as int? ?? 0,
        teachingDays: json['teaching_days'] as int? ?? 0,
      );
}
