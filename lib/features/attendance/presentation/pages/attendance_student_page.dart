import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/attendance_entities.dart';
import '../providers/attendance_local_data.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_layout.dart';
import '../widgets/attendance_page_header.dart';
import '../widgets/attendance_alert.dart';
import '../widgets/attendance_kpis.dart';
import '../widgets/attendance_filter_bar.dart';
import '../widgets/global_controls.dart';
import '../widgets/class_accordion_grid.dart';
import '../widgets/monthly_report.dart';
import '../widgets/dialogs/absent_note_dialog.dart';
import '../widgets/dialogs/late_comer_dialog.dart';
import '../widgets/dialogs/notes_modal.dart';
import '../widgets/dialogs/view_notes_modal.dart';
import '../widgets/dialogs/unlock_edit_dialog.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/export_options_dialog.dart';
import '../widgets/dialogs/student_attendance_import_dialog.dart';

int? _timeToMins(String? t) {
  if (t == null) return null;
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t);
  if (m == null) return null;
  return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

String _nowHHMM() {
  final n = DateTime.now();
  return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
}

/// Student Attendance — converted from the real (git-preserved)
/// `StudentAttendancePage` implementation. See the module doc comments in
/// `attendance_local_data.dart` for the "no backend, local state only"
/// architecture notes.
class AttendanceStudentPage extends ConsumerStatefulWidget {
  const AttendanceStudentPage({super.key});

  @override
  ConsumerState<AttendanceStudentPage> createState() => _AttendanceStudentPageState();
}

class _AttendanceStudentPageState extends ConsumerState<AttendanceStudentPage> {
  late final String _today = _todayIso();
  bool _importDialogOpen = false;

  ({int classId, int sectionId, AttendanceStudentEntity student, String mode})? _absentDialogState;
  ({int classId, int sectionId, AttendanceStudentEntity student, String signInTime, int minutesLate})? _lateDialogState;
  ({int classId, int sectionId, AttendanceStudentEntity student, String mode})? _notesDialogState;
  bool _showUnlockDialog = false;

  static String _todayIso() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _reloadClasses() => ref.read(attendanceReloadProvider.notifier).state++;

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? const Color(0xFFC2264E) : const Color(0xFF0B0B14)));
  }

  String get _selectedDate => ref.watch(selectedDateProvider);
  String get _dateMode {
    final d = _selectedDate;
    if (d == _today) return 'today';
    if (d.compareTo(_today) < 0) return 'past';
    return 'future';
  }

  bool get _isSundaySelected => DateTime.parse('${_selectedDate}T00:00:00').weekday == DateTime.sunday;

  bool get _isReadOnly {
    final mode = _dateMode;
    final unlocked = ref.watch(isEditUnlockedProvider);
    if (mode == 'future') return true;
    if (_isSundaySelected && !unlocked) return true;
    if (mode == 'past' && !unlocked) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider).maybeWhen(data: (v) => v, orElse: () => const <ClassInfoEntity>[]);
    final studentsState = ref.watch(attendanceStudentsProvider);
    final selectedDate = _selectedDate;
    final academicYear = ref.watch(academicYearProvider);
    final levelFilter = ref.watch(levelFilterProvider);
    final searchQuery = ref.watch(attendanceSearchQueryProvider);
    final statusFilter = ref.watch(attendanceStatusFilterProvider);
    final sectionFilter = ref.watch(attendanceSectionFilterProvider);
    final openClasses = ref.watch(openClassesProvider);
    final activeSections = ref.watch(activeSectionsProvider);
    final selectedRows = ref.watch(selectedRowsProvider);
    final isEditUnlocked = ref.watch(isEditUnlockedProvider);

    final allStudents = studentsState.students.values.expand((l) => l).toList();
    final kpis = classes.isEmpty
        ? null
        : KpiDataEntity(
            totalStudents: classes.fold<int>(0, (s, c) => s + c.totalStudents),
            presentToday: allStudents.where((s) => s.status == 'present').length,
            absentToday: allStudents.where((s) => s.status == 'absent').length,
            lateToday: allStudents.where((s) => s.status == 'late').length,
            presentPct: allStudents.isEmpty ? 0 : ((allStudents.where((s) => s.status == 'present').length / allStudents.length) * 100).round(),
          );

    return AttendanceLayout(
      currentPath: '/attendance/student',
      child: Container(
        color: const Color(0xFFF0EFFE),
        child: SafeArea(
          top: false,
          child: Stack(children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AttendancePageHeader(
                    onImport: () => setState(() => _importDialogOpen = true),
                    onExport: _handleExportCsv,
                    onDownloadSample: () => _toast('Sample attendance template downloaded.'),
                  ),
                  if (kpis != null && kpis.rteAtRisk > 0) AttendanceAlert(count: kpis.rteAtRisk),
                  AttendanceKpis(data: kpis, selectedDate: selectedDate, today: _today),
                  AttendanceFilterBar(
                    academicYear: academicYear,
                    levelFilter: levelFilter,
                    onYearChange: (v) => ref.read(academicYearProvider.notifier).state = v,
                    onLevelChange: (v) => ref.read(levelFilterProvider.notifier).state = v,
                  ),
                  GlobalControls(
                    selectedDate: selectedDate,
                    onDateChange: _handleDateChange,
                    searchQuery: searchQuery,
                    onSearchChange: (v) => ref.read(attendanceSearchQueryProvider.notifier).state = v,
                    statusFilter: statusFilter,
                    onStatusFilterChange: (v) => ref.read(attendanceStatusFilterProvider.notifier).state = v,
                    sectionFilter: sectionFilter,
                    onSectionFilterChange: (v) => ref.read(attendanceSectionFilterProvider.notifier).state = v,
                    onMarkAllVisible: (status) => _handleMarkAllVisible(status, classes, openClasses, activeSections, studentsState),
                    allVisibleMarked: _allVisibleMarked(classes, openClasses, activeSections, studentsState),
                  ),
                  ClassAccordionGrid(
                    classes: classes,
                    levelFilter: levelFilter,
                    searchQuery: searchQuery,
                    statusFilter: statusFilter,
                    sectionFilter: sectionFilter,
                    openClasses: openClasses,
                    onToggleClass: (id) => _handleToggleClass(id, classes, activeSections, studentsState),
                    activeSections: activeSections,
                    onSectionChange: _handleSectionChange,
                    students: studentsState.students,
                    loadingStudents: studentsState.loading,
                    selectedRows: selectedRows,
                    onSelectionChange: (key, ids) => ref.read(selectedRowsProvider.notifier).state = {...selectedRows, key: ids},
                    onToggleAbsent: _handleToggleAbsent,
                    onEditStatusPrompt: _handleEditStatusPrompt,
                    onToggleLunch: _handleToggleLunch,
                    onSignIn: _handleSignIn,
                    onSignOut: _handleSignOut,
                    onBulkMark: (classId, sectionId, status) => _handleBulkMark(classId, sectionId, status, selectedRows, studentsState),
                    onBulkSignIn: (classId, sectionId) => _handleBulkSignIn(classId, sectionId, selectedRows, studentsState),
                    onSave: _handleSave,
                    onReset: _handleReset,
                    onOpenNote: (classId, sectionId, student, mode) => setState(() => _notesDialogState = (classId: classId, sectionId: sectionId, student: student, mode: mode)),
                    readOnly: _isReadOnly,
                    dateMode: _dateMode,
                    selectedDate: selectedDate,
                    onRequestUnlock: () => setState(() => _showUnlockDialog = true),
                    isSundayLocked: _isSundaySelected && !isEditUnlocked && _dateMode == 'today',
                    onMarkAllPresentForClass: (classId) => _handleMarkAllPresentForClass(classId, classes, studentsState),
                    isEditUnlocked: isEditUnlocked,
                    onLogoutPastEdit: () {
                      ref.read(isEditUnlockedProvider.notifier).state = false;
                      _toast('Past-date edit mode closed.');
                    },
                  ),
                  MonthlyReport(selectedDate: selectedDate, classes: classes),
                ],
              ),
            ),
            if (_absentDialogState != null)
              AbsentNoteDialog(
                student: _absentDialogState!.student,
                initialReason: _absentDialogState!.student.absentReason ?? '',
                onConfirm: (reason) {
                  _commitStudentStatus(_absentDialogState!.classId, _absentDialogState!.sectionId, _absentDialogState!.student, 'absent', absentReason: reason.isEmpty ? null : reason);
                  setState(() => _absentDialogState = null);
                },
                onSkip: () {
                  if (_absentDialogState!.mode == 'mark') {
                    _commitStudentStatus(_absentDialogState!.classId, _absentDialogState!.sectionId, _absentDialogState!.student, 'absent');
                  }
                  setState(() => _absentDialogState = null);
                },
              ),
            if (_notesDialogState != null) _buildNotesDialog(studentsState),
            if (_lateDialogState != null)
              LateComerDialog(
                student: _lateDialogState!.student,
                minutesLate: _lateDialogState!.minutesLate,
                initialMessage: _lateDialogState!.student.absentReason ?? '',
                onMarkLate: (message) {
                  _commitStudentStatus(_lateDialogState!.classId, _lateDialogState!.sectionId, _lateDialogState!.student, 'late', absentReason: message.isEmpty ? null : message, signInTime: _lateDialogState!.signInTime);
                  setState(() => _lateDialogState = null);
                },
                onSchoolApproved: (reason) {
                  _commitStudentStatus(_lateDialogState!.classId, _lateDialogState!.sectionId, _lateDialogState!.student, 'present', absentReason: reason.isEmpty ? null : 'School approved: $reason', signInTime: _lateDialogState!.signInTime);
                  setState(() => _lateDialogState = null);
                },
                onMarkAbsent: (reason) {
                  _commitStudentStatus(_lateDialogState!.classId, _lateDialogState!.sectionId, _lateDialogState!.student, 'absent', absentReason: reason.isEmpty ? null : reason, signInTime: null);
                  setState(() => _lateDialogState = null);
                },
                onSkip: () {
                  _commitStudentStatus(_lateDialogState!.classId, _lateDialogState!.sectionId, _lateDialogState!.student, 'present', signInTime: _lateDialogState!.signInTime);
                  setState(() => _lateDialogState = null);
                },
              ),
            if (_showUnlockDialog)
              UnlockEditDialog(
                onUnlock: () {
                  ref.read(isEditUnlockedProvider.notifier).state = true;
                  setState(() => _showUnlockDialog = false);
                  _toast('Past date editing unlocked.');
                },
                onClose: () => setState(() => _showUnlockDialog = false),
              ),
            StudentAttendanceImportDialog(
              open: _importDialogOpen,
              classes: classes,
              onClose: () => setState(() => _importDialogOpen = false),
              onNotify: (message, tone) => _toast(message, error: tone == 'error'),
              onImported: ({required classId, required sectionId, required date, required imported}) {
                ref.read(selectedDateProvider.notifier).state = date;
                ref.read(activeSectionsProvider.notifier).state = {...activeSections, classId: sectionId};
                ref.read(openClassesProvider.notifier).state = {classId};
                ref.read(attendanceStudentsProvider.notifier).loadSection(classId, sectionId);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildNotesDialog(AttendanceStudentsState studentsState) {
    final st = _notesDialogState!;
    final key = '${st.classId}-${st.sectionId}';
    final list = studentsState.students[key] ?? const <AttendanceStudentEntity>[];
    final matches = list.where((s) => s.id == st.student.id).toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    final current = matches.first;
    final effectiveMode = st.mode == 'view' && current.notesCount == 0 ? 'add' : st.mode;
    if (effectiveMode == 'view') {
      return ViewNotesModal(
        student: current,
        onEditNote: (noteId, newText) => _handleUpdateNote(st.classId, st.sectionId, current.id, noteId, newText),
        onDeleteNote: (noteId) => _handleDeleteNote(st.classId, st.sectionId, current.id, noteId),
        onClose: () => setState(() => _notesDialogState = null),
      );
    }
    return NotesModal(
      student: current,
      initialNote: '',
      onSave: (_, noteText) => _handleSaveNote(st.classId, st.sectionId, current.id, noteText),
      onClose: () => setState(() => _notesDialogState = null),
    );
  }

  // ── Mutations (all local — no backend) ──────────────────────────────

  void _commitStudentStatus(int classId, int sectionId, AttendanceStudentEntity student, String newStatus, {String? absentReason, Object? signInTime = _unset, Object? signOutTime = _unset}) {
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    final resolvedSignIn = identical(signInTime, _unset) ? student.signInTime : signInTime as String?;
    final resolvedSignOut = identical(signOutTime, _unset) ? student.signOutTime : signOutTime as String?;
    final updated = student.copyWith(
      status: newStatus,
      absentReason: absentReason ?? (newStatus == 'absent' ? student.absentReason : null),
      signInTime: resolvedSignIn,
      signOutTime: resolvedSignOut,
      arrivalTime: resolvedSignIn ?? student.arrivalTime,
      isLate: newStatus == 'late',
    );
    notifier.updateStudent(classId, sectionId, updated);
    AttendanceLocalData.refreshClassSummary().then((_) => _reloadClasses());
    _toast('Attendance updated.');
  }

  void _handleToggleAbsent(int classId, int sectionId, AttendanceStudentEntity student) async {
    if (_isReadOnly) return;
    if (student.signInTime != null && student.signOutTime == null) {
      _toast('Sign out the student before marking absent.', error: true);
      return;
    }
    if (student.status == 'absent') {
      final result = await confirmDialog(context, title: 'Remove absent mark?', message: '${student.fullName} will be moved back to the unmarked list. You can sign them in afterwards.', tone: ConfirmTone.warn, confirmLabel: 'Yes, remove', cancelLabel: 'Keep absent');
      if (!result.ok) return;
      _commitStudentStatus(classId, sectionId, student, 'present', signInTime: null);
      return;
    }
    final result = await confirmDialog(context, title: 'Mark student absent?', message: "Confirm marking ${student.fullName} as absent for today. You'll be asked to add a reason next.", tone: ConfirmTone.danger, confirmLabel: 'Mark absent');
    if (!result.ok) return;
    setState(() => _absentDialogState = (classId: classId, sectionId: sectionId, student: student, mode: 'mark'));
  }

  void _handleEditStatusPrompt(int classId, int sectionId, AttendanceStudentEntity student) {
    if (_isReadOnly) return;
    if (student.status == 'absent') {
      setState(() => _absentDialogState = (classId: classId, sectionId: sectionId, student: student, mode: 'edit'));
      return;
    }
    if (student.status == 'late') {
      setState(() => _lateDialogState = (classId: classId, sectionId: sectionId, student: student, signInTime: student.signInTime ?? _nowHHMM(), minutesLate: student.lateMinutes > 0 ? student.lateMinutes : 1));
    }
  }

  void _handleToggleLunch(int classId, int sectionId, AttendanceStudentEntity student) {
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    notifier.updateStudent(classId, sectionId, student.copyWith(lunch: !student.lunch));
    _toast('Lunch status updated.');
  }

  void _handleSignIn(int classId, int sectionId, AttendanceStudentEntity student) {
    if (_isReadOnly || student.status == 'absent' || student.signInTime != null) return;
    final now = _nowHHMM();
    final lateInfo = _lateThresholdInfo(classId, sectionId, student, now);
    if (lateInfo.$1) {
      setState(() => _lateDialogState = (classId: classId, sectionId: sectionId, student: student, signInTime: now, minutesLate: lateInfo.$2));
      return;
    }
    _commitStudentStatus(classId, sectionId, student, 'present', signInTime: now);
  }

  (bool, int) _lateThresholdInfo(int classId, int sectionId, AttendanceStudentEntity student, String signInTime) {
    final key = '$classId-$sectionId';
    final sectionStudents = ref.read(attendanceStudentsProvider).students[key] ?? const <AttendanceStudentEntity>[];
    final eligible = sectionStudents.where((s) => s.status != 'absent').toList();
    if (eligible.isEmpty) return (false, 0);
    final candidateMinutes = _timeToMins(signInTime);
    if (candidateMinutes == null) return (false, 0);
    final signedTimes = <int>[];
    for (final s in eligible) {
      final time = s.id == student.id ? signInTime : s.signInTime;
      final mins = time != null ? _timeToMins(time) : null;
      if (mins != null) signedTimes.add(mins);
    }
    if (signedTimes.isEmpty) return (false, 0);
    final earliest = signedTimes.reduce((a, b) => a < b ? a : b);
    final minutesLate = (candidateMinutes - earliest).clamp(0, 1000000);
    if (minutesLate < 30) return (false, 0);
    return (true, minutesLate);
  }

  void _handleSignOut(int classId, int sectionId, AttendanceStudentEntity student) {
    if (_isReadOnly || student.signInTime == null || student.signOutTime != null) return;
    final now = _nowHHMM();
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    notifier.updateStudent(classId, sectionId, student.copyWith(signOutTime: now, pickupTime: now));
    _toast('Sign-out saved.');
  }

  void _handleBulkMark(int classId, int sectionId, String status, Map<String, Set<int>> selectedRows, AttendanceStudentsState studentsState) {
    final key = '$classId-$sectionId';
    final ids = selectedRows[key] ?? <int>{};
    final sectionStudents = studentsState.students[key] ?? const <AttendanceStudentEntity>[];
    final base = ids.isNotEmpty ? sectionStudents.where((s) => ids.contains(s.id)).toList() : sectionStudents;
    final targets = status == 'present' ? base.where((s) => s.status != 'absent').toList() : base;
    if (targets.isEmpty) return;
    final now = _nowHHMM();
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    for (final s in targets) {
      final shouldSignIn = status == 'present' && s.signInTime == null;
      notifier.updateStudent(classId, sectionId, s.copyWith(status: status, signInTime: shouldSignIn ? now : s.signInTime, arrivalTime: shouldSignIn ? (s.arrivalTime ?? now) : s.arrivalTime));
    }
    ref.read(selectedRowsProvider.notifier).state = {...selectedRows, key: <int>{}};
    AttendanceLocalData.refreshClassSummary().then((_) => _reloadClasses());
    _toast('${targets.length} attendance record(s) updated.');
  }

  void _handleBulkSignIn(int classId, int sectionId, Map<String, Set<int>> selectedRows, AttendanceStudentsState studentsState) {
    final key = '$classId-$sectionId';
    final ids = selectedRows[key] ?? <int>{};
    final now = _nowHHMM();
    final targets = (studentsState.students[key] ?? const <AttendanceStudentEntity>[]).where((s) => ids.contains(s.id) && s.status != 'absent').toList();
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    for (final s in targets) {
      notifier.updateStudent(classId, sectionId, s.copyWith(status: 'present', signInTime: s.signInTime ?? now, arrivalTime: s.arrivalTime ?? s.signInTime ?? now));
    }
    _toast('${targets.length} sign-in record(s) saved.');
  }

  void _handleSave(int classId, int sectionId) {
    _toast('✓ Saved attendance record(s).');
    final openClasses = ref.read(openClassesProvider);
    ref.read(openClassesProvider.notifier).state = Set.of(openClasses)..remove(classId);
    final key = '$classId-$sectionId';
    final selectedRows = ref.read(selectedRowsProvider);
    ref.read(selectedRowsProvider.notifier).state = {...selectedRows, key: <int>{}};
    AttendanceLocalData.refreshClassSummary().then((_) => _reloadClasses());
  }

  void _handleReset(int classId, int sectionId) {
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    final key = '$classId-$sectionId';
    final sectionStudents = ref.read(attendanceStudentsProvider).students[key] ?? const <AttendanceStudentEntity>[];
    for (final s in sectionStudents) {
      notifier.updateStudent(classId, sectionId, s.copyWith(status: 'unmarked', absentReason: null, arrivalTime: null, signInTime: null, signOutTime: null, pickupTime: null, pickupBy: null, notes: const [], isLate: false));
    }
    _toast('Section attendance reset.');
  }

  void _handleMarkAllVisible(String status, List<ClassInfoEntity> classes, Set<int> openClasses, Map<int, int> activeSections, AttendanceStudentsState studentsState) {
    final selectedRows = ref.read(selectedRowsProvider);
    for (final classId in openClasses) {
      final cls = classes.where((c) => c.id == classId).toList();
      if (cls.isEmpty) continue;
      final sectionId = activeSections[classId] ?? (cls.first.sections.isNotEmpty ? cls.first.sections.first.id : null);
      if (sectionId != null) _handleBulkMark(classId, sectionId, status, selectedRows, studentsState);
    }
  }

  bool _allVisibleMarked(List<ClassInfoEntity> classes, Set<int> openClasses, Map<int, int> activeSections, AttendanceStudentsState studentsState) {
    final visible = <AttendanceStudentEntity>[];
    for (final classId in openClasses) {
      final cls = classes.where((c) => c.id == classId).toList();
      if (cls.isEmpty) continue;
      final sectionId = activeSections[classId] ?? (cls.first.sections.isNotEmpty ? cls.first.sections.first.id : null);
      if (sectionId == null) continue;
      visible.addAll(studentsState.students['$classId-$sectionId'] ?? const []);
    }
    if (visible.isEmpty) return false;
    return visible.every((s) => s.status == 'present' || s.status == 'absent' || s.status == 'late');
  }

  void _handleMarkAllPresentForClass(int classId, List<ClassInfoEntity> classes, AttendanceStudentsState studentsState) {
    final cls = classes.where((c) => c.id == classId).toList();
    if (cls.isEmpty) return;
    final now = _nowHHMM();
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    var touched = 0;
    for (final sec in cls.first.sections) {
      final key = '$classId-${sec.id}';
      final sectionStudents = studentsState.students[key];
      if (sectionStudents == null || sectionStudents.isEmpty) continue;
      for (final s in sectionStudents.where((s) => s.status != 'absent')) {
        notifier.updateStudent(classId, sec.id, s.copyWith(status: 'present', signInTime: s.signInTime ?? now, arrivalTime: s.arrivalTime ?? s.signInTime ?? now));
        touched++;
      }
    }
    if (touched > 0) _toast('Marked $touched student(s) present in ${cls.first.displayLabel}.');
    AttendanceLocalData.refreshClassSummary().then((_) => _reloadClasses());
  }

  void _handleToggleClass(int classId, List<ClassInfoEntity> classes, Map<int, int> activeSections, AttendanceStudentsState studentsState) {
    final openClasses = ref.read(openClassesProvider);
    final isCurrentlyOpen = openClasses.contains(classId);
    ref.read(openClassesProvider.notifier).state = isCurrentlyOpen ? <int>{} : {classId};
    if (!isCurrentlyOpen) {
      final cls = classes.where((c) => c.id == classId).toList();
      if (cls.isNotEmpty && cls.first.sections.isNotEmpty) {
        final sectionId = activeSections[classId] ?? cls.first.sections.first.id;
        ref.read(attendanceStudentsProvider.notifier).loadSection(classId, sectionId);
      }
    }
  }

  void _handleSectionChange(int classId, int sectionId) {
    final activeSections = ref.read(activeSectionsProvider);
    ref.read(activeSectionsProvider.notifier).state = {...activeSections, classId: sectionId};
    ref.read(attendanceStudentsProvider.notifier).loadSection(classId, sectionId);
  }

  void _handleDateChange(String date) {
    ref.read(selectedDateProvider.notifier).state = date;
    ref.read(selectedRowsProvider.notifier).state = {};
    ref.read(isEditUnlockedProvider.notifier).state = false;
    ref.read(attendanceStudentsProvider.notifier).clear();
  }

  Future<void> _handleExportCsv() async {
    final classes = ref.read(classesProvider).maybeWhen(data: (v) => v, orElse: () => const <ClassInfoEntity>[]);
    final opts = await exportOptionsDialog(context, defaultDate: _selectedDate, classes: classes);
    if (opts == null) return;
    _toast('Attendance report downloaded.');
  }

  void _handleSaveNote(int classId, int sectionId, int studentId, String noteText) {
    final key = '$classId-$sectionId';
    final list = ref.read(attendanceStudentsProvider).students[key] ?? const <AttendanceStudentEntity>[];
    final matches = list.where((s) => s.id == studentId).toList();
    if (matches.isEmpty) return;
    final student = matches.first;
    final newNote = StudentNoteEntity(id: 'note-${DateTime.now().millisecondsSinceEpoch}', text: noteText, createdAt: '');
    ref.read(attendanceStudentsProvider.notifier).updateStudent(classId, sectionId, student.copyWith(notes: [...student.notes, newNote]));
    _toast('Note saved.');
    setState(() => _notesDialogState = null);
  }

  void _handleUpdateNote(int classId, int sectionId, int studentId, String noteId, String newText) {
    final key = '$classId-$sectionId';
    final list = ref.read(attendanceStudentsProvider).students[key] ?? const <AttendanceStudentEntity>[];
    final matches = list.where((s) => s.id == studentId).toList();
    if (matches.isEmpty) return;
    final student = matches.first;
    final updatedNotes = student.notes.map((n) => n.id == noteId ? StudentNoteEntity(id: n.id, text: newText, createdAt: n.createdAt) : n).toList();
    ref.read(attendanceStudentsProvider.notifier).updateStudent(classId, sectionId, student.copyWith(notes: updatedNotes));
    _toast('Note updated.');
  }

  void _handleDeleteNote(int classId, int sectionId, int studentId, String noteId) {
    final key = '$classId-$sectionId';
    final list = ref.read(attendanceStudentsProvider).students[key] ?? const <AttendanceStudentEntity>[];
    final matches = list.where((s) => s.id == studentId).toList();
    if (matches.isEmpty) return;
    final student = matches.first;
    final updatedNotes = student.notes.where((n) => n.id != noteId).toList();
    ref.read(attendanceStudentsProvider.notifier).updateStudent(classId, sectionId, student.copyWith(notes: updatedNotes));
    _toast('Note deleted.');
  }
}

const Object _unset = Object();
