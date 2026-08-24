import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../domain/entities/attendance_entities.dart';
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

    final kpisAsync = ref.watch(dailySummaryProvider);
    final kpis = kpisAsync.maybeWhen(data: (v) => v, orElse: () => null);

    return AttendanceLayout(
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
                    onDownloadSample: _handleDownloadSample,
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

  void _commitStudentStatus(int classId, int sectionId, AttendanceStudentEntity student, String newStatus, {String? absentReason, Object? signInTime = _unset, Object? signOutTime = _unset}) async {
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
    try {
      await notifier.updateStudent(classId, sectionId, updated);
      _reloadClasses();
      _toast('Attendance updated.');
    } catch (e) {
      if (mounted) _toast('Unable to save attendance: $e', error: true);
    }
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

  void _handleToggleLunch(int classId, int sectionId, AttendanceStudentEntity student) async {
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    try {
      await notifier.updateStudent(classId, sectionId, student.copyWith(lunch: !student.lunch));
      _toast('Lunch status updated.');
    } catch (e) {
      if (mounted) _toast('Unable to save lunch status: $e', error: true);
    }
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

  void _handleSignOut(int classId, int sectionId, AttendanceStudentEntity student) async {
    if (_isReadOnly || student.signInTime == null || student.signOutTime != null) return;
    final now = _nowHHMM();
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    try {
      await notifier.updateStudent(classId, sectionId, student.copyWith(signOutTime: now, pickupTime: now));
      _toast('Sign-out saved.');
    } catch (e) {
      if (mounted) _toast('Unable to save sign-out: $e', error: true);
    }
  }

  void _handleBulkMark(int classId, int sectionId, String status, Map<String, Set<int>> selectedRows, AttendanceStudentsState studentsState) async {
    final key = '$classId-$sectionId';
    final ids = selectedRows[key] ?? <int>{};
    final sectionStudents = studentsState.students[key] ?? const <AttendanceStudentEntity>[];
    final base = ids.isNotEmpty ? sectionStudents.where((s) => ids.contains(s.id)).toList() : sectionStudents;
    final targets = status == 'present' ? base.where((s) => s.status != 'absent').toList() : base;
    if (targets.isEmpty) return;
    final now = _nowHHMM();
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    final updatedTargets = targets.map((s) {
      final shouldSignIn = status == 'present' && s.signInTime == null;
      return s.copyWith(status: status, signInTime: shouldSignIn ? now : s.signInTime, arrivalTime: shouldSignIn ? (s.arrivalTime ?? now) : s.arrivalTime);
    }).toList();
    for (final s in updatedTargets) {
      notifier.replaceSection(classId, sectionId, [
        for (final existing in sectionStudents) existing.id == s.id ? s : existing,
      ]);
    }
    ref.read(selectedRowsProvider.notifier).state = {...selectedRows, key: <int>{}};
    try {
      await notifier.persistSection(classId, sectionId, updatedTargets);
      _reloadClasses();
      _toast('${targets.length} attendance record(s) updated.');
    } catch (e) {
      if (mounted) _toast('Unable to save attendance: $e', error: true);
    }
  }

  void _handleBulkSignIn(int classId, int sectionId, Map<String, Set<int>> selectedRows, AttendanceStudentsState studentsState) async {
    final key = '$classId-$sectionId';
    final ids = selectedRows[key] ?? <int>{};
    final now = _nowHHMM();
    final sectionStudents = studentsState.students[key] ?? const <AttendanceStudentEntity>[];
    final targets = sectionStudents.where((s) => ids.contains(s.id) && s.status != 'absent').toList();
    if (targets.isEmpty) return;
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    final updatedTargets = targets.map((s) => s.copyWith(status: 'present', signInTime: s.signInTime ?? now, arrivalTime: s.arrivalTime ?? s.signInTime ?? now)).toList();
    notifier.replaceSection(classId, sectionId, [
      for (final existing in sectionStudents)
        if (updatedTargets.any((u) => u.id == existing.id)) updatedTargets.firstWhere((u) => u.id == existing.id) else existing,
    ]);
    try {
      await notifier.persistSection(classId, sectionId, updatedTargets);
      _toast('${targets.length} sign-in record(s) saved.');
    } catch (e) {
      if (mounted) _toast('Unable to save sign-ins: $e', error: true);
    }
  }

  void _handleSave(int classId, int sectionId) async {
    final key = '$classId-$sectionId';
    final sectionStudents = ref.read(attendanceStudentsProvider).students[key] ?? const <AttendanceStudentEntity>[];
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    try {
      await notifier.persistSection(classId, sectionId, sectionStudents);
      _toast('✓ Saved attendance record(s).');
    } catch (e) {
      if (mounted) _toast('Unable to save attendance: $e', error: true);
      return;
    }
    final openClasses = ref.read(openClassesProvider);
    ref.read(openClassesProvider.notifier).state = Set.of(openClasses)..remove(classId);
    final selectedRows = ref.read(selectedRowsProvider);
    ref.read(selectedRowsProvider.notifier).state = {...selectedRows, key: <int>{}};
    _reloadClasses();
  }

  /// Matches web's real `handleReset` exactly: it does NOT merely refetch
  /// (a previous version of this method assumed the `store/` endpoint had
  /// no way to clear a mark and just reloaded, which meant a saved "Absent"
  /// mark was still "Absent" truth on the server, so nothing ever visibly
  /// reset). Web explicitly wipes state on the server too — since `store/`
  /// requires a real P/A/L status for every id (its "full coverage" rule,
  /// there is no true "unmarked" server status), it sends every student in
  /// the section back to a `status: 'present'` baseline with
  /// reason/times/pickup all cleared, matching web's own reset payload. The
  /// UI briefly shows "unmarked" rows optimistically (mirroring web's
  /// immediate revert before its server round-trip resolves), then the
  /// final reload settles on "present" for everyone — the real, achievable
  /// meaning of "reset" here, not a truly blank status.
  void _handleReset(int classId, int sectionId) async {
    final key = '$classId-$sectionId';
    final sectionStudents = ref.read(attendanceStudentsProvider).students[key] ?? const <AttendanceStudentEntity>[];
    final notifier = ref.read(attendanceStudentsProvider.notifier);

    if (sectionStudents.isEmpty) {
      try {
        await notifier.loadSection(classId, sectionId);
      } catch (e) {
        if (mounted) _toast('Unable to reload section: $e', error: true);
      }
      return;
    }

    notifier.replaceSection(classId, sectionId, [
      for (final s in sectionStudents)
        s.copyWith(
          status: 'unmarked',
          absentReason: null,
          arrivalTime: null,
          signInTime: null,
          signOutTime: null,
          pickupTime: null,
          pickupBy: null,
          notes: const [],
        ),
    ]);

    final presentBaseline = [
      for (final s in sectionStudents)
        s.copyWith(
          status: 'present',
          absentReason: null,
          arrivalTime: null,
          signInTime: null,
          signOutTime: null,
          pickupTime: null,
          pickupBy: null,
        ),
    ];

    try {
      await notifier.persistSection(classId, sectionId, presentBaseline);
      _toast('Section attendance reset.');
    } catch (e) {
      if (mounted) _toast('Failed to reset attendance: $e', error: true);
    }
    try {
      await notifier.loadSection(classId, sectionId);
    } catch (_) {
      // Best-effort refresh — the reset itself already succeeded or failed
      // above; a failed refetch here just leaves the optimistic rows in
      // place rather than surfacing a second error for the same action.
    }
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

  void _handleMarkAllPresentForClass(int classId, List<ClassInfoEntity> classes, AttendanceStudentsState studentsState) async {
    final cls = classes.where((c) => c.id == classId).toList();
    if (cls.isEmpty) return;
    final now = _nowHHMM();
    final notifier = ref.read(attendanceStudentsProvider.notifier);
    var touched = 0;
    try {
      for (final sec in cls.first.sections) {
        final key = '$classId-${sec.id}';
        final sectionStudents = studentsState.students[key];
        if (sectionStudents == null || sectionStudents.isEmpty) continue;
        final targets = sectionStudents.where((s) => s.status != 'absent').toList();
        if (targets.isEmpty) continue;
        final updatedTargets = targets.map((s) => s.copyWith(status: 'present', signInTime: s.signInTime ?? now, arrivalTime: s.arrivalTime ?? s.signInTime ?? now)).toList();
        notifier.replaceSection(classId, sec.id, [
          for (final existing in sectionStudents)
            if (updatedTargets.any((u) => u.id == existing.id)) updatedTargets.firstWhere((u) => u.id == existing.id) else existing,
        ]);
        await notifier.persistSection(classId, sec.id, updatedTargets);
        touched += updatedTargets.length;
      }
      if (touched > 0) _toast('Marked $touched student(s) present in ${cls.first.displayLabel}.');
      _reloadClasses();
    } catch (e) {
      if (mounted) _toast('Unable to mark class present: $e', error: true);
    }
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
    try {
      final bytes = await ref.read(attendanceRepositoryProvider).exportAttendance(
            fmt: 'xlsx',
            classId: opts.classId == 'all' ? null : int.tryParse(opts.classId),
            sectionId: opts.sectionId == 'all' ? null : int.tryParse(opts.sectionId),
            month: opts.scope == 'month' ? int.tryParse(opts.month.split('-').last) : null,
            year: opts.scope == 'month' ? int.tryParse(opts.month.split('-').first) : null,
            date: opts.scope == 'day' ? opts.date : null,
            dateFrom: opts.scope == 'range' ? opts.dateFrom : null,
            dateTo: opts.scope == 'range' ? opts.dateTo : null,
          );
      await saveBytesForDownload(bytes: bytes, filename: 'attendance_export_${opts.scope}.xlsx');
      _toast('Attendance report downloaded.');
    } catch (e) {
      if (mounted) _toast('Unable to export attendance: $e', error: true);
    }
  }

  Future<void> _handleDownloadSample() async {
    try {
      final bytes = await ref.read(attendanceRepositoryProvider).downloadSample();
      await saveBytesForDownload(bytes: bytes, filename: 'student_attendance_sheet.xlsx');
      _toast('Sample attendance template downloaded.');
    } catch (e) {
      if (mounted) _toast('Unable to download sample: $e', error: true);
    }
  }

  void _handleSaveNote(int classId, int sectionId, int studentId, String noteText) async {
    final key = '$classId-$sectionId';
    final list = ref.read(attendanceStudentsProvider).students[key] ?? const <AttendanceStudentEntity>[];
    final matches = list.where((s) => s.id == studentId).toList();
    if (matches.isEmpty) return;
    final student = matches.first;
    final newNote = StudentNoteEntity(id: 'note-${DateTime.now().millisecondsSinceEpoch}', text: noteText, createdAt: '');
    try {
      // The backend only has one `notes`/`attendance_note` field per
      // (student, date) record — matching web's own documented "multiple
      // notes are a client-side illusion" reality, all notes are joined
      // and sent as the student's single `absentReason`/note field.
      final updatedNotes = [...student.notes, newNote];
      await ref.read(attendanceStudentsProvider.notifier).updateStudent(
            classId,
            sectionId,
            student.copyWith(notes: updatedNotes, absentReason: updatedNotes.map((n) => n.text).join(' ||| ')),
          );
      _toast('Note saved.');
      if (mounted) setState(() => _notesDialogState = null);
    } catch (e) {
      if (mounted) _toast('Unable to save note: $e', error: true);
    }
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
