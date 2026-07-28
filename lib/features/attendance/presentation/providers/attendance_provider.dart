import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_entities.dart';
import '../../domain/repositories/attendance_repository.dart';

/// ========================================================================
/// DEPENDENCY INJECTION — real backend
/// ========================================================================
final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>((ref) {
  return AttendanceRemoteDataSource(ref.watch(dioClientProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(ref.watch(attendanceRemoteDataSourceProvider));
});

/// ========================================================================
/// Student Attendance — wired to the real `AttendanceRepository`
/// (`/api/v1/attendance/student-attendance/...`, `/api/v1/core/classes/`).
/// ========================================================================

final attendanceReloadProvider = StateProvider<int>((ref) => 0);

final selectedDateProvider = StateProvider<String>((ref) => _todayIso());

/// Fixed literal default matching web's `useCurrentAcademicYear('2026-27')`
/// fallback argument (the exact string passed in the historical source).
/// Disclosed, real web limitation carried over faithfully: the header's
/// Academic Year dropdown is never actually wired into any data-fetching
/// call in the real web source either (confirmed directly) — it's
/// decorative there too, not a Flutter-side omission.
final academicYearProvider = StateProvider<String>((ref) => '2026-27');

final levelFilterProvider = StateProvider<LevelFilter>((ref) => 'all');
final attendanceSearchQueryProvider = StateProvider<String>((ref) => '');
final attendanceStatusFilterProvider = StateProvider<String>((ref) => 'all');
final attendanceSectionFilterProvider = StateProvider<String>((ref) => 'all');

/// Which class accordions are open — web only ever keeps one open at a time
/// (`handleToggleClass` always replaces the set with a single id, or empties
/// it), so this mirrors that single-open behavior even though it's typed as
/// a Set for parity with the original prop shape.
final openClassesProvider = StateProvider<Set<int>>((ref) => {});

/// Active section tab per open class: classId -> sectionId.
final activeSectionsProvider = StateProvider<Map<int, int>>((ref) => {});

/// Selected row ids per section: "classId-sectionId" -> student ids.
final selectedRowsProvider = StateProvider<Map<String, Set<int>>>((ref) => {});

final isEditUnlockedProvider = StateProvider<bool>((ref) => false);

/// Classes + nested sections, from `/api/v1/core/classes/`, enriched with
/// each class's live present/absent/late/overall% from
/// `/student-attendance/class-summary/?date=...` (mirrors web's
/// `useClasses`+`class-summary` merge, `hooks/useClasses.ts:241-244`).
///
/// `ClassViewSet.get_queryset()` returns EVERY school's classes, completely
/// unscoped, for superuser accounts (confirmed directly against the
/// backend: `if user.is_superuser: return qs` — no school filter at all).
/// A superuser therefore genuinely receives multiple real, distinct rows
/// per class name — one per school that has a class with that name (e.g.
/// 3 separate "Nursery" rows for 3 different schools) — not duplicates in
/// any technical sense, but confusing to show merged together in a
/// single-school-oriented UI. Filtering to the current user's own
/// `school_id` here (when the API actually reports one) restores the
/// single-school view a non-superuser account already gets for free from
/// the backend's own scoping.
final classesProvider = FutureProvider.autoDispose<List<ClassInfoEntity>>((ref) async {
  ref.watch(attendanceReloadProvider);
  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(attendanceRepositoryProvider);
  final currentSchoolId = ref.watch(authNotifierProvider).maybeWhen(authenticated: (u) => u.schoolId, orElse: () => null);
  final classes = await repository.getClasses();
  final scoped = currentSchoolId == null ? classes : classes.where((c) => c.schoolId == null || c.schoolId == currentSchoolId).toList();
  List<ClassSummaryTileEntity> tiles;
  try {
    tiles = await repository.getClassSummary(date);
  } catch (_) {
    tiles = const [];
  }
  final byId = {for (final t in tiles) t.classId: t};
  return scoped.map((c) {
    final t = byId[c.id];
    if (t == null) return c;
    return c.copyWith(totalPresent: t.present, totalSignedIn: t.signedIn, totalAbsent: t.absent, totalLate: t.late, overallPct: t.pct.round());
  }).toList();
});

/// Daily KPI summary — `/student-attendance/daily-summary/?date=...`.
final dailySummaryProvider = FutureProvider.autoDispose<KpiDataEntity>((ref) {
  ref.watch(attendanceReloadProvider);
  final date = ref.watch(selectedDateProvider);
  return ref.watch(attendanceRepositoryProvider).getDailySummary(date);
});

class AttendanceStudentsState {
  final Map<String, List<AttendanceStudentEntity>> students;
  final Map<String, bool> loading;
  const AttendanceStudentsState({this.students = const {}, this.loading = const {}});
}

class AttendanceStudentsNotifier extends StateNotifier<AttendanceStudentsState> {
  final Ref _ref;
  AttendanceStudentsNotifier(this._ref) : super(const AttendanceStudentsState());

  AttendanceRepository get _repo => _ref.read(attendanceRepositoryProvider);

  Future<void> loadSection(int classId, int sectionId) async {
    final key = '$classId-$sectionId';
    state = AttendanceStudentsState(students: state.students, loading: {...state.loading, key: true});
    final date = _ref.read(selectedDateProvider);
    try {
      final list = await _repo.searchStudents(classId: classId, sectionId: sectionId, date: date);
      state = AttendanceStudentsState(students: {...state.students, key: list}, loading: {...state.loading, key: false});
    } catch (_) {
      state = AttendanceStudentsState(students: state.students, loading: {...state.loading, key: false});
      rethrow;
    }
  }

  /// Applies [updated] optimistically, then persists that single student's
  /// full current mark via `store/`. Throws on failure (caller shows the
  /// real error) — the optimistic update is left in place either way,
  /// matching web's own optimistic-update-then-fire pattern (it doesn't
  /// roll back on failure either, it just surfaces a toast).
  Future<void> updateStudent(int classId, int sectionId, AttendanceStudentEntity updated) async {
    final key = '$classId-$sectionId';
    final list = List<AttendanceStudentEntity>.of(state.students[key] ?? []);
    final idx = list.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;
    list[idx] = updated;
    state = AttendanceStudentsState(students: {...state.students, key: list}, loading: state.loading);
    await _persistOne(classId, sectionId, updated);
  }

  Future<void> _persistOne(int classId, int sectionId, AttendanceStudentEntity s) async {
    final date = _ref.read(selectedDateProvider);
    await _repo.storeAttendance(
      date: date,
      classId: classId,
      sectionId: sectionId,
      ids: [s.id],
      attendance: {s.id: attendanceTypeForStatus(s.status)},
      note: {s.id: s.absentReason ?? ''},
      arrivalTime: {s.id: s.arrivalTime ?? ''},
      signInTime: {s.id: s.signInTime ?? ''},
      signOutTime: {s.id: s.signOutTime ?? ''},
      pickupTime: {s.id: s.pickupTime ?? ''},
      pickupBy: {s.id: s.pickupBy ?? ''},
      lunch: {s.id: s.lunch},
    );
  }

  /// Persists every currently-loaded student of [classId]/[sectionId] in
  /// one `store/` call — used by bulk-mark/save/mark-all-present flows.
  Future<void> persistSection(int classId, int sectionId, List<AttendanceStudentEntity> students) async {
    if (students.isEmpty) return;
    final date = _ref.read(selectedDateProvider);
    await _repo.storeAttendance(
      date: date,
      classId: classId,
      sectionId: sectionId,
      ids: students.map((s) => s.id).toList(),
      attendance: {for (final s in students) s.id: attendanceTypeForStatus(s.status)},
      note: {for (final s in students) s.id: s.absentReason ?? ''},
      arrivalTime: {for (final s in students) s.id: s.arrivalTime ?? ''},
      signInTime: {for (final s in students) s.id: s.signInTime ?? ''},
      signOutTime: {for (final s in students) s.id: s.signOutTime ?? ''},
      pickupTime: {for (final s in students) s.id: s.pickupTime ?? ''},
      pickupBy: {for (final s in students) s.id: s.pickupBy ?? ''},
      lunch: {for (final s in students) s.id: s.lunch},
    );
  }

  void replaceSection(int classId, int sectionId, List<AttendanceStudentEntity> students) {
    final key = '$classId-$sectionId';
    state = AttendanceStudentsState(students: {...state.students, key: students}, loading: state.loading);
  }

  void clear() {
    state = const AttendanceStudentsState();
  }
}

final attendanceStudentsProvider = StateNotifierProvider<AttendanceStudentsNotifier, AttendanceStudentsState>((ref) {
  return AttendanceStudentsNotifier(ref);
});

String _todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
