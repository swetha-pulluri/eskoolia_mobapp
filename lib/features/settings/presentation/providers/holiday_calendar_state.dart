import '../../domain/entities/holiday_entity.dart';

const Object _unset = Object();

/// Combines every `useState` hook from `HolidaysPanel.tsx` into one
/// immutable state object for a single `StateNotifier`.
class HolidayCalendarState {
  final List<HolidayEntity> staffCalendar;
  final List<HolidayEntity> schoolWideHolidays;
  final List<HolidayEntity> staffOnlyHolidays;
  final List<HolidayExclusionEntity> exclusions;
  final bool loading;
  final String? error;
  final String? success;
  final int? busyId;

  final bool wizardOpen;
  final int step;
  final int? editingId;
  final Map<String, dynamic> draft;
  final bool saving;

  const HolidayCalendarState({
    this.staffCalendar = const [],
    this.schoolWideHolidays = const [],
    this.staffOnlyHolidays = const [],
    this.exclusions = const [],
    this.loading = true,
    this.error,
    this.success,
    this.busyId,
    this.wizardOpen = false,
    this.step = 0,
    this.editingId,
    this.draft = const {},
    this.saving = false,
  });

  bool get isEditing => editingId != null;

  HolidayCalendarState copyWith({
    List<HolidayEntity>? staffCalendar,
    List<HolidayEntity>? schoolWideHolidays,
    List<HolidayEntity>? staffOnlyHolidays,
    List<HolidayExclusionEntity>? exclusions,
    bool? loading,
    Object? error = _unset,
    Object? success = _unset,
    Object? busyId = _unset,
    bool? wizardOpen,
    int? step,
    Object? editingId = _unset,
    Map<String, dynamic>? draft,
    bool? saving,
  }) {
    return HolidayCalendarState(
      staffCalendar: staffCalendar ?? this.staffCalendar,
      schoolWideHolidays: schoolWideHolidays ?? this.schoolWideHolidays,
      staffOnlyHolidays: staffOnlyHolidays ?? this.staffOnlyHolidays,
      exclusions: exclusions ?? this.exclusions,
      loading: loading ?? this.loading,
      error: error == _unset ? this.error : error as String?,
      success: success == _unset ? this.success : success as String?,
      busyId: busyId == _unset ? this.busyId : busyId as int?,
      wizardOpen: wizardOpen ?? this.wizardOpen,
      step: step ?? this.step,
      editingId: editingId == _unset ? this.editingId : editingId as int?,
      draft: draft ?? this.draft,
      saving: saving ?? this.saving,
    );
  }
}

Map<String, dynamic> buildHolidayWizardDefaults() => {
      'name': '',
      'date': '',
      'end_date': '',
      'is_optional': false,
    };
