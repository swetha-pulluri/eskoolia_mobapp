import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../data/local/shared_prefs.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart' show sharedPrefsProvider;
import '../../data/datasources/parent_remote_datasource.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/entities/attendance_calendar_entity.dart';
import '../../domain/entities/child_detail_entity.dart';
import '../../domain/entities/child_fees_entity.dart';
import '../../domain/entities/notice_item_entity.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../../domain/repositories/parent_repository.dart';

final parentRemoteDataSourceProvider = Provider<ParentRemoteDataSource>((ref) {
  return ParentRemoteDataSource(ref.watch(dioClientProvider));
});

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepositoryImpl(ref.watch(parentRemoteDataSourceProvider));
});

/// The guardian's profile + lightweight children list — `/api/v1/parent/me/`.
final parentMeProvider = FutureProvider.autoDispose<ParentMeEntity>((ref) {
  return ref.watch(parentRepositoryProvider).getMe();
});

/// Which child the ChildSwitcher currently has selected, persisted via
/// [StorageKeys.parentSelectedChildId] — mirrors web's `ParentChildContext`
/// localStorage-backed `parent_selected_child_id`. Holds only the *chosen*
/// id; [selectedChildProvider] below resolves it against the real children
/// list and falls back to the first child, same as web does.
class SelectedChildIdNotifier extends StateNotifier<int?> {
  final SharedPrefs _prefs;

  SelectedChildIdNotifier(this._prefs) : super(_prefs.getInt(StorageKeys.parentSelectedChildId));

  void select(int id) {
    state = id;
    _prefs.setInt(StorageKeys.parentSelectedChildId, id);
  }
}

final selectedChildIdProvider = StateNotifierProvider.autoDispose<SelectedChildIdNotifier, int?>((ref) {
  return SelectedChildIdNotifier(ref.watch(sharedPrefsProvider));
});

/// The child currently shown across the Home screen's widgets — the stored
/// id if it still matches one of the guardian's children, else the first
/// child, else null (no children enrolled).
final selectedChildProvider = Provider.autoDispose<ChildSummaryEntity?>((ref) {
  final me = ref.watch(parentMeProvider).valueOrNull;
  if (me == null || me.children.isEmpty) return null;

  final storedId = ref.watch(selectedChildIdProvider);
  final stored = storedId != null ? me.children.where((c) => c.id == storedId).firstOrNull : null;
  return stored ?? me.children.first;
});

/// One child's attendance/marks/behaviour summary — `/api/v1/parent/children/<id>/`.
/// Powers the Attendance and Recent Results widgets.
final childDetailProvider = FutureProvider.autoDispose<ChildDetailEntity?>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return null;
  return ref.watch(parentRepositoryProvider).getChildDetail(child.id);
});

/// One child's fee assignments — `/api/v1/parent/fees/?child_id=`. Powers
/// the Fee Status widget.
final childFeesProvider = FutureProvider.autoDispose<ChildFeesEntity?>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return null;
  return ref.watch(parentRepositoryProvider).getChildFees(child.id);
});

/// Published school notices — `/api/v1/parent/notices/`. Powers the Notice
/// Board widget. Not child-scoped (whole-school), unlike the two above.
final parentNoticesProvider = FutureProvider.autoDispose<List<NoticeItemEntity>>((ref) {
  return ref.watch(parentRepositoryProvider).getNotices();
});

/// The Attendance Calendar's currently viewed month — in-memory only, same
/// as web's own `useState` (no localStorage persistence for the selected
/// month there either; always starts on the current month per session).
class SelectedMonthNotifier extends StateNotifier<({int year, int month})> {
  SelectedMonthNotifier() : super((year: DateTime.now().year, month: DateTime.now().month));

  void previous() {
    final s = state;
    state = s.month == 1 ? (year: s.year - 1, month: 12) : (year: s.year, month: s.month - 1);
  }

  void next() {
    final s = state;
    state = s.month == 12 ? (year: s.year + 1, month: 1) : (year: s.year, month: s.month + 1);
  }
}

final selectedMonthProvider = StateNotifierProvider.autoDispose<SelectedMonthNotifier, ({int year, int month})>((ref) {
  return SelectedMonthNotifier();
});

/// One child's attendance calendar for the currently selected month —
/// `/api/v1/parent/attendance/?child_id=&month=YYYY-MM`. Powers the
/// Attendance Calendar page.
final attendanceCalendarProvider = FutureProvider.autoDispose<AttendanceCalendarEntity?>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return null;
  final month = ref.watch(selectedMonthProvider);
  final monthStr = '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
  return ref.watch(parentRepositoryProvider).getAttendanceCalendar(child.id, monthStr);
});
