import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entities.dart';

class AttendanceTableColumns {
  static const checkbox = 36.0;
  static const pupil = 190.0;
  static const rollNo = 70.0;
  static const absent = 80.0;
  static const arrival = 140.0;
  static const signIn = 120.0;
  static const signOut = 110.0;
  static const pickup = 100.0;
  static const lunch = 70.0;
  static const notes = 60.0;
  static const actions = 110.0;

  static double get total => checkbox + pupil + rollNo + absent + arrival + signIn + signOut + pickup + lunch + notes + actions;
}

/// Attendance Table — converted from web
/// `attendance/student/components/AttendanceTable.tsx`.
class AttendanceTable extends StatelessWidget {
  final List<AttendanceStudentEntity> students;
  final bool loading;
  final bool readOnly;
  final bool showLiveStatus;
  final Set<int> selectedIds;
  final void Function(int id, bool checked) onSelect;
  final void Function(bool checked) onSelectAll;
  final ValueChanged<AttendanceStudentEntity> onToggleAbsent;
  final ValueChanged<AttendanceStudentEntity> onToggleLunch;
  final ValueChanged<AttendanceStudentEntity> onSignIn;
  final ValueChanged<AttendanceStudentEntity> onSignOut;
  final ValueChanged<AttendanceStudentEntity> onViewNotes;
  final ValueChanged<AttendanceStudentEntity> onEditStatusPrompt;
  final ValueChanged<AttendanceStudentEntity> onEditNote;
  final ValueChanged<AttendanceStudentEntity> onDeleteNote;

  const AttendanceTable({
    super.key,
    required this.students,
    this.loading = false,
    this.readOnly = false,
    this.showLiveStatus = true,
    required this.selectedIds,
    required this.onSelect,
    required this.onSelectAll,
    required this.onToggleAbsent,
    required this.onToggleLunch,
    required this.onSignIn,
    required this.onSignOut,
    required this.onViewNotes,
    required this.onEditStatusPrompt,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  int? _timeToMins(String? t) {
    if (t == null) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t);
    if (m == null) return null;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = students.isNotEmpty && students.every((s) => selectedIds.contains(s.id));

    final signInMins = students.where((s) => s.status != 'absent').map((s) => _timeToMins(s.signInTime)).whereType<int>().toList();
    final earliestSignIn = signInMins.isEmpty ? null : signInMins.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      height: 380,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: AttendanceTableColumns.total,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(allSelected),
              Expanded(
                child: loading
                    ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('Loading students…', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)))))
                    : students.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('No students found', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)))))
                        : ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, i) {
                              final s = students[i];
                              int computedLateMinutes = s.lateMinutes;
                              final isSchoolApprovedLate = s.absentReason?.startsWith('School approved:') ?? false;
                              if ((s.isLate || isSchoolApprovedLate) && earliestSignIn != null && s.signInTime != null) {
                                final mins = _timeToMins(s.signInTime);
                                if (mins != null) {
                                  final diff = mins - earliestSignIn;
                                  if (diff > 0) computedLateMinutes = diff;
                                }
                              }
                              final enriched = s.copyWith(lateMinutes: computedLateMinutes, isSchoolApprovedLate: isSchoolApprovedLate || s.isSchoolApprovedLate);
                              return AttendanceTableRow(
                                key: ValueKey(s.id),
                                student: enriched,
                                isSelected: selectedIds.contains(s.id),
                                readOnly: readOnly,
                                showLiveStatus: showLiveStatus,
                                onSelect: (checked) => onSelect(s.id, checked),
                                onToggleAbsent: () => onToggleAbsent(s),
                                onToggleLunch: () => onToggleLunch(s),
                                onSignIn: () => onSignIn(s),
                                onSignOut: () => onSignOut(s),
                                onViewNotes: () => onViewNotes(s),
                                onEditStatusPrompt: () => onEditStatusPrompt(s),
                                onEditNote: () => onEditNote(s),
                                onDeleteNote: () => onDeleteNote(s),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool allSelected) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFEDEDF5), width: 1.5))),
      child: Row(
        children: [
          SizedBox(
            width: AttendanceTableColumns.checkbox,
            child: Checkbox(
              value: allSelected,
              onChanged: readOnly ? null : (v) => onSelectAll(v ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          _th('Pupil', AttendanceTableColumns.pupil),
          _th('Roll No', AttendanceTableColumns.rollNo, center: true),
          _th('Absent', AttendanceTableColumns.absent, center: true),
          _th('Arrival', AttendanceTableColumns.arrival),
          _th('Sign In', AttendanceTableColumns.signIn),
          _th('Sign Out', AttendanceTableColumns.signOut),
          _th('Pick-up', AttendanceTableColumns.pickup),
          _th('Lunch', AttendanceTableColumns.lunch, center: true),
          _th('Notes', AttendanceTableColumns.notes, center: true),
          _th('Actions', AttendanceTableColumns.actions),
        ],
      ),
    );
  }

  Widget _th(String label, double width, {bool center = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          label,
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), letterSpacing: 0.4),
        ),
      ),
    );
  }
}

/// Attendance Table Row — converted from web
/// `attendance/student/components/AttendanceTableRow.tsx`.
class AttendanceTableRow extends StatelessWidget {
  final AttendanceStudentEntity student;
  final bool isSelected;
  final bool readOnly;
  final bool showLiveStatus;
  final ValueChanged<bool> onSelect;
  final VoidCallback onToggleAbsent;
  final VoidCallback onToggleLunch;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onViewNotes;
  final VoidCallback onEditStatusPrompt;
  final VoidCallback onEditNote;
  final VoidCallback onDeleteNote;

  const AttendanceTableRow({
    super.key,
    required this.student,
    required this.isSelected,
    this.readOnly = false,
    this.showLiveStatus = true,
    required this.onSelect,
    required this.onToggleAbsent,
    required this.onToggleLunch,
    required this.onSignIn,
    required this.onSignOut,
    required this.onViewNotes,
    required this.onEditStatusPrompt,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;
    final isAbsent = s.status == 'absent';
    final hasActiveSignIn = s.signInTime != null && s.signOutTime == null && !isAbsent;
    final absentToggleLocked = s.signInTime != null && s.signOutTime == null;
    final canSignIn = !readOnly && !isAbsent && s.signInTime == null;
    final canToggleLunch = !readOnly && hasActiveSignIn && (s.status == 'present' || s.status == 'late');
    final showLateStatus = showLiveStatus && s.status != 'absent' && (s.status == 'late' || s.isLate);

    Color rowBg = Colors.transparent;
    Color leftBorder = Colors.transparent;
    if (isSelected) {
      rowBg = const Color(0xFFF4F2FF);
      leftBorder = const Color(0xFF4729F4);
    } else if (showLateStatus) {
      rowBg = const Color(0xFFFFF5F7);
      leftBorder = const Color(0xFFC2264E);
    }

    // The colored left indicator is painted via a `Positioned` overlay
    // rather than a `Border.left` on this `Container`: a decoration border
    // deflates its child's available width by the border's own thickness,
    // which made every data row exactly 3px narrower than the header row
    // above it (both meant to share the same `AttendanceTableColumns.total`
    // width) — a real, reproducible `RenderFlex overflowed by 3.0 pixels`
    // on every row, confirmed via a widget test.
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(color: rowBg, border: const Border(bottom: BorderSide(color: Color(0xFFF4F4F8)))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _cell(AttendanceTableColumns.checkbox, Checkbox(value: isSelected, onChanged: readOnly ? null : (v) => onSelect(v ?? false), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
              _cell(AttendanceTableColumns.pupil, _pupilCell()),
              _cell(AttendanceTableColumns.rollNo, Text(s.rollNo.isEmpty ? '—' : s.rollNo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5A5E70)))),
              _cell(AttendanceTableColumns.absent, Center(child: _absentToggle(isAbsent, absentToggleLocked))),
              _cell(AttendanceTableColumns.arrival, _arrivalCell()),
              _cell(AttendanceTableColumns.signIn, _signInCell(hasActiveSignIn, canSignIn)),
              _cell(AttendanceTableColumns.signOut, _signOutCell()),
              _cell(AttendanceTableColumns.pickup, _pickupCell()),
              _cell(AttendanceTableColumns.lunch, Center(child: _lunchToggle(canToggleLunch))),
              _cell(AttendanceTableColumns.notes, Center(child: _notesCell())),
              _cell(AttendanceTableColumns.actions, _actionsCell()),
            ],
          ),
        ),
        if (leftBorder != Colors.transparent) Positioned(left: 0, top: 0, bottom: 1, child: Container(width: 3, color: leftBorder)),
      ],
    );
  }

  Widget _cell(double width, Widget child) => SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: child));

  Widget _pupilCell() {
    final s = student;
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(radius: 16, backgroundColor: Color(s.avatarColor), child: Text(s.initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
            Positioned(
              bottom: -1,
              right: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: (showLiveStatus && (s.signInTime != null && s.signOutTime == null && s.status != 'absent')) ? const Color(0xFF0A8C5A) : const Color(0xFF9CA0AE), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
              Wrap(spacing: 4, runSpacing: 2, children: [
                Text(s.group, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA0AE))),
                if (s.syncedFromApp) _tinyBadge('App', const Color(0xFFEEEBFF), const Color(0xFF4729F4)),
                if (s.rtePct != null && s.rtePct! < 75) _tinyBadge('RTE', const Color(0xFFFCE8EE), const Color(0xFFC2264E)),
                if (s.absentReason != null && s.absentReason!.isNotEmpty && (s.status == 'absent' || s.status == 'late'))
                  _tinyBadge(s.absentReason!, const Color(0xFFFDF1DC), const Color(0xFFB4721B)),
                if (s.isSchoolApprovedLate && s.absentReason != null)
                  _tinyBadge(s.absentReason!.replaceFirst(RegExp(r'^School approved:\s*', caseSensitive: false), '').isEmpty ? 'Approved late' : s.absentReason!.replaceFirst(RegExp(r'^School approved:\s*', caseSensitive: false), ''), const Color(0xFFE4F6ED), const Color(0xFF0A8C5A)),
                if (showLiveStatus && student.status != 'absent' && (student.status == 'late' || student.isLate)) _tinyBadge('⏰ Late Comer', const Color(0xFFFDF1DC), const Color(0xFFB4721B)),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tinyBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _absentToggle(bool isAbsent, bool locked) {
    return GestureDetector(
      onTap: (readOnly || locked) ? null : onToggleAbsent,
      child: Opacity(
        opacity: (readOnly || locked) ? 0.4 : 1,
        child: Container(
          width: 32,
          height: 18,
          padding: const EdgeInsets.all(2),
          alignment: isAbsent ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(color: isAbsent ? const Color(0xFFC2264E) : const Color(0xFFE6E6EC), borderRadius: BorderRadius.circular(999)),
          child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
      ),
    );
  }

  Widget _lunchToggle(bool enabled) {
    final on = student.lunch;
    return GestureDetector(
      onTap: enabled ? onToggleLunch : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 32,
          height: 18,
          padding: const EdgeInsets.all(2),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(color: on ? const Color(0xFF4729F4) : const Color(0xFFE6E6EC), borderRadius: BorderRadius.circular(999)),
          child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
      ),
    );
  }

  Widget _arrivalCell() {
    final s = student;
    if (!showLiveStatus) return Text(s.arrivalTime ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A4A)));
    if (s.arrivalTime != null) {
      Color bg, fg, border;
      if (s.isLate) {
        bg = const Color(0xFFFDF1DC);
        fg = const Color(0xFFB4721B);
        border = const Color(0x4DB4721B);
      } else if (s.isSchoolApprovedLate && s.lateMinutes > 0) {
        bg = const Color(0xFFE4F6ED);
        fg = const Color(0xFF0A8C5A);
        border = const Color(0x4D0A8C5A);
      } else {
        bg = const Color(0xFFF4F4F8);
        fg = const Color(0xFF3A3A4A);
        border = Colors.transparent;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(s.arrivalTime!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          if (s.isLate && s.lateMinutes > 0) Text(' +${s.lateMinutes}m', style: TextStyle(fontSize: 9, color: fg)),
          if (!s.isLate && s.isSchoolApprovedLate && s.lateMinutes > 0) Tooltip(message: 'Approved late arrival', child: Text(' +${s.lateMinutes}m ✓', style: TextStyle(fontSize: 9, color: fg))),
        ]),
      );
    }
    return const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)));
  }

  Widget _signInCell(bool hasActiveSignIn, bool canSignIn) {
    final s = student;
    if (!showLiveStatus) return Text(s.signInTime ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A4A)));
    if (s.signInTime != null) {
      final bg = hasActiveSignIn ? const Color(0xFFE4F6ED) : const Color(0xFFF4F4F8);
      final fg = hasActiveSignIn ? const Color(0xFF0A8C5A) : const Color(0xFF3A3A4A);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(s.signInTime!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );
    }
    if (readOnly) return const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)));
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: canSignIn ? onSignIn : null,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('Sign in'),
      ),
    );
  }

  Widget _signOutCell() {
    final s = student;
    if (!showLiveStatus) return Text(s.signOutTime ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A4A)));
    if (s.signOutTime != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFF4F4F8), borderRadius: BorderRadius.circular(8)),
        child: Text(s.signOutTime!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3A3A4A))),
      );
    }
    if (s.signInTime != null && !readOnly) {
      return SizedBox(
        height: 28,
        child: OutlinedButton(
          onPressed: onSignOut,
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC)), backgroundColor: const Color(0xFFF4F4F8), padding: const EdgeInsets.symmetric(horizontal: 12), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Sign out'),
        ),
      );
    }
    return const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)));
  }

  Widget _pickupCell() {
    final s = student;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.pickupTime ?? '—', style: TextStyle(fontSize: 12, color: s.pickupTime != null ? const Color(0xFF3A3A4A) : const Color(0xFF9CA0AE))),
        if (s.pickupBy != null && s.pickupBy!.isNotEmpty)
          Tooltip(message: s.pickupBy!, child: Text(s.pickupBy!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF6B6B7B)))),
      ],
    );
  }

  Widget _notesCell() {
    final n = student.notesCount;
    if (n > 0) {
      return Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFF4729F4), shape: BoxShape.circle),
        child: Text('$n', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
      );
    }
    return const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)));
  }

  Widget _actionsCell() {
    final s = student;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (!readOnly && (s.status == 'absent' || s.status == 'late'))
        _iconBtn(
          Icons.edit_outlined,
          bg: s.status == 'absent' ? const Color(0xFFFCE8EE) : const Color(0xFFFDF1DC),
          fg: s.status == 'absent' ? const Color(0xFFC2264E) : const Color(0xFFB4721B),
          tooltip: s.status == 'absent' ? 'Update absent reason' : 'Update late prompt',
          onTap: onEditStatusPrompt,
        ),
      if (s.notesCount > 0) _iconBtn(Icons.visibility_outlined, bg: const Color(0xFFE6E6EC), fg: const Color(0xFF6B6B7B), tooltip: 'View notes', onTap: onViewNotes),
      if (!readOnly) _iconBtn(Icons.note_add_outlined, bg: const Color(0xFFE6E6EC), fg: const Color(0xFF6B6B7B), tooltip: 'Add / edit note', onTap: onEditNote),
      if (s.notesCount > 0 && !readOnly) _iconBtn(Icons.delete_outline, bg: const Color(0xFFE6E6EC), fg: const Color(0xFF6B6B7B), tooltip: 'Delete note', onTap: onDeleteNote),
    ]);
  }

  Widget _iconBtn(IconData icon, {required Color bg, required Color fg, required String tooltip, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 13, color: fg)),
        ),
      ),
    );
  }
}
