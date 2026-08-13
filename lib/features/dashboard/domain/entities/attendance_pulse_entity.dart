/// Home screen → "Today's Pulse" → Student Attendance card. Reference:
/// backend/apps/attendance/views.py::StudentAttendanceDashboardAPIView,
/// frontend/components/widgets/pulse/AttendanceSnapshot.tsx.
///
/// Field names are snake_case on the wire (unlike [FeesTodayEntity], whose
/// endpoint returns camelCase) — confirmed against the real backend view,
/// not a porting inconsistency to "fix".
class AttendancePulseEntity {
  final double attendancePercentage;
  final int present;
  final int absent;
  final int leave;
  final int late;
  final int markedTeachers;
  final int totalTeachers;
  final String lastUpdated;
  final List<double> trend;
  final List<PendingClassEntity> pendingClasses;

  const AttendancePulseEntity({
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.leave,
    required this.late,
    required this.markedTeachers,
    required this.totalTeachers,
    required this.lastUpdated,
    required this.trend,
    required this.pendingClasses,
  });

  const AttendancePulseEntity.empty()
      : attendancePercentage = 0,
        present = 0,
        absent = 0,
        leave = 0,
        late = 0,
        markedTeachers = 0,
        totalTeachers = 0,
        lastUpdated = '—',
        trend = const [],
        pendingClasses = const [];

  factory AttendancePulseEntity.fromJson(Map<String, dynamic> json) {
    return AttendancePulseEntity(
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      leave: json['leave'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      markedTeachers: json['marked_teachers'] as int? ?? 0,
      totalTeachers: json['total_teachers'] as int? ?? 0,
      lastUpdated: json['last_updated'] as String? ?? '—',
      trend: ((json['trend'] as List?) ?? const []).map((e) => (e as num).toDouble()).toList(),
      pendingClasses: ((json['pending_classes'] as List?) ?? const [])
          .map((e) => PendingClassEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// One entry in `pending_classes` — a section with zero attendance rows
/// marked yet today.
class PendingClassEntity {
  final String name;
  final String sectionId;

  const PendingClassEntity({required this.name, required this.sectionId});

  factory PendingClassEntity.fromJson(Map<String, dynamic> json) {
    final sectionId = json['section_id']?.toString() ?? '';
    return PendingClassEntity(
      name: json['name'] as String? ?? 'Section $sectionId',
      sectionId: sectionId,
    );
  }
}
