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
}
