import '../../../roles/domain/models/role_data.dart';
import '../../domain/entities/attendance_policy_entity.dart';

const Object _unset = Object();

/// Combines every `useState` hook from `AttendanceRulesPanel.tsx` (list +
/// roles + wizard + history) into one immutable state object for a single
/// `StateNotifier` — same pattern as Leave Policy's `LeavePolicyState`.
class AttendanceRulesState {
  final List<AttendancePolicyEntity> policies;
  final List<RoleData> roles;
  final bool loading;
  final String? error;
  final String? success;
  final int? busyId;

  final bool wizardOpen;
  final int step;
  final int? editingId;
  final Map<String, dynamic> draft;
  final bool saving;

  final int? historyOpenId;
  final List<AttendanceAuditEntry> history;
  final bool historyLoading;

  const AttendanceRulesState({
    this.policies = const [],
    this.roles = const [],
    this.loading = true,
    this.error,
    this.success,
    this.busyId,
    this.wizardOpen = false,
    this.step = 0,
    this.editingId,
    this.draft = const {},
    this.saving = false,
    this.historyOpenId,
    this.history = const [],
    this.historyLoading = false,
  });

  bool get isEditing => editingId != null;

  AttendanceRulesState copyWith({
    List<AttendancePolicyEntity>? policies,
    List<RoleData>? roles,
    bool? loading,
    Object? error = _unset,
    Object? success = _unset,
    Object? busyId = _unset,
    bool? wizardOpen,
    int? step,
    Object? editingId = _unset,
    Map<String, dynamic>? draft,
    bool? saving,
    Object? historyOpenId = _unset,
    List<AttendanceAuditEntry>? history,
    bool? historyLoading,
  }) {
    return AttendanceRulesState(
      policies: policies ?? this.policies,
      roles: roles ?? this.roles,
      loading: loading ?? this.loading,
      error: error == _unset ? this.error : error as String?,
      success: success == _unset ? this.success : success as String?,
      busyId: busyId == _unset ? this.busyId : busyId as int?,
      wizardOpen: wizardOpen ?? this.wizardOpen,
      step: step ?? this.step,
      editingId: editingId == _unset ? this.editingId : editingId as int?,
      draft: draft ?? this.draft,
      saving: saving ?? this.saving,
      historyOpenId: historyOpenId == _unset ? this.historyOpenId : historyOpenId as int?,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
    );
  }
}

/// Mirrors `WIZARD_DEFAULTS` in `AttendanceRulesPanel.tsx` — values match
/// `SchoolAttendancePolicy`'s own model field defaults exactly.
Map<String, dynamic> buildAttendanceWizardDefaults() {
  return {
    'name': '',
    'is_active': true,
    'applies_to_roles': <int>[],
    'shift_start': '09:00',
    'shift_end': '17:00',
    'grace_period_minutes': 15,
    'missing_punch_grace_minutes': 10,
    'break_duration_minutes': 30,
    'early_exit_grace_minutes': 30,
    'min_hours_full_day': '8.00',
    'min_hours_half_day': '4.00',
    'ot_threshold_hours': '9.00',
    'ot_multiplier_regular': '1.50',
    'ot_multiplier_holiday': '2.00',
    'late_marks_per_lop': 3,
    'lop_deduction_unit': 'full_day',
    'weekly_off_mon': false,
    'weekly_off_tue': false,
    'weekly_off_wed': false,
    'weekly_off_thu': false,
    'weekly_off_fri': false,
    'weekly_off_sat': true,
    'weekly_off_sun': true,
    'absence_alert_enabled': false,
    'absence_alert_after_days': 3,
    'absence_alert_notify_whom': 'manager_and_hr',
  };
}

/// The 7 weekly-off draft keys in Mon→Sun order — used by the wizard's
/// toggle-chip step and the read-only week-strip on each card.
const List<String> attendanceWeeklyOffKeys = [
  'weekly_off_mon',
  'weekly_off_tue',
  'weekly_off_wed',
  'weekly_off_thu',
  'weekly_off_fri',
  'weekly_off_sat',
  'weekly_off_sun',
];
