import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administration/presentation/providers/administration_list_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/holiday_calendar_remote_datasource.dart';
import '../../data/repositories/holiday_calendar_repository_impl.dart';
import '../../domain/entities/holiday_entity.dart';
import '../../domain/repositories/holiday_calendar_repository.dart';
import 'holiday_calendar_state.dart';

final holidayCalendarRemoteDataSourceProvider = Provider<HolidayCalendarRemoteDataSource>((ref) {
  return HolidayCalendarRemoteDataSource(ref.watch(dioClientProvider));
});

final holidayCalendarRepositoryProvider = Provider<HolidayCalendarRepository>((ref) {
  return HolidayCalendarRepositoryImpl(ref.watch(holidayCalendarRemoteDataSourceProvider));
});

final holidayCalendarNotifierProvider =
    StateNotifierProvider.autoDispose<HolidayCalendarNotifier, HolidayCalendarState>((ref) {
  return HolidayCalendarNotifier(ref.watch(holidayCalendarRepositoryProvider));
});

/// A 1:1 port of every function in `HolidaysPanel.tsx`.
class HolidayCalendarNotifier extends StateNotifier<HolidayCalendarState> {
  final HolidayCalendarRepository _repository;

  HolidayCalendarNotifier(this._repository) : super(const HolidayCalendarState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final calendarFuture = _repository.getStaffCalendar();
      final allHolidaysFuture = _repository.getAllHolidays();
      final exclusionsFuture = _repository.getExclusions();
      final calendar = await calendarFuture;
      final allHolidays = await allHolidaysFuture;
      final exclusions = await exclusionsFuture;
      state = state.copyWith(
        loading: false,
        staffCalendar: calendar,
        schoolWideHolidays: allHolidays.where((h) => h.audience == 'all').toList(),
        staffOnlyHolidays: allHolidays.where((h) => h.audience == 'staff_only').toList(),
        exclusions: exclusions,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }

  HolidayExclusionEntity? _exclusionForHoliday(int holidayId) {
    for (final exclusion in state.exclusions) {
      if (exclusion.holidayId == holidayId) return exclusion;
    }
    return null;
  }

  bool isExcluded(int holidayId) => _exclusionForHoliday(holidayId) != null;

  Future<void> toggleExclusion(HolidayEntity holiday) async {
    state = state.copyWith(busyId: holiday.id, error: null);
    try {
      final existing = _exclusionForHoliday(holiday.id);
      if (existing != null) {
        await _repository.deleteExclusion(existing.id);
      } else {
        await _repository.createExclusion(holiday.id);
      }
      await load();
    } catch (e) {
      state = state.copyWith(error: adminErrorMessage(e));
    } finally {
      state = state.copyWith(busyId: null);
    }
  }

  void startCreate() {
    state = state.copyWith(editingId: null, draft: buildHolidayWizardDefaults(), step: 0, wizardOpen: true);
  }

  void startEdit(HolidayEntity holiday) {
    state = state.copyWith(
      editingId: holiday.id,
      draft: {
        'name': holiday.name,
        'date': holiday.date,
        'end_date': holiday.endDate ?? '',
        'is_optional': holiday.isOptional,
      },
      step: 0,
      wizardOpen: true,
    );
  }

  void closeWizard() {
    state = state.copyWith(wizardOpen: false, editingId: null);
  }

  void setStep(int step) => state = state.copyWith(step: step);

  void setDraftField(String key, dynamic value) {
    state = state.copyWith(draft: {...state.draft, key: value});
  }

  Future<void> submit() async {
    final name = ((state.draft['name'] as String?) ?? '').trim();
    final date = (state.draft['date'] as String?) ?? '';
    final endDate = (state.draft['end_date'] as String?) ?? '';
    if (name.isEmpty || date.isEmpty) {
      state = state.copyWith(error: 'Name and date are required.');
      throw Exception('Name and date are required.');
    }
    if (endDate.isNotEmpty && endDate.compareTo(date) < 0) {
      state = state.copyWith(error: 'End date cannot be before the start date.');
      throw Exception('End date cannot be before the start date.');
    }

    state = state.copyWith(saving: true, error: null, success: null);
    try {
      final editingId = state.editingId;
      if (editingId != null) {
        final updated = await _repository.updateHoliday(editingId, {
          'name': name,
          'date': date,
          'end_date': endDate.isEmpty ? null : endDate,
          'is_optional': state.draft['is_optional'] ?? false,
        });
        state = state.copyWith(
          saving: false,
          staffOnlyHolidays: [for (final h in state.staffOnlyHolidays) if (h.id == editingId) updated else h],
          success: 'Holiday updated.',
          wizardOpen: false,
          editingId: null,
        );
      } else {
        await _repository.createHoliday({
          'name': name,
          'date': date,
          'end_date': endDate.isEmpty ? null : endDate,
          'audience': 'staff_only',
          'holiday_type': 'other',
          'is_optional': state.draft['is_optional'] ?? false,
        });
        state = state.copyWith(saving: false, success: 'Staff-only holiday added.', wizardOpen: false, editingId: null);
      }
      await load();
    } catch (e) {
      state = state.copyWith(saving: false, error: adminErrorMessage(e));
      rethrow;
    }
  }

  Future<void> delete(HolidayEntity holiday) async {
    state = state.copyWith(busyId: holiday.id, error: null);
    try {
      await _repository.deleteHoliday(holiday.id);
      await load();
    } catch (e) {
      state = state.copyWith(error: adminErrorMessage(e));
    } finally {
      state = state.copyWith(busyId: null);
    }
  }
}
