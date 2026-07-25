/// Mirrors web `app/(dashboard)/attendance/student/types.ts` verbatim.
library;

/// "live" | "partial" | "none"
typedef SyncStatus = String;

/// "present" | "absent" | "late" | "unmarked"
typedef AttendanceStatus = String;

/// "all" | "primary" | "middle" | "secondary"
typedef LevelFilter = String;

class SectionSummaryEntity {
  final int id;
  final String name;
  final int studentCount;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int unmarkedCount;
  final int attendancePct;
  final SyncStatus syncStatus;

  const SectionSummaryEntity({
    required this.id,
    required this.name,
    this.studentCount = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.unmarkedCount = 0,
    this.attendancePct = 0,
    this.syncStatus = 'none',
  });

  /// Mirrors backend `core.Section` / `SectionSerializer`
  /// (`id, school_class, name, capacity, student_count, created_at`).
  factory SectionSummaryEntity.fromJson(Map<String, dynamic> json) {
    return SectionSummaryEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClassInfoEntity {
  final int id;
  final String name;
  final String displayLabel;
  final String subLabel;
  /// "primary" | "middle" | "secondary"
  final String level;
  final List<SectionSummaryEntity> sections;
  final int totalStudents;
  final int totalPresent;
  final int? totalSignedIn;
  final int totalAbsent;
  final int totalLate;
  final int overallPct;
  final SyncStatus syncStatus;

  const ClassInfoEntity({
    required this.id,
    required this.name,
    required this.displayLabel,
    this.subLabel = '',
    this.level = 'primary',
    this.sections = const [],
    this.totalStudents = 0,
    this.totalPresent = 0,
    this.totalSignedIn,
    this.totalAbsent = 0,
    this.totalLate = 0,
    this.overallPct = 0,
    this.syncStatus = 'none',
  });

  /// Mirrors backend `core.Class` / `ClassSerializer`
  /// (`GET /api/v1/core/classes/`) — nests `sections` directly, matching
  /// web's `hooks/useClasses.ts` mapping (`display_label` = name as-is,
  /// `level` derived via the same grade-number heuristic web uses:
  /// Nursery/LKG/UKG or grade ≤5 → primary, ≤8 → middle, else secondary).
  factory ClassInfoEntity.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final sectionsJson = json['sections'] as List? ?? const [];
    final sections = sectionsJson.map((e) => SectionSummaryEntity.fromJson(e as Map<String, dynamic>)).toList();
    final totalStudents = (json['total_students'] as num?)?.toInt() ?? sections.fold<int>(0, (s, sec) => s + sec.studentCount);
    return ClassInfoEntity(
      id: json['id'] as int,
      name: name,
      displayLabel: name,
      level: _levelFor(name),
      sections: sections,
      totalStudents: totalStudents,
    );
  }

  static String _levelFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('nursery') || lower.contains('lkg') || lower.contains('ukg')) return 'primary';
    final m = RegExp(r'\d+').firstMatch(lower);
    final grade = m != null ? int.tryParse(m.group(0)!) : null;
    if (grade == null) return 'primary';
    if (grade <= 5) return 'primary';
    if (grade <= 8) return 'middle';
    return 'secondary';
  }

  ClassInfoEntity copyWith({
    List<SectionSummaryEntity>? sections,
    int? totalStudents,
    int? totalPresent,
    int? totalSignedIn,
    int? totalAbsent,
    int? totalLate,
    int? overallPct,
    SyncStatus? syncStatus,
  }) {
    return ClassInfoEntity(
      id: id,
      name: name,
      displayLabel: displayLabel,
      subLabel: subLabel,
      level: level,
      sections: sections ?? this.sections,
      totalStudents: totalStudents ?? this.totalStudents,
      totalPresent: totalPresent ?? this.totalPresent,
      totalSignedIn: totalSignedIn ?? this.totalSignedIn,
      totalAbsent: totalAbsent ?? this.totalAbsent,
      totalLate: totalLate ?? this.totalLate,
      overallPct: overallPct ?? this.overallPct,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class StudentNoteEntity {
  final String id;
  final String text;
  final String createdAt;
  const StudentNoteEntity({required this.id, required this.text, this.createdAt = ''});
}

class AttendanceStudentEntity {
  final int id;
  final String admissionNo;
  final String rollNo;
  final String fullName;
  final String initials;
  final int avatarColor; // ARGB int, from AVATAR_COLORS cycle
  final String group;
  final bool syncedFromApp;
  final int? rtePct;
  final AttendanceStatus status;
  final String? absentReason;
  final String? arrivalTime;
  final bool isLate;
  final bool isSchoolApprovedLate;
  final int lateMinutes;
  final String? signInTime;
  final String? signOutTime;
  final String? pickupTime;
  final String? pickupBy;
  final bool lunch;
  final List<StudentNoteEntity> notes;

  const AttendanceStudentEntity({
    required this.id,
    required this.admissionNo,
    required this.rollNo,
    required this.fullName,
    required this.initials,
    required this.avatarColor,
    this.group = '',
    this.syncedFromApp = false,
    this.rtePct,
    this.status = 'unmarked',
    this.absentReason,
    this.arrivalTime,
    this.isLate = false,
    this.isSchoolApprovedLate = false,
    this.lateMinutes = 0,
    this.signInTime,
    this.signOutTime,
    this.pickupTime,
    this.pickupBy,
    this.lunch = false,
    this.notes = const [],
  });

  int get notesCount => notes.length;

  /// Mirrors backend `student-attendance/student-search/` response's
  /// per-student shape (`views.py:369-414`): `id, admission_no, first_name,
  /// last_name, roll_no, attendance_type|null, attendance_note,
  /// arrival_time, sign_in_time, sign_out_time, pickup_time, pickup_by,
  /// lunch`. `notes`/`rtePct` have no server field (see the module's known,
  /// disclosed gaps) and start empty/null; `attendance_note` seeds the
  /// single note the record actually has, matching the one-field-really
  /// backs-"notes" reality confirmed against the real web source.
  factory AttendanceStudentEntity.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final first = json['first_name'] as String? ?? '';
    final last = json['last_name'] as String? ?? '';
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
    final type = json['attendance_type'] as String?;
    final note = json['attendance_note'] as String?;
    return AttendanceStudentEntity(
      id: id,
      admissionNo: json['admission_no']?.toString() ?? '',
      rollNo: json['roll_no']?.toString() ?? '',
      fullName: fullName.isEmpty ? 'Student $id' : fullName,
      initials: _initialsOf(fullName.isEmpty ? 'S' : fullName),
      avatarColor: kAttendanceAvatarColors[id % kAttendanceAvatarColors.length],
      status: _statusForType(type),
      absentReason: (note != null && note.isNotEmpty) ? note : null,
      arrivalTime: json['arrival_time'] as String?,
      isLate: type == 'L',
      signInTime: json['sign_in_time'] as String?,
      signOutTime: json['sign_out_time'] as String?,
      pickupTime: json['pickup_time'] as String?,
      pickupBy: json['pickup_by'] as String?,
      lunch: json['lunch'] == true,
      notes: (note != null && note.isNotEmpty) ? [StudentNoteEntity(id: 'server-note-$id', text: note)] : const [],
    );
  }

  AttendanceStudentEntity copyWith({
    AttendanceStatus? status,
    Object? absentReason = _sentinel,
    Object? arrivalTime = _sentinel,
    bool? isLate,
    bool? isSchoolApprovedLate,
    int? lateMinutes,
    Object? signInTime = _sentinel,
    Object? signOutTime = _sentinel,
    Object? pickupTime = _sentinel,
    Object? pickupBy = _sentinel,
    bool? lunch,
    List<StudentNoteEntity>? notes,
  }) {
    return AttendanceStudentEntity(
      id: id,
      admissionNo: admissionNo,
      rollNo: rollNo,
      fullName: fullName,
      initials: initials,
      avatarColor: avatarColor,
      group: group,
      syncedFromApp: syncedFromApp,
      rtePct: rtePct,
      status: status ?? this.status,
      absentReason: identical(absentReason, _sentinel) ? this.absentReason : absentReason as String?,
      arrivalTime: identical(arrivalTime, _sentinel) ? this.arrivalTime : arrivalTime as String?,
      isLate: isLate ?? this.isLate,
      isSchoolApprovedLate: isSchoolApprovedLate ?? this.isSchoolApprovedLate,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      signInTime: identical(signInTime, _sentinel) ? this.signInTime : signInTime as String?,
      signOutTime: identical(signOutTime, _sentinel) ? this.signOutTime : signOutTime as String?,
      pickupTime: identical(pickupTime, _sentinel) ? this.pickupTime : pickupTime as String?,
      pickupBy: identical(pickupBy, _sentinel) ? this.pickupBy : pickupBy as String?,
      lunch: lunch ?? this.lunch,
      notes: notes ?? this.notes,
    );
  }
}

const _sentinel = Object();

/// AVATAR_COLORS from web's `useStudents.ts`, cycled by `id % 6`.
const List<int> kAttendanceAvatarColors = [0xFF4729F4, 0xFF0A8C5A, 0xFFB4721B, 0xFFC2264E, 0xFF7B61FF, 0xFF0891B2];

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
  final initials = parts.map((p) => p[0].toUpperCase()).join();
  return initials.isEmpty ? 'S' : initials;
}

/// 'P'|'A'|'L'|'F'|'H'|null -> 'present'|'absent'|'late'|'unmarked'.
String _statusForType(String? type) {
  switch (type) {
    case 'P':
      return 'present';
    case 'A':
      return 'absent';
    case 'L':
      return 'late';
    default:
      return 'unmarked';
  }
}

/// 'present'|'absent'|'late'|'unmarked' -> 'P'|'A'|'L' for the `store/` payload.
String attendanceTypeForStatus(String status) {
  switch (status) {
    case 'present':
      return 'P';
    case 'absent':
      return 'A';
    case 'late':
      return 'L';
    default:
      return 'P';
  }
}

class KpiDataEntity {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final int lateToday;
  final int classesMarked;
  final int totalClasses;
  final int presentPct;
  final int weeklyAvgPct;
  final int chronicAbsentees;
  final int rteAtRisk;
  final int absentWithReason;
  final String? lateStudentName;
  final int? lateMinutes;
  final int deltaPct;
  final int? absentDelta;

  const KpiDataEntity({
    this.totalStudents = 0,
    this.presentToday = 0,
    this.absentToday = 0,
    this.lateToday = 0,
    this.classesMarked = 0,
    this.totalClasses = 0,
    this.presentPct = 0,
    this.weeklyAvgPct = 0,
    this.chronicAbsentees = 0,
    this.rteAtRisk = 0,
    this.absentWithReason = 0,
    this.lateStudentName,
    this.lateMinutes,
    this.deltaPct = 0,
    this.absentDelta,
  });

  /// Mirrors backend `student-attendance/daily-summary/` response exactly:
  /// `{date, total_students, present, absent, absent_with_reason, late,
  /// unmarked}`. There is genuinely no `rte_at_risk` field server-side
  /// (confirmed directly against the backend) — matching web's own honest
  /// behavior, `rteAtRisk` stays 0 rather than being invented client-side.
  factory KpiDataEntity.fromJson(Map<String, dynamic> json) {
    final total = (json['total_students'] as num?)?.toInt() ?? 0;
    final present = (json['present'] as num?)?.toInt() ?? 0;
    return KpiDataEntity(
      totalStudents: total,
      presentToday: present,
      absentToday: (json['absent'] as num?)?.toInt() ?? 0,
      lateToday: (json['late'] as num?)?.toInt() ?? 0,
      absentWithReason: (json['absent_with_reason'] as num?)?.toInt() ?? 0,
      presentPct: total > 0 ? ((present / total) * 100).round() : 0,
    );
  }
}

class DailyAttendanceRecordEntity {
  final int id;
  final int studentId;
  final String attendanceDate;
  /// 'P' | 'A' | 'L' | 'F' | 'H'
  final String attendanceType;
  final int? classId;
  final int? sectionId;
  const DailyAttendanceRecordEntity({
    required this.id,
    required this.studentId,
    required this.attendanceDate,
    required this.attendanceType,
    this.classId,
    this.sectionId,
  });

  /// Mirrors the bare `GET /api/v1/attendance/student-attendance/` list
  /// endpoint's raw row shape — used only to build the Monthly Report's
  /// week-by-week cards client-side, matching web's own approach (its
  /// comment explains the backend's `report-insights` week-numbering
  /// doesn't align to calendar Sun-Sat boundaries, so it recomputes from
  /// raw records instead of trusting that endpoint's own `weekly` field).
  factory DailyAttendanceRecordEntity.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceRecordEntity(
      id: json['id'] as int,
      studentId: json['student'] as int? ?? 0,
      attendanceDate: json['attendance_date'] as String? ?? '',
      attendanceType: json['attendance_type'] as String? ?? '',
      classId: json['class_id'] as int?,
      sectionId: json['section_id'] as int?,
    );
  }
}

/// Per-class dashboard tile — mirrors
/// `GET student-attendance/class-summary/`'s `classes[]` entries exactly
/// (`class_id, total, present, signed_in, absent, late, unmarked, pct`).
class ClassSummaryTileEntity {
  final int classId;
  final int total;
  final int present;
  final int signedIn;
  final int absent;
  final int late;
  final int unmarked;
  final double pct;
  const ClassSummaryTileEntity({
    required this.classId,
    this.total = 0,
    this.present = 0,
    this.signedIn = 0,
    this.absent = 0,
    this.late = 0,
    this.unmarked = 0,
    this.pct = 0,
  });

  factory ClassSummaryTileEntity.fromJson(Map<String, dynamic> json) {
    return ClassSummaryTileEntity(
      classId: json['class_id'] as int,
      total: (json['total'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      signedIn: (json['signed_in'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      unmarked: (json['unmarked'] as num?)?.toInt() ?? 0,
      pct: (json['pct'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One row of the Monthly Report's Student Summary table — mirrors
/// `GET student-attendance/report/`'s paginated result rows exactly.
class MonthlyReportRowEntity {
  final int studentId;
  final String admissionNo;
  final String name;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int holiday;
  const MonthlyReportRowEntity({
    required this.studentId,
    this.admissionNo = '',
    this.name = '',
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.halfDay = 0,
    this.holiday = 0,
  });

  factory MonthlyReportRowEntity.fromJson(Map<String, dynamic> json) {
    return MonthlyReportRowEntity(
      studentId: json['student_id'] as int,
      admissionNo: json['admission_no']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      halfDay: (json['half_day'] as num?)?.toInt() ?? 0,
      holiday: (json['holiday'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReasonCountEntity {
  final String reason;
  final int count;
  const ReasonCountEntity({required this.reason, required this.count});

  factory ReasonCountEntity.fromJson(Map<String, dynamic> json) {
    return ReasonCountEntity(reason: json['reason'] as String? ?? '', count: (json['count'] as num?)?.toInt() ?? 0);
  }
}

/// Mirrors `GET student-attendance/report-insights/` response
/// (`{weekly:[...], top_absent_reasons:[...], top_late_reasons:[...]}`).
/// The Flutter Monthly Report recomputes its own week cards from raw
/// records rather than trusting `weekly` here, matching web's own
/// documented workaround — so `weekly` is parsed but intentionally unused
/// by the report widget.
class ReportInsightsEntity {
  final List<ReasonCountEntity> topAbsentReasons;
  final List<ReasonCountEntity> topLateReasons;
  const ReportInsightsEntity({this.topAbsentReasons = const [], this.topLateReasons = const []});

  factory ReportInsightsEntity.fromJson(Map<String, dynamic> json) {
    return ReportInsightsEntity(
      topAbsentReasons: (json['top_absent_reasons'] as List? ?? const [])
          .map((e) => ReasonCountEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      topLateReasons: (json['top_late_reasons'] as List? ?? const [])
          .map((e) => ReasonCountEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
