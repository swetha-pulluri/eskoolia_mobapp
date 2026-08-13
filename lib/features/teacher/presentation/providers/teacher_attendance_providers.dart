import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../attendance/domain/entities/attendance_entities.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/teacher_attendance_remote_datasource.dart';
import '../../data/repositories/teacher_attendance_repository_impl.dart';
import '../../domain/entities/teacher_attendance_entity.dart';
import '../../domain/repositories/teacher_attendance_repository.dart';
import 'teacher_providers.dart';

/// ========================================================================
/// DEPENDENCY INJECTION — real backend (`apps.teacher_portal` attendance
/// endpoints — see `ApiConstants.teacherAttendanceStudents`/`teacherAttendanceStore`).
/// ========================================================================
final teacherAttendanceRemoteDataSourceProvider = Provider<TeacherAttendanceRemoteDataSource>((ref) {
  return TeacherAttendanceRemoteDataSource(ref.watch(dioClientProvider));
});

final teacherAttendanceRepositoryProvider = Provider<TeacherAttendanceRepository>((ref) {
  return TeacherAttendanceRepositoryImpl(ref.watch(teacherAttendanceRemoteDataSourceProvider));
});

/// The class+section options the signed-in teacher can view attendance for —
/// derived from the already-fetched `teacherMeProvider` (no separate API
/// call needed), matching web's `buildAllClasses(me)` in the teacher
/// attendance page: the class-teacher section first (if any), then every
/// subject-assignment section not already included, sorted by class id then
/// section name.
final teacherAttendanceClassOptionsProvider = FutureProvider.autoDispose<List<TeacherClassOptionEntity>>((ref) async {
  final me = await ref.watch(teacherMeProvider.future);
  return buildTeacherAttendanceClassOptions(me);
});

/// Which class+section is currently being viewed. `null` until the page
/// defaults it to the first option once `teacherAttendanceClassOptionsProvider`
/// resolves (mirrors web's `viewClass` state + its "once me loads, default to
/// CT class (or first subject class)" effect).
final teacherAttendanceSelectedClassProvider = StateProvider<TeacherClassOptionEntity?>((ref) => null);

final teacherAttendanceSelectedDateProvider = StateProvider<String>((ref) => todayIsoForTeacherAttendance());

final teacherAttendanceSearchProvider = StateProvider<String>((ref) => '');
final teacherAttendanceStatusFilterProvider = StateProvider<String>((ref) => 'all');

/// Tracked only so the shared `GlobalControls` widget has somewhere to write
/// its section-filter selection — web's own teacher attendance page never
/// actually applies this filter to the roster either (its `filteredStudents`
/// only checks `searchQuery`/`statusFilter`), so this stays unused for
/// filtering here too, matching that exactly rather than "fixing" it.
final teacherAttendanceSectionFilterProvider = StateProvider<String>((ref) => 'all');

final teacherAttendanceSelectedIdsProvider = StateProvider<Set<int>>((ref) => {});

class TeacherAttendanceRosterState {
  final List<AttendanceStudentEntity> students;
  final bool loading;
  final bool isLocked;
  final bool canEdit;
  final String? holidayName;
  final bool saving;
  final String? saveError;

  const TeacherAttendanceRosterState({
    this.students = const [],
    this.loading = false,
    this.isLocked = false,
    this.canEdit = false,
    this.holidayName,
    this.saving = false,
    this.saveError,
  });

  TeacherAttendanceRosterState copyWith({
    List<AttendanceStudentEntity>? students,
    bool? loading,
    bool? isLocked,
    bool? canEdit,
    bool? saving,
    Object? saveError = _sentinel,
  }) {
    return TeacherAttendanceRosterState(
      students: students ?? this.students,
      loading: loading ?? this.loading,
      isLocked: isLocked ?? this.isLocked,
      canEdit: canEdit ?? this.canEdit,
      holidayName: holidayName,
      saving: saving ?? this.saving,
      saveError: identical(saveError, _sentinel) ? this.saveError : saveError as String?,
    );
  }
}

const _sentinel = Object();

/// Drives the single currently-viewed class+section's roster: load, local
/// optimistic mutation, and a debounced (800ms) auto-save of every currently
/// "marked" (non-unmarked) student. Direct port of web's `loadStudents`/
/// `updateStudent`/`autoSave`/`scheduleAutoSave` in
/// `app/(teacher-portal)/teacher/attendance/page.tsx`.
///
/// Unlike the admin Student Attendance module (Module 6 — explicit
/// "Save Attendance" button, per-student or per-section immediate persist),
/// the teacher page has NO save button at all: every local edit is queued
/// and auto-saved after the debounce window, matching web exactly. Only the
/// class teacher of a section (`canEdit == true`, from the fetch response)
/// can trigger an auto-save; a subject teacher merely viewing the roster
/// never fires a write.
class TeacherAttendanceNotifier extends StateNotifier<TeacherAttendanceRosterState> {
  final Ref _ref;
  Timer? _saveTimer;

  TeacherAttendanceNotifier(this._ref) : super(const TeacherAttendanceRosterState());

  TeacherAttendanceRepository get _repo => _ref.read(teacherAttendanceRepositoryProvider);

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  /// Mirrors web's early return for a future date: the roster is cleared
  /// locally and the fetch is never attempted (the backend would 400 it
  /// anyway — see `TeacherAttendanceFetchView`'s own future-date guard).
  Future<void> loadStudents(int classId, int sectionId, String date) async {
    if (date.compareTo(todayIsoForTeacherAttendance()) > 0) {
      state = const TeacherAttendanceRosterState();
      _ref.read(teacherAttendanceSelectedIdsProvider.notifier).state = {};
      return;
    }
    state = state.copyWith(loading: true, saveError: null);
    try {
      final roster = await _repo.getStudents(classId: classId, sectionId: sectionId, date: date);
      state = TeacherAttendanceRosterState(
        students: roster.students,
        loading: false,
        isLocked: roster.isLocked,
        canEdit: roster.canEdit,
        holidayName: roster.isHoliday ? (roster.holidayName ?? 'Holiday') : null,
      );
      _ref.read(teacherAttendanceSelectedIdsProvider.notifier).state = {};
    } catch (e) {
      state = state.copyWith(loading: false, saveError: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Applies [updated] optimistically, then schedules a debounced auto-save
  /// of every currently-marked student — matches web's `updateStudent`.
  void updateOne(AttendanceStudentEntity updated, String date) {
    final next = [for (final s in state.students) s.id == updated.id ? updated : s];
    state = state.copyWith(students: next);
    _scheduleAutoSave(date);
  }

  /// Applies [mapper] to every student whose id is in [ids] before a single
  /// debounced auto-save fires — backs "mark all visible" and the bulk
  /// action bar, matching web's `handleMarkAllVisible`/`handleBulkMark`/
  /// `handleBulkSignIn` (each mutates the whole list once, then schedules
  /// one auto-save, rather than one per student).
  void updateMany(Set<int> ids, AttendanceStudentEntity Function(AttendanceStudentEntity) mapper, String date) {
    if (ids.isEmpty) return;
    final next = [for (final s in state.students) ids.contains(s.id) ? mapper(s) : s];
    state = state.copyWith(students: next);
    _scheduleAutoSave(date);
  }

  void _scheduleAutoSave(String date) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () => _autoSave(date));
  }

  /// Sends every currently-marked (non-"unmarked") student in the loaded
  /// roster in one `store/` call — not just the student that last changed —
  /// matching web's `autoSave(currentStudents, date)`, which always
  /// resubmits the full marked set on every debounce tick.
  Future<void> _autoSave(String date) async {
    final viewClass = _ref.read(teacherAttendanceSelectedClassProvider);
    if (viewClass == null || !state.canEdit) return;
    if (date != todayIsoForTeacherAttendance()) return;
    final marked = state.students.where((s) => s.status != 'unmarked').toList();
    if (marked.isEmpty) return;

    state = state.copyWith(saving: true, saveError: null);
    try {
      final attendance = <int, String>{};
      final note = <int, String>{};
      final lunch = <int, bool>{};
      final arrivalTime = <int, String>{};
      final signInTime = <int, String>{};
      final signOutTime = <int, String>{};

      for (final s in marked) {
        attendance[s.id] = attendanceTypeForStatus(s.status);
        if (s.absentReason != null && s.absentReason!.isNotEmpty) note[s.id] = s.absentReason!;
        lunch[s.id] = s.lunch;
        if (s.arrivalTime != null && s.arrivalTime!.isNotEmpty) arrivalTime[s.id] = s.arrivalTime!;
        if (s.signInTime != null && s.signInTime!.isNotEmpty) signInTime[s.id] = s.signInTime!;
        if (s.signOutTime != null && s.signOutTime!.isNotEmpty) signOutTime[s.id] = s.signOutTime!;
      }

      await _repo.storeAttendance(
        classId: viewClass.classId,
        sectionId: viewClass.sectionId,
        date: date,
        ids: marked.map((s) => s.id).toList(),
        attendance: attendance,
        note: note,
        lunch: lunch,
        arrivalTime: arrivalTime,
        signInTime: signInTime,
        signOutTime: signOutTime,
        lockAttendance: false,
      );
      state = state.copyWith(saving: false);
    } catch (e) {
      state = state.copyWith(saving: false, saveError: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void clear() {
    _saveTimer?.cancel();
    state = const TeacherAttendanceRosterState();
  }
}

final teacherAttendanceRosterProvider =
    StateNotifierProvider<TeacherAttendanceNotifier, TeacherAttendanceRosterState>((ref) {
  return TeacherAttendanceNotifier(ref);
});

String todayIsoForTeacherAttendance() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
