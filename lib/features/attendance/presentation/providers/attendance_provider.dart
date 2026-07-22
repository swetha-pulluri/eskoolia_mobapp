import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/attendance_entities.dart';
import 'attendance_local_data.dart';

/// ========================================================================
/// UI-ONLY PROVIDERS — Attendance module (no backend calls; see
/// `attendance_local_data.dart` for the architectural rationale).
/// ========================================================================

final attendanceReloadProvider = StateProvider<int>((ref) => 0);

final selectedDateProvider = StateProvider<String>((ref) => _todayIso());

/// Fixed literal default matching web's `useCurrentAcademicYear('2026-27')`
/// fallback argument (the exact string passed in the historical source).
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

final classesProvider = FutureProvider.autoDispose<List<ClassInfoEntity>>((ref) {
  ref.watch(attendanceReloadProvider);
  return AttendanceLocalData.getClasses();
});

class AttendanceStudentsState {
  final Map<String, List<AttendanceStudentEntity>> students;
  final Map<String, bool> loading;
  const AttendanceStudentsState({this.students = const {}, this.loading = const {}});
}

class AttendanceStudentsNotifier extends StateNotifier<AttendanceStudentsState> {
  AttendanceStudentsNotifier() : super(const AttendanceStudentsState());

  Future<void> loadSection(int classId, int sectionId) async {
    final key = '$classId-$sectionId';
    state = AttendanceStudentsState(students: state.students, loading: {...state.loading, key: true});
    final list = await AttendanceLocalData.getStudents(classId, sectionId);
    state = AttendanceStudentsState(students: {...state.students, key: list}, loading: {...state.loading, key: false});
  }

  void updateStudent(int classId, int sectionId, AttendanceStudentEntity updated) {
    final key = '$classId-$sectionId';
    final list = List<AttendanceStudentEntity>.of(state.students[key] ?? []);
    final idx = list.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;
    list[idx] = updated;
    state = AttendanceStudentsState(students: {...state.students, key: list}, loading: state.loading);
    AttendanceLocalData.setStudents(classId, sectionId, list);
  }

  void replaceSection(int classId, int sectionId, List<AttendanceStudentEntity> students) {
    final key = '$classId-$sectionId';
    state = AttendanceStudentsState(students: {...state.students, key: students}, loading: state.loading);
    AttendanceLocalData.setStudents(classId, sectionId, students);
  }

  void clear() {
    state = const AttendanceStudentsState();
  }
}

final attendanceStudentsProvider = StateNotifierProvider<AttendanceStudentsNotifier, AttendanceStudentsState>((ref) {
  return AttendanceStudentsNotifier();
});

String _todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
