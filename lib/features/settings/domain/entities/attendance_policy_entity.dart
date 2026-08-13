/// Settings → Attendance Rules: one `SchoolAttendancePolicy` record.
/// Reference: backend/apps/settings/models.py::SchoolAttendancePolicy,
/// backend/apps/settings/serializers.py::SchoolAttendancePolicySerializer,
/// frontend/components/settings/AttendanceRulesPanel.tsx.
class AttendanceRoleRef {
  final int id;
  final String name;

  const AttendanceRoleRef({required this.id, required this.name});

  factory AttendanceRoleRef.fromJson(Map<String, dynamic> json) {
    return AttendanceRoleRef(id: json['id'] as int, name: json['name'] as String? ?? '');
  }
}

class AttendancePolicyEntity {
  final int id;
  final String name;
  final bool isDefault;
  final bool isActive;
  final List<AttendanceRoleRef> appliesToRolesDetail;

  final String shiftStart;
  final String shiftEnd;
  final int gracePeriodMinutes;
  final int missingPunchGraceMinutes;
  final int breakDurationMinutes;
  final String minHoursFullDay;
  final String minHoursHalfDay;
  final int earlyExitGraceMinutes;
  final String otThresholdHours;
  final String otMultiplierRegular;
  final String otMultiplierHoliday;

  final int lateMarksPerLop;
  final String lopDeductionUnit;

  final bool weeklyOffMon;
  final bool weeklyOffTue;
  final bool weeklyOffWed;
  final bool weeklyOffThu;
  final bool weeklyOffFri;
  final bool weeklyOffSat;
  final bool weeklyOffSun;

  final bool absenceAlertEnabled;
  final int absenceAlertAfterDays;
  final String absenceAlertNotifyWhom;

  final String? createdByName;
  final String? updatedByName;
  final String? updatedAt;
  final String? createdAt;

  const AttendancePolicyEntity({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.isActive,
    required this.appliesToRolesDetail,
    required this.shiftStart,
    required this.shiftEnd,
    required this.gracePeriodMinutes,
    required this.missingPunchGraceMinutes,
    required this.breakDurationMinutes,
    required this.minHoursFullDay,
    required this.minHoursHalfDay,
    required this.earlyExitGraceMinutes,
    required this.otThresholdHours,
    required this.otMultiplierRegular,
    required this.otMultiplierHoliday,
    required this.lateMarksPerLop,
    required this.lopDeductionUnit,
    required this.weeklyOffMon,
    required this.weeklyOffTue,
    required this.weeklyOffWed,
    required this.weeklyOffThu,
    required this.weeklyOffFri,
    required this.weeklyOffSat,
    required this.weeklyOffSun,
    required this.absenceAlertEnabled,
    required this.absenceAlertAfterDays,
    required this.absenceAlertNotifyWhom,
    required this.createdByName,
    required this.updatedByName,
    required this.updatedAt,
    required this.createdAt,
  });

  static bool _bool(Map<String, dynamic> json, String key, {bool fallback = false}) =>
      json[key] as bool? ?? fallback;
  static int _int(Map<String, dynamic> json, String key, {int fallback = 0}) =>
      (json[key] as num?)?.toInt() ?? fallback;
  static String _str(Map<String, dynamic> json, String key, {String fallback = ''}) =>
      json[key] as String? ?? fallback;

  factory AttendancePolicyEntity.fromJson(Map<String, dynamic> json) {
    return AttendancePolicyEntity(
      id: json['id'] as int,
      name: _str(json, 'name'),
      isDefault: _bool(json, 'is_default'),
      isActive: _bool(json, 'is_active', fallback: true),
      appliesToRolesDetail: ((json['applies_to_roles_detail'] as List?) ?? const [])
          .map((e) => AttendanceRoleRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      shiftStart: _str(json, 'shift_start', fallback: '09:00:00'),
      shiftEnd: _str(json, 'shift_end', fallback: '17:00:00'),
      gracePeriodMinutes: _int(json, 'grace_period_minutes', fallback: 15),
      missingPunchGraceMinutes: _int(json, 'missing_punch_grace_minutes', fallback: 10),
      breakDurationMinutes: _int(json, 'break_duration_minutes', fallback: 30),
      minHoursFullDay: _str(json, 'min_hours_full_day', fallback: '8.00'),
      minHoursHalfDay: _str(json, 'min_hours_half_day', fallback: '4.00'),
      earlyExitGraceMinutes: _int(json, 'early_exit_grace_minutes', fallback: 30),
      otThresholdHours: _str(json, 'ot_threshold_hours', fallback: '9.00'),
      otMultiplierRegular: _str(json, 'ot_multiplier_regular', fallback: '1.50'),
      otMultiplierHoliday: _str(json, 'ot_multiplier_holiday', fallback: '2.00'),
      lateMarksPerLop: _int(json, 'late_marks_per_lop', fallback: 3),
      lopDeductionUnit: _str(json, 'lop_deduction_unit', fallback: 'full_day'),
      weeklyOffMon: _bool(json, 'weekly_off_mon'),
      weeklyOffTue: _bool(json, 'weekly_off_tue'),
      weeklyOffWed: _bool(json, 'weekly_off_wed'),
      weeklyOffThu: _bool(json, 'weekly_off_thu'),
      weeklyOffFri: _bool(json, 'weekly_off_fri'),
      weeklyOffSat: _bool(json, 'weekly_off_sat', fallback: true),
      weeklyOffSun: _bool(json, 'weekly_off_sun', fallback: true),
      absenceAlertEnabled: _bool(json, 'absence_alert_enabled'),
      absenceAlertAfterDays: _int(json, 'absence_alert_after_days', fallback: 3),
      absenceAlertNotifyWhom: _str(json, 'absence_alert_notify_whom', fallback: 'manager_and_hr'),
      createdByName: json['created_by_name'] as String?,
      updatedByName: json['updated_by_name'] as String?,
      updatedAt: json['updated_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  /// Used only to locally flip `isDefault` on the sibling policies after a
  /// `make_default` call, so their badge updates immediately without a full
  /// reload.
  AttendancePolicyEntity copyWithDefault(bool isDefault) {
    return AttendancePolicyEntity(
      id: id,
      name: name,
      isDefault: isDefault,
      isActive: isActive,
      appliesToRolesDetail: appliesToRolesDetail,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      gracePeriodMinutes: gracePeriodMinutes,
      missingPunchGraceMinutes: missingPunchGraceMinutes,
      breakDurationMinutes: breakDurationMinutes,
      minHoursFullDay: minHoursFullDay,
      minHoursHalfDay: minHoursHalfDay,
      earlyExitGraceMinutes: earlyExitGraceMinutes,
      otThresholdHours: otThresholdHours,
      otMultiplierRegular: otMultiplierRegular,
      otMultiplierHoliday: otMultiplierHoliday,
      lateMarksPerLop: lateMarksPerLop,
      lopDeductionUnit: lopDeductionUnit,
      weeklyOffMon: weeklyOffMon,
      weeklyOffTue: weeklyOffTue,
      weeklyOffWed: weeklyOffWed,
      weeklyOffThu: weeklyOffThu,
      weeklyOffFri: weeklyOffFri,
      weeklyOffSat: weeklyOffSat,
      weeklyOffSun: weeklyOffSun,
      absenceAlertEnabled: absenceAlertEnabled,
      absenceAlertAfterDays: absenceAlertAfterDays,
      absenceAlertNotifyWhom: absenceAlertNotifyWhom,
      createdByName: createdByName,
      updatedByName: updatedByName,
      updatedAt: updatedAt,
      createdAt: createdAt,
    );
  }

  /// Seeds the wizard's editable `draft` on edit — mirrors the web's
  /// `startEdit`, which truncates `shift_start`/`shift_end` to `HH:MM` (an
  /// `<input type="time">` value) and reduces `applies_to_roles_detail`
  /// back down to a plain list of role ids for the write field.
  Map<String, dynamic> toFormMap() {
    return {
      'name': name,
      'is_active': isActive,
      'applies_to_roles': appliesToRolesDetail.map((r) => r.id).toList(),
      'shift_start': shiftStart.length >= 5 ? shiftStart.substring(0, 5) : shiftStart,
      'shift_end': shiftEnd.length >= 5 ? shiftEnd.substring(0, 5) : shiftEnd,
      'grace_period_minutes': gracePeriodMinutes,
      'missing_punch_grace_minutes': missingPunchGraceMinutes,
      'break_duration_minutes': breakDurationMinutes,
      'min_hours_full_day': minHoursFullDay,
      'min_hours_half_day': minHoursHalfDay,
      'early_exit_grace_minutes': earlyExitGraceMinutes,
      'ot_threshold_hours': otThresholdHours,
      'ot_multiplier_regular': otMultiplierRegular,
      'ot_multiplier_holiday': otMultiplierHoliday,
      'late_marks_per_lop': lateMarksPerLop,
      'lop_deduction_unit': lopDeductionUnit,
      'weekly_off_mon': weeklyOffMon,
      'weekly_off_tue': weeklyOffTue,
      'weekly_off_wed': weeklyOffWed,
      'weekly_off_thu': weeklyOffThu,
      'weekly_off_fri': weeklyOffFri,
      'weekly_off_sat': weeklyOffSat,
      'weekly_off_sun': weeklyOffSun,
      'absence_alert_enabled': absenceAlertEnabled,
      'absence_alert_after_days': absenceAlertAfterDays,
      'absence_alert_notify_whom': absenceAlertNotifyWhom,
    };
  }
}

/// One `SettingsAuditLog` row for an attendance policy — mirrors the web's
/// `interface AuditEntry` (id, actor_name, action, created_at only; kept
/// separate from Leave Policy's/SMTP's own copies per the established
/// per-feature self-contained convention).
class AttendanceAuditEntry {
  final int id;
  final String actorName;
  final String action;
  final DateTime? createdAt;

  const AttendanceAuditEntry({
    required this.id,
    required this.actorName,
    required this.action,
    required this.createdAt,
  });

  factory AttendanceAuditEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceAuditEntry(
      id: json['id'] as int,
      actorName: json['actor_name'] as String? ?? 'System',
      action: json['action'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
