import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../attendance/domain/entities/attendance_entities.dart';
import '../../../attendance/presentation/widgets/attendance_bulk_action_bar.dart';
import '../../../attendance/presentation/widgets/attendance_kpis.dart';
import '../../../attendance/presentation/widgets/attendance_table.dart';
import '../../../attendance/presentation/widgets/dialogs/absent_note_dialog.dart';
import '../../../attendance/presentation/widgets/dialogs/late_comer_dialog.dart';
import '../../../attendance/presentation/widgets/dialogs/notes_modal.dart';
import '../../../attendance/presentation/widgets/dialogs/view_notes_modal.dart';
import '../../../attendance/presentation/widgets/global_controls.dart';
import '../../domain/entities/teacher_attendance_entity.dart';
import '../providers/teacher_attendance_providers.dart';

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

/// Teacher Portal — Attendance (Sprint 5 parity port).
///
/// Direct port of web's `app/(teacher-portal)/teacher/attendance/page.tsx`,
/// which itself explicitly reuses the admin Student Attendance module's UI
/// components unchanged (`GlobalControls`, `AttendanceTable`,
/// `AttendanceBulkActionBar`, `AttendanceKpis`, `LateComerDialog`,
/// `AbsentNoteDialog`, `NotesModal`, `ViewNotesModal` — all from
/// `lib/features/attendance/presentation/widgets/`, imported here exactly
/// as web imports the admin TSX components). Only the data layer
/// (`TeacherAttendanceRepository`, scoped to `/api/v1/teacher/attendance/*`)
/// and this page's own layout/state are new.
///
/// Scope: only the class+section(s) the signed-in teacher is assigned to —
/// view-only unless the teacher is the class teacher of that section
/// (`can_edit`, from the fetch response). Unlike admin's Student Attendance
/// (Module 6), there is NO explicit "Save Attendance" button and NO
/// past-date unlock dialog — every edit auto-saves after an 800ms debounce
/// (see `TeacherAttendanceNotifier`), and a past date is permanently
/// read-only for a teacher (the backend itself returns 403 on a past-date
/// write for this endpoint — see `TeacherAttendanceStoreView`).
class TeacherAttendancePage extends ConsumerStatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  ConsumerState<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends ConsumerState<TeacherAttendancePage> {
  AttendanceStudentEntity? _absentDialogStudent;
  ({AttendanceStudentEntity student, int minutesLate})? _lateDialogState;
  AttendanceStudentEntity? _notesModalStudent;
  AttendanceStudentEntity? _viewNotesModalStudent;

  String get _today => todayIsoForTeacherAttendance();

  void _loadFor(TeacherClassOptionEntity cls, String date) {
    ref.read(teacherAttendanceRosterProvider.notifier).loadStudents(cls.classId, cls.sectionId, date);
  }

  bool _effectiveReadOnly(TeacherAttendanceRosterState rosterState, String selectedDate) {
    final isPastDate = selectedDate.compareTo(_today) < 0;
    return rosterState.isLocked || isPastDate || !rosterState.canEdit || rosterState.holidayName != null;
  }

  @override
  Widget build(BuildContext context) {
    final classOptionsAsync = ref.watch(teacherAttendanceClassOptionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        top: false,
        child: classOptionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _errorState(error),
          data: _buildWithClassOptions,
        ),
      ),
    );
  }

  Widget _errorState(Object error) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 32, color: Color(0xFF9CA0AE)),
                  const SizedBox(height: 12),
                  Text('Could not load your classes.\n${error.toString().replaceFirst('Exception: ', '')}',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B7B))),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(teacherAttendanceClassOptionsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithClassOptions(List<TeacherClassOptionEntity> classOptions) {
    if (classOptions.isEmpty) return _noClassesAssigned();

    final selectedClass = ref.watch(teacherAttendanceSelectedClassProvider);
    final selectedDate = ref.watch(teacherAttendanceSelectedDateProvider);

    if (selectedClass == null) {
      // Once options load, default to the first (class-teacher section, or
      // the first subject-assignment section) — mirrors web's one-shot
      // "once me loads, default to CT class" effect.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(teacherAttendanceSelectedClassProvider) != null) return;
        ref.read(teacherAttendanceSelectedClassProvider.notifier).state = classOptions.first;
        _loadFor(classOptions.first, selectedDate);
      });
      return const Center(child: CircularProgressIndicator());
    }

    final searchQuery = ref.watch(teacherAttendanceSearchProvider);
    final statusFilter = ref.watch(teacherAttendanceStatusFilterProvider);
    final sectionFilter = ref.watch(teacherAttendanceSectionFilterProvider);
    final selectedIds = ref.watch(teacherAttendanceSelectedIdsProvider);
    final rosterState = ref.watch(teacherAttendanceRosterProvider);
    final effectiveReadOnly = _effectiveReadOnly(rosterState, selectedDate);
    final isPastDate = selectedDate.compareTo(_today) < 0;
    final isFutureDate = selectedDate.compareTo(_today) > 0;

    final filtered = rosterState.students.where((s) {
      if (searchQuery.isNotEmpty &&
          !s.fullName.toLowerCase().contains(searchQuery.toLowerCase()) &&
          !s.rollNo.contains(searchQuery)) {
        return false;
      }
      if (statusFilter != 'all' && s.status != statusFilter) return false;
      return true;
    }).toList();
    final allVisibleMarked = filtered.isNotEmpty && filtered.every((s) => s.status != 'unmarked');
    final allMarked = rosterState.students.isNotEmpty && rosterState.students.every((s) => s.status != 'unmarked');

    final total = rosterState.students.length;
    final presentCount = rosterState.students.where((s) => s.status == 'present').length;
    final absentCount = rosterState.students.where((s) => s.status == 'absent').length;
    final lateCount = rosterState.students.where((s) => s.status == 'late').length;
    final presentPct = total > 0 ? ((presentCount / total) * 100).round() : 0;
    String? lateStudentName;
    for (final s in rosterState.students) {
      if (s.status == 'late') {
        lateStudentName = s.fullName;
        break;
      }
    }
    final kpiData = (rosterState.loading || total == 0)
        ? null
        : KpiDataEntity(
            totalStudents: total,
            presentToday: presentCount,
            absentToday: absentCount,
            lateToday: lateCount,
            presentPct: presentPct,
            absentWithReason: rosterState.students.where((s) => s.status == 'absent' && (s.absentReason?.isNotEmpty ?? false)).length,
            lateStudentName: lateStudentName,
            deltaPct: 0,
            absentDelta: 0,
          );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(classOptions, selectedClass, selectedDate),
          if (rosterState.holidayName != null) _holidayBanner(selectedDate, rosterState.holidayName!),
          const SizedBox(height: 4),
          AttendanceKpis(data: kpiData, selectedDate: selectedDate, today: _today),
          GlobalControls(
            selectedDate: selectedDate,
            onDateChange: (date) {
              ref.read(teacherAttendanceSelectedDateProvider.notifier).state = date;
              _loadFor(selectedClass, date);
            },
            searchQuery: searchQuery,
            onSearchChange: (v) => ref.read(teacherAttendanceSearchProvider.notifier).state = v,
            statusFilter: statusFilter,
            onStatusFilterChange: (v) => ref.read(teacherAttendanceStatusFilterProvider.notifier).state = v,
            sectionFilter: sectionFilter,
            onSectionFilterChange: (v) => ref.read(teacherAttendanceSectionFilterProvider.notifier).state = v,
            onMarkAllVisible: effectiveReadOnly ? (_) {} : (status) => _handleMarkAllVisible(status, filtered, selectedDate),
            allVisibleMarked: allVisibleMarked,
          ),
          if (!effectiveReadOnly)
            AttendanceBulkActionBar(
              count: selectedIds.length,
              onClear: () => ref.read(teacherAttendanceSelectedIdsProvider.notifier).state = {},
              onMarkAll: (status) => _handleBulkMark(status, selectedIds, selectedDate),
              onSignInAll: () => _handleBulkSignIn(selectedIds, selectedDate),
            ),
          Container(
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _classCardHeader(
                  selectedClass,
                  rosterState,
                  isLocked: rosterState.isLocked,
                  isPastDate: isPastDate,
                  isFutureDate: isFutureDate,
                  allMarked: allMarked,
                  presentCount: presentCount,
                  presentPct: presentPct,
                ),
                AttendanceTable(
                  students: filtered,
                  loading: rosterState.loading,
                  readOnly: effectiveReadOnly,
                  showLiveStatus: true,
                  selectedIds: selectedIds,
                  onSelect: (id, checked) {
                    final next = Set<int>.of(selectedIds);
                    checked ? next.add(id) : next.remove(id);
                    ref.read(teacherAttendanceSelectedIdsProvider.notifier).state = next;
                  },
                  onSelectAll: (checked) {
                    ref.read(teacherAttendanceSelectedIdsProvider.notifier).state =
                        checked ? filtered.map((s) => s.id).toSet() : <int>{};
                  },
                  onToggleAbsent: (s) => _handleToggleAbsent(s, effectiveReadOnly),
                  onToggleLunch: (s) => _handleToggleLunch(s, effectiveReadOnly, selectedDate),
                  onSignIn: (s) => _handleSignIn(s, effectiveReadOnly, rosterState, selectedDate),
                  onSignOut: (s) => _handleSignOut(s, effectiveReadOnly, selectedDate),
                  onViewNotes: (s) => setState(() => _viewNotesModalStudent = s),
                  onEditStatusPrompt: (s) => _handleEditStatusPrompt(s, effectiveReadOnly),
                  onEditNote: (s) {
                    if (effectiveReadOnly) return;
                    setState(() => _notesModalStudent = s);
                  },
                  onDeleteNote: (s) => _handleDeleteNote(s, effectiveReadOnly, selectedDate),
                ),
              ],
            ),
          ),
          if (_absentDialogStudent != null)
            AbsentNoteDialog(
              student: _absentDialogStudent!,
              initialReason: _absentDialogStudent!.absentReason ?? '',
              onConfirm: (reason) {
                final note = reason.isEmpty ? null : reason;
                ref.read(teacherAttendanceRosterProvider.notifier).updateOne(
                      _absentDialogStudent!.copyWith(
                        status: 'absent',
                        absentReason: note,
                        notes: note != null ? [StudentNoteEntity(id: 'n0', text: note)] : const [],
                      ),
                      selectedDate,
                    );
                setState(() => _absentDialogStudent = null);
              },
              onSkip: () {
                ref.read(teacherAttendanceRosterProvider.notifier).updateOne(
                      _absentDialogStudent!.copyWith(status: 'absent', absentReason: null),
                      selectedDate,
                    );
                setState(() => _absentDialogStudent = null);
              },
            ),
          if (_lateDialogState != null)
            LateComerDialog(
              student: _lateDialogState!.student,
              minutesLate: _lateDialogState!.minutesLate,
              initialMessage: _lateDialogState!.student.absentReason ?? '',
              onMarkLate: (message) {
                ref.read(teacherAttendanceRosterProvider.notifier).updateOne(
                      _lateDialogState!.student.copyWith(status: 'late', absentReason: message.isEmpty ? null : message, isLate: true),
                      selectedDate,
                    );
                setState(() => _lateDialogState = null);
              },
              onSchoolApproved: (reason) {
                ref.read(teacherAttendanceRosterProvider.notifier).updateOne(
                      _lateDialogState!.student.copyWith(
                        status: 'present',
                        absentReason: reason.isEmpty ? null : 'School approved: $reason',
                        isSchoolApprovedLate: true,
                      ),
                      selectedDate,
                    );
                setState(() => _lateDialogState = null);
              },
              onMarkAbsent: (reason) {
                ref.read(teacherAttendanceRosterProvider.notifier).updateOne(
                      _lateDialogState!.student.copyWith(status: 'absent', absentReason: reason.isEmpty ? null : reason),
                      selectedDate,
                    );
                setState(() => _lateDialogState = null);
              },
              onSkip: () => setState(() => _lateDialogState = null),
            ),
          if (_notesModalStudent != null)
            NotesModal(
              student: _notesModalStudent!,
              initialNote: _notesModalStudent!.absentReason ?? '',
              onSave: (student, noteText) {
                ref.read(teacherAttendanceRosterProvider.notifier).updateOne(
                      student.copyWith(absentReason: noteText, notes: [StudentNoteEntity(id: 'n0', text: noteText)]),
                      selectedDate,
                    );
                setState(() => _notesModalStudent = null);
              },
              onClose: () => setState(() => _notesModalStudent = null),
            ),
          if (_viewNotesModalStudent != null)
            ViewNotesModal(
              student: _viewNotesModalStudent!,
              onEditNote: (noteId, newText) {
                if (effectiveReadOnly) return;
                final student = _viewNotesModalStudent!;
                final updatedNotes = [
                  for (final n in student.notes)
                    n.id == noteId ? StudentNoteEntity(id: n.id, text: newText, createdAt: n.createdAt) : n,
                ];
                final updated = student.copyWith(absentReason: newText, notes: updatedNotes);
                ref.read(teacherAttendanceRosterProvider.notifier).updateOne(updated, selectedDate);
                setState(() => _viewNotesModalStudent = updated);
              },
              onDeleteNote: (noteId) {
                if (effectiveReadOnly) return;
                final student = _viewNotesModalStudent!;
                final updatedNotes = student.notes.where((n) => n.id != noteId).toList();
                final updated = student.copyWith(notes: updatedNotes, absentReason: null);
                ref.read(teacherAttendanceRosterProvider.notifier).updateOne(updated, selectedDate);
                setState(() => _viewNotesModalStudent = updated);
              },
              onClose: () => setState(() => _viewNotesModalStudent = null),
            ),
        ],
      ),
    );
  }

  Widget _noClassesAssigned() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(14)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 32, color: Color(0xFF9CA0AE)),
                  const SizedBox(height: 12),
                  const Text('No classes assigned', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
                  const SizedBox(height: 6),
                  const Text(
                    'You are not assigned to any class. Ask your admin to assign you as a class teacher or subject teacher.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA0AE)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(List<TeacherClassOptionEntity> allClasses, TeacherClassOptionEntity selectedClass, String selectedDate) {
    // Now its own card — same white/bordered style already used by the
    // class/roster card below it — instead of floating text directly on
    // the page background, per explicit request.
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      children: [
                        TextSpan(text: 'Student '),
                        TextSpan(text: 'Attendance', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: Color(0xFF6C3CE1))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Track and manage daily student attendance', style: TextStyle(fontSize: 13, color: Color(0xFF6B6B80))),
                ],
              ),
            ),
            if (allClasses.length > 1)
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedClass.key,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                    items: allClasses
                        .map((c) => DropdownMenuItem(
                              value: c.key,
                              child: Text('${c.className} – Section ${c.sectionName}${c.isClassTeacher ? '' : ' (View only)'}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      final found = allClasses.where((c) => c.key == value).toList();
                      if (found.isEmpty) return;
                      ref.read(teacherAttendanceSelectedClassProvider.notifier).state = found.first;
                      ref.read(teacherAttendanceSelectedIdsProvider.notifier).state = {};
                      ref.read(teacherAttendanceRosterProvider.notifier).clear();
                      _loadFor(found.first, selectedDate);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _holidayBanner(String selectedDate, String holidayName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), border: Border.all(color: const Color(0xFFFDBA74)), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_busy, size: 16, color: Color(0xFF9A3412)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF9A3412)),
                children: [
                  TextSpan(text: selectedDate, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' is a school holiday ('),
                  TextSpan(text: holidayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(
                      text: ') — every student in this class will be automatically marked Holiday. Manual marking is disabled for this date.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classCardHeader(
    TeacherClassOptionEntity selectedClass,
    TeacherAttendanceRosterState rosterState, {
    required bool isLocked,
    required bool isPastDate,
    required bool isFutureDate,
    required bool allMarked,
    required int presentCount,
    required int presentPct,
  }) {
    final canEdit = rosterState.canEdit;
    final holidayName = rosterState.holidayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          Text(selectedClass.className, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
          Text('${rosterState.students.length} student${rosterState.students.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0A8C5A), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('$presentCount present', style: const TextStyle(fontSize: 11, color: Color(0xFF0A8C5A))),
          ]),
          _badge('Section ${selectedClass.sectionName}', bg: const Color(0xFFEEF2FF), fg: const Color(0xFF4338CA)),
          if (holidayName != null) _badge('🎉 Holiday — $holidayName', bg: const Color(0xFFFFF7ED), fg: const Color(0xFF9A3412)),
          if (!isFutureDate && !isLocked && !isPastDate && holidayName == null)
            _badge(allMarked ? '✓ All Marked' : 'Attendance Needed',
                bg: allMarked ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED), fg: allMarked ? const Color(0xFF16A34A) : const Color(0xFFEA580C)),
          if (isLocked) _badge('🔒 Locked — contact admin to unlock', bg: const Color(0xFFFDF1DC), fg: const Color(0xFFB4721B)),
          if (isPastDate) _badge('👁 Past date — view only', bg: const Color(0xFFEEF2FF), fg: const Color(0xFF4338CA)),
          if (isFutureDate) _badge('⚠ Future date', bg: const Color(0xFFFEF9EC), fg: const Color(0xFFB45309)),
          if (!canEdit && !isPastDate && !isFutureDate && !isLocked) _badge('👁 View only', bg: const Color(0xFFF4F4F8), fg: const Color(0xFF5A5E70)),
          if (rosterState.saving && !isLocked && !isPastDate && canEdit)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0A8C5A), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Auto-saving', style: TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
            ]),
          if (rosterState.saveError != null)
            Text('⚠ ${rosterState.saveError}', style: const TextStyle(fontSize: 11, color: Color(0xFFC2264E), fontWeight: FontWeight.w600)),
          Text('$presentPct% today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: presentPct >= 75 ? const Color(0xFF16A34A) : const Color(0xFFE11D48))),
        ],
      ),
    );
  }

  Widget _badge(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  // ── Handlers — mirror web's page.tsx handlers 1:1 ──────────────────────

  void _handleToggleAbsent(AttendanceStudentEntity student, bool effectiveReadOnly) {
    if (effectiveReadOnly) return;
    if (student.status == 'absent') {
      ref.read(teacherAttendanceRosterProvider.notifier).updateOne(
            student.copyWith(status: 'present', absentReason: null),
            ref.read(teacherAttendanceSelectedDateProvider),
          );
    } else {
      setState(() => _absentDialogStudent = student);
    }
  }

  void _handleToggleLunch(AttendanceStudentEntity student, bool effectiveReadOnly, String date) {
    if (effectiveReadOnly) return;
    ref.read(teacherAttendanceRosterProvider.notifier).updateOne(student.copyWith(lunch: !student.lunch), date);
  }

  void _handleSignIn(AttendanceStudentEntity student, bool effectiveReadOnly, TeacherAttendanceRosterState rosterState, String date) {
    if (effectiveReadOnly || student.status == 'absent' || student.signInTime != null) return;
    final now = _nowHHMM();
    final updated = student.copyWith(signInTime: now, arrivalTime: student.arrivalTime ?? now, status: 'present');

    final earliestMins = <int>[];
    for (final s in rosterState.students) {
      if (s.status == 'absent') continue;
      final t = s.id == student.id ? now : s.signInTime;
      final mins = _timeToMins(t);
      if (mins != null) earliestMins.add(mins);
    }
    int? diff;
    if (earliestMins.isNotEmpty) {
      final earliest = earliestMins.reduce((a, b) => a < b ? a : b);
      final nowMins = _timeToMins(now);
      if (nowMins != null) diff = nowMins - earliest;
    }

    ref.read(teacherAttendanceRosterProvider.notifier).updateOne(updated, date);
    if (diff != null && diff >= 10) {
      setState(() => _lateDialogState = (student: updated, minutesLate: diff!));
    }
  }

  void _handleSignOut(AttendanceStudentEntity student, bool effectiveReadOnly, String date) {
    if (effectiveReadOnly || student.signInTime == null || student.signOutTime != null) return;
    ref.read(teacherAttendanceRosterProvider.notifier).updateOne(student.copyWith(signOutTime: _nowHHMM()), date);
  }

  void _handleEditStatusPrompt(AttendanceStudentEntity student, bool effectiveReadOnly) {
    if (effectiveReadOnly) return;
    if (student.status == 'absent') {
      setState(() => _absentDialogStudent = student);
    } else if (student.status == 'late') {
      setState(() => _lateDialogState = (student: student, minutesLate: student.lateMinutes));
    }
  }

  void _handleDeleteNote(AttendanceStudentEntity student, bool effectiveReadOnly, String date) {
    if (effectiveReadOnly) return;
    ref.read(teacherAttendanceRosterProvider.notifier).updateOne(student.copyWith(absentReason: null, notes: const []), date);
  }

  void _handleMarkAllVisible(String status, List<AttendanceStudentEntity> filtered, String date) {
    final ids = filtered.map((s) => s.id).toSet();
    ref.read(teacherAttendanceRosterProvider.notifier).updateMany(
          ids,
          (s) => s.copyWith(status: status, absentReason: status == 'absent' ? 'No intimation' : null, isLate: status == 'late'),
          date,
        );
  }

  void _handleBulkMark(String status, Set<int> selectedIds, String date) {
    ref.read(teacherAttendanceRosterProvider.notifier).updateMany(
          selectedIds,
          (s) => s.copyWith(status: status, absentReason: status == 'absent' ? 'No intimation' : null, isLate: status == 'late'),
          date,
        );
    ref.read(teacherAttendanceSelectedIdsProvider.notifier).state = {};
  }

  void _handleBulkSignIn(Set<int> selectedIds, String date) {
    final now = _nowHHMM();
    ref.read(teacherAttendanceRosterProvider.notifier).updateMany(
          selectedIds,
          (s) => s.copyWith(status: 'present', signInTime: s.signInTime ?? now, arrivalTime: s.arrivalTime ?? now),
          date,
        );
    ref.read(teacherAttendanceSelectedIdsProvider.notifier).state = {};
  }
}
