import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entities.dart';
import 'attendance_ring.dart';
import 'attendance_table.dart';
import 'attendance_bulk_action_bar.dart';
import 'section_tabs.dart';

/// Class Accordion Grid — converted from web
/// `attendance/student/components/ClassAccordionGrid.tsx`. Purely
/// presentational (mirrors web exactly): all mutations are delegated to
/// the callbacks passed in from the orchestrator page, which applies them
/// to local Riverpod state instead of a backend.
class ClassAccordionGrid extends StatelessWidget {
  final List<ClassInfoEntity> classes;
  final LevelFilter levelFilter;
  final String searchQuery;
  final String statusFilter;
  final String sectionFilter;
  final Set<int> openClasses;
  final ValueChanged<int> onToggleClass;
  final Map<int, int> activeSections;
  final void Function(int classId, int sectionId) onSectionChange;
  final Map<String, List<AttendanceStudentEntity>> students;
  final Map<String, bool> loadingStudents;
  final Map<String, Set<int>> selectedRows;
  final void Function(String key, Set<int> ids) onSelectionChange;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onToggleAbsent;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onEditStatusPrompt;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onToggleLunch;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onSignIn;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onSignOut;
  final void Function(int classId, int sectionId, String status) onBulkMark;
  final void Function(int classId, int sectionId) onBulkSignIn;
  final void Function(int classId, int sectionId) onSave;
  final void Function(int classId, int sectionId) onReset;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student, String mode) onOpenNote;
  final bool readOnly;
  final String dateMode; // 'today' | 'past' | 'future'
  final String? selectedDate;
  final VoidCallback? onRequestUnlock;
  final bool isSundayLocked;
  final void Function(int classId)? onMarkAllPresentForClass;
  final bool isEditUnlocked;
  final VoidCallback? onLogoutPastEdit;

  const ClassAccordionGrid({
    super.key,
    required this.classes,
    required this.levelFilter,
    required this.searchQuery,
    required this.statusFilter,
    required this.sectionFilter,
    required this.openClasses,
    required this.onToggleClass,
    required this.activeSections,
    required this.onSectionChange,
    required this.students,
    required this.loadingStudents,
    required this.selectedRows,
    required this.onSelectionChange,
    required this.onToggleAbsent,
    required this.onEditStatusPrompt,
    required this.onToggleLunch,
    required this.onSignIn,
    required this.onSignOut,
    required this.onBulkMark,
    required this.onBulkSignIn,
    required this.onSave,
    required this.onReset,
    required this.onOpenNote,
    this.readOnly = false,
    this.dateMode = 'today',
    this.selectedDate,
    this.onRequestUnlock,
    this.isSundayLocked = false,
    this.onMarkAllPresentForClass,
    this.isEditUnlocked = false,
    this.onLogoutPastEdit,
  });

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim().toLowerCase();
    final visible = classes.where((cls) {
      if (levelFilter != 'all' && cls.level != levelFilter) return false;
      if (q.isNotEmpty) {
        if (cls.name.toLowerCase().contains(q) || cls.displayLabel.toLowerCase().contains(q)) return true;
        final all = cls.sections.expand((sec) => students['${cls.id}-${sec.id}'] ?? const <AttendanceStudentEntity>[]);
        return all.any((s) => s.fullName.toLowerCase().contains(q));
      }
      return true;
    }).toList();

    String formattedDate = '';
    if (selectedDate != null) {
      final d = DateTime.tryParse(selectedDate!);
      if (d != null) {
        const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        formattedDate = '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
      }
    }

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Icon(Icons.donut_large_outlined, size: 40, color: const Color(0xFF9B9BAD).withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('No classes match the current filters.', style: TextStyle(fontSize: 14, color: Color(0xFF9B9BAD))),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (readOnly && dateMode == 'past') _banner(bg: const Color(0xFFFFFBEB), border: const Color(0xFFF4DCA7), iconBg: const Color(0xFFFDF1DC), icon: Icons.lock_outline, iconColor: const Color(0xFFB4721B), titleColor: const Color(0xFF92400E), subColor: const Color(0xFFB45309), title: 'Viewing past date — $formattedDate', subtitle: 'This record is read-only. Login to edit past attendance.', buttonLabel: 'Login to Edit', buttonBg: const Color(0xFFFDF1DC), buttonFg: const Color(0xFF9A5C00), buttonBorder: const Color(0xFFF4DCA7), onButtonTap: onRequestUnlock),
        if (!readOnly && dateMode == 'past' && isEditUnlocked) _banner(bg: const Color(0xFFFFF1F2), border: const Color(0xFFFBCFE8), iconBg: const Color(0xFFFCE7F3), icon: Icons.warning_amber_rounded, iconColor: const Color(0xFFBE185D), titleColor: const Color(0xFF9D174D), subColor: const Color(0xFFBE185D), title: 'Past-date edit mode is active', subtitle: 'Please log out after finishing changes for this past date.', buttonLabel: 'Logout', buttonBg: const Color(0xFFFCE7F3), buttonFg: const Color(0xFF9D174D), buttonBorder: const Color(0xFFF9A8D4), onButtonTap: onLogoutPastEdit),
        if (readOnly && dateMode == 'future') _banner(bg: const Color(0xFFF5F3FF), border: const Color(0xFFC5BEFF), iconBg: const Color(0xFFEDE9FE), icon: Icons.access_time, iconColor: const Color(0xFF7C3AED), titleColor: const Color(0xFF4C1D95), subColor: const Color(0xFF6D28D9), title: 'Viewing future date — $formattedDate', subtitle: 'Attendance cannot be taken for future dates.'),
        if (isSundayLocked) _banner(bg: const Color(0xFFF5F3FF), border: const Color(0xFFC5BEFF), iconBg: const Color(0xFFEDE9FE), icon: Icons.beach_access_outlined, iconColor: const Color(0xFF7C3AED), titleColor: const Color(0xFF4C1D95), subColor: const Color(0xFF6D28D9), title: 'Today is Sunday — attendance is read-only', subtitle: 'Sunday attendance is locked by default. Login to edit if needed.', buttonLabel: 'Login to Edit', buttonBg: const Color(0xFFEDE9FE), buttonFg: const Color(0xFF5B21B6), buttonBorder: const Color(0xFFC5BEFF), onButtonTap: onRequestUnlock),
        ...visible.map((cls) => _ClassCard(
              cls: cls,
              isOpen: openClasses.contains(cls.id),
              onToggle: onToggleClass,
              activeSectionId: activeSections[cls.id],
              onSectionChange: onSectionChange,
              students: students,
              loadingStudents: loadingStudents,
              selectedRows: selectedRows,
              searchQuery: searchQuery,
              statusFilter: statusFilter,
              sectionFilter: sectionFilter,
              onSelectionChange: onSelectionChange,
              onToggleAbsent: onToggleAbsent,
              onEditStatusPrompt: onEditStatusPrompt,
              onToggleLunch: onToggleLunch,
              onSignIn: onSignIn,
              onSignOut: onSignOut,
              onBulkMark: onBulkMark,
              onBulkSignIn: onBulkSignIn,
              onSave: onSave,
              onReset: onReset,
              onOpenNote: onOpenNote,
              readOnly: readOnly,
              dateMode: dateMode,
              onMarkAllPresentForClass: onMarkAllPresentForClass,
            )),
      ],
    );
  }

  Widget _banner({
    required Color bg,
    required Color border,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required Color titleColor,
    required Color subColor,
    required String title,
    required String subtitle,
    String? buttonLabel,
    Color? buttonBg,
    Color? buttonFg,
    Color? buttonBorder,
    VoidCallback? onButtonTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: iconColor)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: subColor)),
              ],
            ),
          ),
          if (buttonLabel != null && onButtonTap != null)
            OutlinedButton(
              onPressed: onButtonTap,
              style: OutlinedButton.styleFrom(backgroundColor: buttonBg, foregroundColor: buttonFg, side: BorderSide(color: buttonBorder ?? Colors.transparent), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(buttonLabel),
            ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatefulWidget {
  final ClassInfoEntity cls;
  final bool isOpen;
  final ValueChanged<int> onToggle;
  final int? activeSectionId;
  final void Function(int classId, int sectionId) onSectionChange;
  final Map<String, List<AttendanceStudentEntity>> students;
  final Map<String, bool> loadingStudents;
  final Map<String, Set<int>> selectedRows;
  final String searchQuery;
  final String statusFilter;
  final String sectionFilter;
  final void Function(String key, Set<int> ids) onSelectionChange;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onToggleAbsent;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onEditStatusPrompt;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onToggleLunch;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onSignIn;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onSignOut;
  final void Function(int classId, int sectionId, String status) onBulkMark;
  final void Function(int classId, int sectionId) onBulkSignIn;
  final void Function(int classId, int sectionId) onSave;
  final void Function(int classId, int sectionId) onReset;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student, String mode) onOpenNote;
  final bool readOnly;
  final String dateMode;
  final void Function(int classId)? onMarkAllPresentForClass;

  const _ClassCard({
    required this.cls,
    required this.isOpen,
    required this.onToggle,
    this.activeSectionId,
    required this.onSectionChange,
    required this.students,
    required this.loadingStudents,
    required this.selectedRows,
    required this.searchQuery,
    required this.statusFilter,
    required this.sectionFilter,
    required this.onSelectionChange,
    required this.onToggleAbsent,
    required this.onEditStatusPrompt,
    required this.onToggleLunch,
    required this.onSignIn,
    required this.onSignOut,
    required this.onBulkMark,
    required this.onBulkSignIn,
    required this.onSave,
    required this.onReset,
    required this.onOpenNote,
    this.readOnly = false,
    this.dateMode = 'today',
    this.onMarkAllPresentForClass,
  });

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _markAllCooldown = false;

  @override
  Widget build(BuildContext context) {
    final cls = widget.cls;
    final filteredSections = widget.sectionFilter == 'all'
        ? cls.sections
        : cls.sections.where((sec) {
            final name = sec.name.trim().toUpperCase();
            final target = widget.sectionFilter.toUpperCase();
            return name == target || name.endsWith(' $target') || name.replaceFirst(RegExp(r'^SECTION\s+', caseSensitive: false), '') == target;
          }).toList();
    final activeSec = widget.activeSectionId ?? (filteredSections.isNotEmpty ? filteredSections.first.id : null);
    final sectionKey = activeSec != null ? '${cls.id}-$activeSec' : null;
    final sectionStudents = sectionKey != null ? (widget.students[sectionKey] ?? const <AttendanceStudentEntity>[]) : const <AttendanceStudentEntity>[];
    final isLoading = sectionKey != null ? (widget.loadingStudents[sectionKey] ?? false) : false;
    final sectionSelected = sectionKey != null ? (widget.selectedRows[sectionKey] ?? <int>{}) : <int>{};
    final activeSectionSummary = filteredSections.where((s) => s.id == activeSec).isNotEmpty ? filteredSections.firstWhere((s) => s.id == activeSec) : (filteredSections.isNotEmpty ? filteredSections.first : null);

    final allSectionsLoaded = filteredSections.isNotEmpty && filteredSections.every((sec) {
      final arr = widget.students['${cls.id}-${sec.id}'];
      return arr != null && arr.isNotEmpty;
    });
    final allLoaded = filteredSections.expand((sec) => widget.students['${cls.id}-${sec.id}'] ?? const <AttendanceStudentEntity>[]).toList();
    final localPresent = allLoaded.where((s) => s.status == 'present').length;
    final localAbsent = allLoaded.where((s) => s.status == 'absent').length;
    final localLate = allLoaded.where((s) => s.status == 'late').length;

    final totalPresent = allSectionsLoaded ? localPresent : cls.totalPresent;
    final totalAbsent = allSectionsLoaded ? localAbsent : cls.totalAbsent;
    final totalLate = allSectionsLoaded ? localLate : cls.totalLate;
    final totalForPct = cls.totalStudents;
    final rawPct = totalForPct > 0 ? (((totalPresent + totalLate) / totalForPct) * 100).round() : 0;
    final attendancePct = rawPct.clamp(0, 100);

    final accountedFor = totalPresent + totalLate + totalAbsent;
    String attendanceStatus;
    if (cls.totalStudents == 0) {
      attendanceStatus = 'none';
    } else if (accountedFor == 0) {
      attendanceStatus = 'needed';
    } else if (accountedFor < cls.totalStudents) {
      attendanceStatus = 'in_progress';
    } else {
      attendanceStatus = 'complete';
    }

    final levelBorderColor = cls.level == 'primary' ? const Color(0xFF22C55E) : cls.level == 'middle' ? const Color(0xFF4729F4) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isOpen ? const Color(0xFFE0DBFD) : const Color(0xFFE6E6EC)),
        boxShadow: widget.isOpen ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 6)] : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: widget.isOpen ? levelBorderColor : Colors.transparent, width: 4))),
            child: InkWell(
              onTap: () => widget.onToggle(cls.id),
              child: Container(
                color: widget.isOpen ? const Color(0xFFF8F6FF) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: widget.isOpen ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9CA0AE)),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cls.displayLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
                        if (cls.subLabel.isNotEmpty) Text(cls.subLabel, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA0AE))),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(spacing: 6, runSpacing: 4, children: [
                        _pill('${cls.totalStudents} ${cls.totalStudents == 1 ? "student" : "students"}', const Color(0xFFFAFAFD), const Color(0xFF3A3A4A), border: const Color(0xFFE6E6EC)),
                        _pill('$totalPresent present', const Color(0xFFE4F6ED), const Color(0xFF0A8C5A)),
                        if (totalAbsent > 0) _pill('$totalAbsent absent', const Color(0xFFFCE8EE), const Color(0xFFC2264E)),
                        if (totalLate > 0) _pill('$totalLate late', const Color(0xFFFDF1DC), const Color(0xFFB4721B)),
                        _pill('${filteredSections.length} ${filteredSections.length == 1 ? "section" : "sections"}', const Color(0xFFF1F1F5), const Color(0xFF6B6B7B)),
                        if (widget.dateMode != 'future' && attendanceStatus == 'needed') _pill('Attendance Needed', const Color(0xFFFCE8EE), const Color(0xFFC2264E)),
                        if (widget.dateMode != 'future' && attendanceStatus == 'in_progress') _pill('In Progress', const Color(0xFFFDF1DC), const Color(0xFFB4721B)),
                        if (widget.dateMode != 'future' && attendanceStatus == 'complete') _pill('✓ Complete', const Color(0xFFE4F6ED), const Color(0xFF0A8C5A)),
                      ]),
                    ),
                    if (!widget.isOpen && widget.dateMode == 'today' && !widget.readOnly && widget.onMarkAllPresentForClass != null && attendanceStatus != 'complete')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: _markAllCooldown
                              ? null
                              : () {
                                  widget.onMarkAllPresentForClass!(cls.id);
                                  setState(() => _markAllCooldown = true);
                                  Future.delayed(const Duration(milliseconds: 1500), () {
                                    if (mounted) setState(() => _markAllCooldown = false);
                                  });
                                },
                          style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFE4F6ED), foregroundColor: const Color(0xFF0A8C5A), side: const BorderSide(color: Color(0x330A8C5A)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('✓ Mark All Present'),
                        ),
                      ),
                    AttendanceRing(pct: attendancePct, size: 32, strokeWidth: 3),
                    const SizedBox(width: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$attendancePct%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: attendancePct == 0 ? const Color(0xFFEF4444) : const Color(0xFF4729F4))),
                        const Text('today', style: TextStyle(fontSize: 9, color: Color(0xFF9CA0AE))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.isOpen)
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
              width: double.infinity,
              child: filteredSections.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No sections configured.', style: TextStyle(fontSize: 13, color: Color(0xFF9B9BAD)))))
                  : Column(
                      children: [
                        if (filteredSections.length > 1)
                          SectionTabs(sections: filteredSections, activeSection: activeSec ?? filteredSections.first.id, onChange: (id) => widget.onSectionChange(cls.id, id), students: widget.students, classId: cls.id),
                        if (activeSec != null && activeSectionSummary != null)
                          _SectionBody(
                            classId: cls.id,
                            sectionId: activeSec,
                            students: sectionStudents,
                            loading: isLoading,
                            searchQuery: widget.searchQuery,
                            statusFilter: widget.statusFilter,
                            selectedRows: sectionSelected,
                            onSelectionChange: widget.onSelectionChange,
                            onToggleAbsent: widget.onToggleAbsent,
                            onEditStatusPrompt: widget.onEditStatusPrompt,
                            onToggleLunch: widget.onToggleLunch,
                            onSignIn: widget.onSignIn,
                            onSignOut: widget.onSignOut,
                            onBulkMark: widget.onBulkMark,
                            onBulkSignIn: widget.onBulkSignIn,
                            onSave: widget.onSave,
                            onReset: widget.onReset,
                            onOpenNote: widget.onOpenNote,
                            readOnly: widget.readOnly,
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg, {Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, border: border != null ? Border.all(color: border) : null, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final int classId;
  final int sectionId;
  final List<AttendanceStudentEntity> students;
  final bool loading;
  final String searchQuery;
  final String statusFilter;
  final Set<int> selectedRows;
  final void Function(String key, Set<int> ids) onSelectionChange;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onToggleAbsent;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onEditStatusPrompt;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onToggleLunch;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onSignIn;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student) onSignOut;
  final void Function(int classId, int sectionId, String status) onBulkMark;
  final void Function(int classId, int sectionId) onBulkSignIn;
  final void Function(int classId, int sectionId) onSave;
  final void Function(int classId, int sectionId) onReset;
  final void Function(int classId, int sectionId, AttendanceStudentEntity student, String mode) onOpenNote;
  final bool readOnly;

  const _SectionBody({
    required this.classId,
    required this.sectionId,
    required this.students,
    required this.loading,
    required this.searchQuery,
    required this.statusFilter,
    required this.selectedRows,
    required this.onSelectionChange,
    required this.onToggleAbsent,
    required this.onEditStatusPrompt,
    required this.onToggleLunch,
    required this.onSignIn,
    required this.onSignOut,
    required this.onBulkMark,
    required this.onBulkSignIn,
    required this.onSave,
    required this.onReset,
    required this.onOpenNote,
    this.readOnly = false,
  });

  String get _key => '$classId-$sectionId';

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim().toLowerCase();
    final visible = students.where((s) {
      if (q.isNotEmpty && !s.fullName.toLowerCase().contains(q) && !s.rollNo.contains(q)) return false;
      if (statusFilter != 'all' && s.status != statusFilter) return false;
      return true;
    }).toList();

    final signedInCount = students.where((s) => s.signInTime != null && s.signOutTime == null).length;
    final present = students.where((s) => s.status == 'present').length;
    final absent = students.where((s) => s.status == 'absent').length;
    final late = students.where((s) => s.status == 'late').length;
    final attendedPresent = students.where((s) => s.status == 'present' && s.signInTime != null).length;
    final pct = students.isNotEmpty ? (((attendedPresent + late) / students.length) * 100).round().clamp(0, 100) : 0;

    if (loading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: List.generate(4, (i) => Container(margin: const EdgeInsets.only(bottom: 8), height: 40, decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(8))))),
      );
    }
    if (students.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No students found for this section.', style: TextStyle(fontSize: 13, color: Color(0xFF9B9BAD)))));
    }

    void toggleAll(bool checked) {
      onSelectionChange(_key, checked ? visible.map((s) => s.id).toSet() : <int>{});
    }

    void toggleOne(int id, bool checked) {
      final next = Set<int>.of(selectedRows);
      if (checked) {
        next.add(id);
      } else {
        next.remove(id);
      }
      onSelectionChange(_key, next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionInnerBar(present: present, absent: absent, late: late, pct: pct),
        if (!readOnly && selectedRows.isNotEmpty)
          AttendanceBulkActionBar(
            count: selectedRows.length,
            onClear: () => onSelectionChange(_key, <int>{}),
            onMarkAll: (status) => onBulkMark(classId, sectionId, status),
            onSignInAll: () => onBulkSignIn(classId, sectionId),
            onSignOutAll: () {
              for (final s in students.where((s) => selectedRows.contains(s.id) && s.signInTime != null && s.signOutTime == null)) {
                onSignOut(classId, sectionId, s);
              }
            },
          ),
        AttendanceTable(
          students: visible,
          loading: false,
          readOnly: readOnly,
          selectedIds: readOnly ? const {} : selectedRows,
          onSelect: readOnly ? (_, _) {} : toggleOne,
          onSelectAll: readOnly ? (_) {} : toggleAll,
          onToggleAbsent: readOnly ? (_) {} : (s) => onToggleAbsent(classId, sectionId, s),
          onToggleLunch: readOnly ? (_) {} : (s) => onToggleLunch(classId, sectionId, s),
          onSignIn: readOnly ? (_) {} : (s) => onSignIn(classId, sectionId, s),
          onSignOut: readOnly ? (_) {} : (s) => onSignOut(classId, sectionId, s),
          onViewNotes: (s) => onOpenNote(classId, sectionId, s, 'view'),
          onEditStatusPrompt: readOnly ? (_) {} : (s) => onEditStatusPrompt(classId, sectionId, s),
          onEditNote: (s) => onOpenNote(classId, sectionId, s, 'add'),
          onDeleteNote: (s) => onOpenNote(classId, sectionId, s, 'view'),
        ),
        if (readOnly)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF1F1F5)))),
            child: Row(children: [
              _dot(present, 'present', const Color(0xFF0A8C5A)),
              const SizedBox(width: 10),
              _dot(absent, 'absent', const Color(0xFFC2264E)),
              const SizedBox(width: 10),
              _dot(late, 'late', const Color(0xFFB4721B)),
              const Spacer(),
              const Text('Read-only', style: TextStyle(fontSize: 10, color: Color(0xFF9CA0AE), fontStyle: FontStyle.italic)),
            ]),
          )
        else
          _SectionFooter(
            present: present,
            absent: absent,
            late: late,
            total: students.length,
            signedInCount: signedInCount,
            onMarkAllPresent: () => onBulkMark(classId, sectionId, 'present'),
            onSignOutAll: () {
              for (final s in students.where((s) => s.signInTime != null && s.signOutTime == null)) {
                onSignOut(classId, sectionId, s);
              }
            },
            onReset: () => onReset(classId, sectionId),
            onSave: () => onSave(classId, sectionId),
          ),
      ],
    );
  }

  Widget _dot(int count, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count $label', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3A3A4A))),
    ]);
  }
}

class _SectionInnerBar extends StatelessWidget {
  final int present;
  final int absent;
  final int late;
  final int pct;
  const _SectionInnerBar({required this.present, required this.absent, required this.late, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFFF8F6FF), border: Border(bottom: BorderSide(color: Color(0xFFEDEDF5)))),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 6,
        children: [
          // Flattened directly into the outer `Wrap` (not grouped into an
          // inner non-wrapping `Row`) so narrow widths can break between
          // individual dots instead of forcing all three onto one line and
          // overflowing.
          _dot(present, 'present', const Color(0xFF0A8C5A)),
          _dot(absent, 'absent', const Color(0xFFC2264E)),
          _dot(late, 'late', const Color(0xFFB4721B)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 70,
              height: 6,
              child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: (pct / 100).clamp(0.0, 1.0), backgroundColor: const Color(0xFFEDEDF5), color: const Color(0xFF4729F4))),
            ),
            const SizedBox(width: 6),
            Text('$pct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4729F4))),
          ]),
        ],
      ),
    );
  }

  Widget _dot(int count, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count $label', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3A3A4A))),
    ]);
  }
}

class _SectionFooter extends StatefulWidget {
  final int present;
  final int absent;
  final int late;
  final int total;
  final int signedInCount;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onSignOutAll;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const _SectionFooter({
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
    required this.signedInCount,
    required this.onMarkAllPresent,
    required this.onSignOutAll,
    required this.onReset,
    required this.onSave,
  });

  @override
  State<_SectionFooter> createState() => _SectionFooterState();
}

class _SectionFooterState extends State<_SectionFooter> {
  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Attendance?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
        content: const Text('This will discard all unsaved changes for this section and reload from the server.', style: TextStyle(fontSize: 12, color: Color(0xFF6B6B7B))),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(context).pop(false), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2264E), foregroundColor: Colors.white),
            child: const Text('Yes, Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    final allMarked = widget.total > 0 && (widget.present + widget.absent + widget.late) >= widget.total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF1F1F5)))),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Flattened directly into the outer `Wrap` — see
          // `_SectionInnerBar`'s identical fix above for why (an inner
          // non-wrapping `Row` here overflows at narrow widths instead of
          // letting the dots break onto their own line).
          Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _dot(widget.present, 'present', const Color(0xFF0A8C5A)),
            _dot(widget.absent, 'absent', const Color(0xFFC2264E)),
            _dot(widget.late, 'late', const Color(0xFFB4721B)),
          ]),
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Tooltip(
                  message: allMarked ? 'All students already marked' : 'Mark all unmarked students present',
                  child: OutlinedButton(
                    onPressed: allMarked ? null : widget.onMarkAllPresent,
                    style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFE4F6ED), foregroundColor: const Color(0xFF0A8C5A), side: const BorderSide(color: Color(0x330A8C5A)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text(allMarked ? '✓ All Marked' : '✓ All Present'),
                  ),
                ),
                if (widget.signedInCount > 0)
                  OutlinedButton(
                    onPressed: widget.onSignOutAll,
                    style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFF4F4F8), foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text('Sign Out All (${widget.signedInCount})'),
                  ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0A8C5A), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Auto-saving', style: TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
                ]),
                OutlinedButton(
                  onPressed: _confirmReset,
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: widget.onSave,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Save Attendance'),
                ),
              ]),
            ],
          ),
        );
  }

  Widget _dot(int count, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count $label', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3A3A4A))),
    ]);
  }
}
