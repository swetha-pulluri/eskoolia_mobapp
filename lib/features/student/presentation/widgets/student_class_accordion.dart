import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_data.dart';
import '../pages/student_profile_page.dart';
import '../providers/student_list_notifier.dart';
import '../providers/student_list_state.dart';
import '../providers/student_providers.dart';
import 'student_archive_reason_dialog.dart';
import 'student_bulk_action_bar.dart';

/// "Panel 02 — Browse & edit by class" — mirrors frontend
/// StudentListPanel.tsx's accordion of classes → sections, each showing a
/// student table with checkboxes, row actions, bulk action bar, and a
/// section-level pager.
///
/// Mobile simplification (disclosed): only one class is expanded at a time
/// (opening another collapses the previous), and within it a section tab
/// bar selects which single section's table is visible — the frontend's
/// own structure ("each open class shows section tabs; each open section
/// shows [table]") already implies one visible table per class, so this
/// keeps that same shape without stacking several open tables on a phone.
class StudentClassAccordion extends ConsumerWidget {
  const StudentClassAccordion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentListNotifierProvider);
    final notifier = ref.read(studentListNotifierProvider.notifier);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.studentListLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state, notifier),
          if (state.browsePanelExpanded) ...[
            Container(height: 1, color: AppColors.studentListLine),
            if (state.loadingClasses)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.classesError != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      state.classesError!,
                      style: const TextStyle(fontSize: 13, color: AppColors.studentListMuted),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: notifier.refresh, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_visibleClasses(state).isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No classes match the current filters.',
                    style: TextStyle(fontSize: 13, color: AppColors.studentPanelDesc),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final schoolClass in _visibleClasses(state))
                      _buildClassRow(context, state, notifier, schoolClass),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Mirrors the frontend's `eligibleClasses` — narrows the rendered class
  /// list to the applied Class filter, if any.
  List<SchoolClass> _visibleClasses(StudentListState state) {
    if (state.appliedClassId == null) return state.classes;
    return state.classes.where((c) => c.id == state.appliedClassId).toList();
  }

  Widget _buildHeader(StudentListState state, StudentListNotifier notifier) {
    return InkWell(
      onTap: notifier.toggleBrowsePanel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.studentPanelNumBg,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '02',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.studentPanelNumText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse & edit by class',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.studentPanelTitle,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap a class, then a section, to see its roster',
                    style: TextStyle(fontSize: 11, color: AppColors.studentPanelDesc),
                  ),
                ],
              ),
            ),
            Icon(
              state.browsePanelExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.studentPanelDesc,
            ),
          ],
        ),
      ),
    );
  }

  /// Mirrors `.sl-cls-acc`/`.sl-cls-hd` exactly: a bordered card (not a flat
  /// divided list) whose header carries a name, a 5-badge summary row
  /// (students/active/special needs/docs pending/sections), and a compact
  /// progress bar — instead of the previous name-and-count-only row.
  Widget _buildClassRow(
    BuildContext context,
    StudentListState state,
    StudentListNotifier notifier,
    SchoolClass schoolClass,
  ) {
    final isExpanded = state.expandedClassId == schoolClass.id;
    final borderColor = isExpanded ? AppColors.studentClsOpenBorder : AppColors.studentClsBorder;
    // A Border needs a single uniform color to pair with borderRadius —
    // Flutter throws otherwise. The teal "open" left accent is drawn as a
    // Positioned strip inside a Stack (not a Row+stretch: this card sits in
    // an unbounded-height scrolling list, and CrossAxisAlignment.stretch on
    // a Row requires a bounded height to stretch to) instead of a
    // differently-colored border side.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          _buildClassCardBody(context, state, notifier, schoolClass, isExpanded),
          if (isExpanded)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: AppColors.studentClsOpenAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildClassCardBody(
    BuildContext context,
    StudentListState state,
    StudentListNotifier notifier,
    SchoolClass schoolClass,
    bool isExpanded,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
            onTap: () => notifier.toggleClass(schoolClass.id),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isExpanded ? null : AppColors.studentClsHeaderBg,
                gradient: isExpanded
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.studentClsHeaderOpenBgTop,
                          AppColors.studentClsHeaderOpenBgBottom,
                        ],
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                        size: 18,
                        color: isExpanded ? AppColors.studentListBrand : AppColors.studentClsChevron,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schoolClass.displayLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.studentListInk,
                          ),
                        ),
                      ),
                      if (schoolClass.totalStudents > 0) ...[
                        const SizedBox(width: 8),
                        _buildProgressIndicator(schoolClass),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      _classBadge(
                        '${schoolClass.totalStudents} ${schoolClass.totalStudents == 1 ? 'student' : 'students'}',
                        AppColors.studentTagBlueBg,
                        AppColors.studentTagBlueBorder,
                        AppColors.studentTagBlueText,
                      ),
                      _classBadge(
                        '${schoolClass.activeCount} active',
                        AppColors.studentBadgeGreenBg,
                        AppColors.studentBadgeGreenBorder,
                        AppColors.studentBadgeGreenText,
                      ),
                      _classBadge(
                        '${schoolClass.specialNeedsCount} special needs',
                        AppColors.studentTagAmberBg,
                        AppColors.studentTagAmberBorder,
                        AppColors.studentTagAmberText,
                      ),
                      _classBadge(
                        '${schoolClass.docsPendingCount} docs pending',
                        AppColors.studentBadgeRedBg,
                        AppColors.studentBadgeRedBorder,
                        AppColors.studentBadgeRedText,
                      ),
                      _classBadge(
                        // Includes the synthetic "Unassigned" tab once
                        // revealed — mirrors `clsSections.length` in the
                        // frontend, whose `classSectionsMap` already has
                        // that synthetic entry pushed in.
                        () {
                          final count = schoolClass.sections.length +
                              (state.classesWithUnassigned.contains(schoolClass.id) ? 1 : 0);
                          return '$count ${count == 1 ? 'section' : 'sections'}';
                        }(),
                        AppColors.studentTagGrayBg,
                        AppColors.studentTagGrayBorder,
                        AppColors.studentTagGrayText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildSectionContent(context, state, notifier, schoolClass),
        ],
      );
  }

  /// Mirrors `.sl-cls-progress` — a fixed 56×4 track with a filled portion
  /// proportional to active/total, plus a trailing percentage label.
  Widget _buildProgressIndicator(SchoolClass schoolClass) {
    final pct = schoolClass.totalStudents > 0
        ? ((schoolClass.activeCount / schoolClass.totalStudents) * 100).round()
        : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.studentFilterDividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (pct / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.studentListBrand,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$pct%', style: const TextStyle(fontSize: 11, color: AppColors.studentClsProgressText)),
      ],
    );
  }

  /// Mirrors `.sl-badge` — a small rounded, colored summary pill.
  Widget _classBadge(String label, Color bg, Color border, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  Widget _buildSectionContent(
    BuildContext context,
    StudentListState state,
    StudentListNotifier notifier,
    SchoolClass schoolClass,
  ) {
    // Mirrors the frontend's `classSectionsMap`, which appends a synthetic
    // "Unassigned" entry (`{id: UNASSIGNED_SECTION_ID, name: "Unassigned"}`)
    // to any class confirmed (via the background probe in toggleClass) to
    // have section-less students — for EVERY class, not hardcoded to any
    // specific grade.
    final visibleSections = state.appliedSectionId == null
        ? [
            ...schoolClass.sections,
            if (state.classesWithUnassigned.contains(schoolClass.id))
              SectionData.unassigned(
                classId: schoolClass.id,
                studentCount: state.unassignedCounts[schoolClass.id] ?? 0,
              ),
          ]
        : schoolClass.sections.where((s) => s.id == state.appliedSectionId).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: AppColors.studentListSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.studentListLine),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mirrors `.sl-sec-tabs`/`.sl-stab`/`.sl-stab.active`/
                // `.sl-stab-ct` exactly: an underline tab row (not bordered
                // pill buttons) with a count pill directly beside the label
                // (no " · " separator), horizontally scrollable like the
                // frontend's own `overflow-x: auto`.
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFBFF),
                    border: Border(bottom: BorderSide(color: AppColors.studentListLine)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: visibleSections.map((section) {
                        final isActive = state.activeSectionId == section.id;
                        return _SectionTabButton(
                          label: section.displayLabel,
                          count: section.studentCount,
                          isActive: isActive,
                          onTap: () => notifier.selectSectionTab(section.id),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                _buildActiveSectionBody(context, state, notifier, schoolClass),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSectionBody(
    BuildContext context,
    StudentListState state,
    StudentListNotifier notifier,
    SchoolClass schoolClass,
  ) {
    if (state.activeSectionId == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Select a section to view its roster.',
          style: TextStyle(fontSize: 13, color: AppColors.studentPanelDesc),
        ),
      );
    }
    final activeSection = state.activeSectionId == kUnassignedSectionId
        ? SectionData.unassigned(
            classId: schoolClass.id,
            studentCount: state.unassignedCounts[schoolClass.id] ?? 0,
          )
        : schoolClass.sections.where((s) => s.id == state.activeSectionId).firstOrNull;
    final sectionLabel = activeSection?.displayLabel ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mirrors `.sl-sec-bar`: select-all checkbox + selection/count text
        // on the left, the Export button on the right — replaces the
        // previous standalone "Roster" title (which the frontend doesn't
        // have) with the frontend's actual row.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => notifier.toggleSelectAllOnPage(
                    !(state.sectionStudents.isNotEmpty &&
                        state.sectionStudents.every((s) => state.selectedIds.contains(s.id))),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sectionSelectAllCheckbox(state),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _sectionCountLabel(state, schoolClass.displayLabel, sectionLabel),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6F7287)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sectionExportButton(context),
            ],
          ),
        ),
        if (state.selectedIds.isNotEmpty)
          StudentBulkActionBar(
            selectedCount: state.selectedIds.length,
            onActivate: () => notifier.setSelectedActive(true),
            onDeactivate: () => notifier.setSelectedActive(false),
            onExportSelected: () => _showExportToast(context),
            onArchive: () => _confirmArchive(context, notifier, state.selectedIds.toList()),
            onClear: notifier.clearSelection,
          ),
        if (state.sectionLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.sectionError != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  state.sectionError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.studentListMuted),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => notifier.goToSectionPage(state.sectionPage),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (state.sectionStudents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No students match the current filters.',
                style: TextStyle(fontSize: 13, color: AppColors.studentPanelDesc),
              ),
            ),
          )
        else
          _StudentTable(
            students: state.sectionStudents,
            selectedIds: state.selectedIds,
            mutatingIds: state.mutatingIds,
            onSelectRow: notifier.toggleSelectRow,
            onView: (s) => Navigator.of(context)
                .push<bool>(MaterialPageRoute(builder: (_) => StudentProfilePage(student: s)))
                .then((mutated) {
              if (mutated == true) {
                notifier.goToSectionPage(state.sectionPage);
                notifier.refresh();
              }
            }),
            onEdit: (s) => _openEnrollForm(context, notifier, state, editingStudent: s),
            onArchiveOne: (s) => _confirmArchive(context, notifier, [s.id]),
            onToggleStatus: (s) => notifier.setStatusForIds([s.id], isActive: !s.isActive),
          ),
        if (state.sectionStudents.isNotEmpty)
          _buildPagerFooter(context, state, notifier, sectionLabel),
      ],
    );
  }

  /// Mirrors `.sl-tbl-foot`'s count span exactly: `"{start}–{end} of {total}
  /// students in {sectionLabel}"` (frontend: `secStartIdx+1}–{secEndIdx} of
  /// {secTotal} students in {secLabel}`) — not just "... of N students".
  Widget _buildPagerFooter(
    BuildContext context,
    StudentListState state,
    StudentListNotifier notifier,
    String sectionLabel,
  ) {
    const pageSize = 10;
    final start = (state.sectionPage - 1) * pageSize + 1;
    final end = (start + state.sectionStudents.length - 1).clamp(0, state.sectionTotalCount);
    final totalPages = (state.sectionTotalCount / pageSize).ceil().clamp(1, 999);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            '$start–$end of ${state.sectionTotalCount} students${sectionLabel.isEmpty ? '' : ' in $sectionLabel'}',
            style: const TextStyle(fontSize: 12, color: AppColors.studentPagerFootText),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pagerButton(
                icon: Icons.chevron_left_rounded,
                onTap: state.sectionPage > 1
                    ? () => notifier.goToSectionPage(state.sectionPage - 1)
                    : null,
              ),
              for (var p = 1; p <= totalPages; p++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _pagerNumber(
                    page: p,
                    isActive: p == state.sectionPage,
                    onTap: () => notifier.goToSectionPage(p),
                  ),
                ),
              _pagerButton(
                icon: Icons.chevron_right_rounded,
                onTap: state.sectionPage < totalPages
                    ? () => notifier.goToSectionPage(state.sectionPage + 1)
                    : null,
              ),
            ],
          ),
          TextButton(
            onPressed: () => _openEnrollForm(context, notifier, state),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.studentListBrand,
              padding: EdgeInsets.zero,
            ),
            child: const Text('+ Add student', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _pagerButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.studentPagerBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? AppColors.studentPagerText : AppColors.studentListLine,
        ),
      ),
    );
  }

  Widget _pagerNumber({required int page, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.studentListBrand : Colors.white,
          border: Border.all(
            color: isActive ? AppColors.studentListBrand : AppColors.studentPagerBorder,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.studentPagerText,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    StudentListNotifier notifier,
    List<int> ids,
  ) async {
    final reason = await showStudentArchiveReasonDialog(context, count: ids.length);
    if (reason == null) return;
    notifier.archiveIds(ids, reason: reason);
  }

  void _showExportToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export is coming soon.')),
    );
  }

  /// Mirrors `.sl-sec-check input[type=checkbox]` — a select-all/indeterminate
  /// checkbox for every student currently visible in this section's roster.
  Widget _sectionSelectAllCheckbox(StudentListState state) {
    final total = state.sectionStudents.length;
    final allSelected = total > 0 && state.sectionStudents.every((s) => state.selectedIds.contains(s.id));
    final someSelected = !allSelected && state.sectionStudents.any((s) => state.selectedIds.contains(s.id));
    return SizedBox(
      width: 16,
      height: 16,
      child: Checkbox(
        value: allSelected,
        tristate: true,
        onChanged: null,
        activeColor: AppColors.studentListBrand,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        // Rendered via the surrounding InkWell's onTap — this Checkbox is
        // display-only here (`someSelected` drives visual indeterminate
        // state, matching the frontend's `el.indeterminate = someSecSelected`).
        fillColor: someSelected ? WidgetStateProperty.all(AppColors.studentListBrand) : null,
        checkColor: Colors.white,
      ),
    );
  }

  /// Mirrors `.sl-sec-count`'s two states exactly: `"{n} of {total} selected"`
  /// when some rows are checked, else `"{total} student(s) in {class} ·
  /// {section}"`.
  String _sectionCountLabel(StudentListState state, String classLabel, String sectionLabel) {
    final total = state.sectionStudents.length;
    final selectedCount = state.selectedIds.length;
    if (selectedCount > 0) {
      return '$selectedCount of $total selected';
    }
    return '$total student${total == 1 ? '' : 's'} in $classLabel · $sectionLabel';
  }

  /// Mirrors `.sl-sec-export` exactly: 12×12 download icon, "Export" label,
  /// 1px `#dfe0eb` border, 7px radius, 4px/10px padding, 11px `#42455d` text.
  Widget _sectionExportButton(BuildContext context) {
    return InkWell(
      onTap: () => _showExportToast(context),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDFE0EB)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download_outlined, size: 12, color: Color(0xFF42455D)),
            SizedBox(width: 4),
            Text('Export', style: TextStyle(fontSize: 11, color: Color(0xFF42455D))),
          ],
        ),
      ),
    );
  }

  /// Pushes the Enroll form — in edit mode when [editingStudent] is given,
  /// otherwise a fresh enrollment (mirrors the frontend's "+ Add student"
  /// shortcut, which opens the same add form as the page-head button).
  Future<void> _openEnrollForm(
    BuildContext context,
    StudentListNotifier notifier,
    StudentListState state, {
    StudentData? editingStudent,
  }) async {
    final saved = await context.push<bool>('/students/enroll', extra: editingStudent);
    if (saved == true) {
      notifier.refresh();
      if (state.activeSectionId != null) {
        notifier.goToSectionPage(state.sectionPage);
      }
    }
  }
}

/// Mirrors `.sl-stab`/`.sl-stab.active`/`.sl-stab-ct` exactly: an underline
/// tab (2px bottom border when active, no background/box border) with a
/// count pill directly beside the label — not a bordered pill button with
/// a " · count" suffix.
class _SectionTabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _SectionTabButton({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF4F39F6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF4F39F6) : const Color(0xFF6B6E8A),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4F39F6) : const Color(0xFFECE8FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white : const Color(0xFF4F39F6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentTable extends StatelessWidget {
  final List<StudentData> students;
  final Set<int> selectedIds;
  final Set<int> mutatingIds;
  final void Function(int, bool) onSelectRow;
  final void Function(StudentData) onView;
  final void Function(StudentData) onEdit;
  final void Function(StudentData) onArchiveOne;
  final void Function(StudentData) onToggleStatus;

  const _StudentTable({
    required this.students,
    required this.selectedIds,
    required this.mutatingIds,
    required this.onSelectRow,
    required this.onView,
    required this.onEdit,
    required this.onArchiveOne,
    required this.onToggleStatus,
  });

  static const double _checkboxW = 40;
  static const double _studentW = 170;
  // Wide enough to fit a full admission number (e.g. "ADM202691011") without
  // ever needing an ellipsis — the frontend's plain `<td>` has no fixed
  // width/truncation at all.
  static const double _admissionW = 150;
  static const double _guardianW = 150;
  static const double _dobW = 100;
  static const double _rollW = 60;
  static const double _statusW = 100;
  static const double _actionsW = 130; // 4 icons (View/Edit/Message/Archive) × 30px each + margin
  static const double _padH = 10; // matches frontend `th, td { padding: 10px 10px }`
  static const double _padV = 10;

  double get _tableWidth =>
      _checkboxW + _studentW + _admissionW + _guardianW + _dobW + _rollW + _statusW + _actionsW;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderRow(),
            for (final student in students) _buildDataRow(context, student),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.studentTableHeadBg,
        border: Border(bottom: BorderSide(color: AppColors.studentTableBorder)),
      ),
      child: Row(
        children: [
          // Mirrors `<th style={{width:36}}><span className="sr-only">
          // Select</span></th>` exactly — the header row has NO visible
          // checkbox at all (only a screen-reader-only label); the real
          // select-all control lives in the `.sl-sec-bar` above the table.
          const SizedBox(width: _checkboxW),
          _headerCell('Student', _studentW),
          _headerCell('Admission No', _admissionW),
          _headerCell('Guardian', _guardianW),
          _headerCell('DOB', _dobW),
          _headerCell('Roll', _rollW),
          _headerCell('Status', _statusW, align: TextAlign.center),
          _headerCell('Actions', _actionsW, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width, {TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
        child: Text(
          label,
          textAlign: align,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.studentTableHeadText,
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, StudentData student) {
    final isMutating = mutatingIds.contains(student.id);
    return Opacity(
      opacity: isMutating ? 0.5 : 1,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.studentTableBorder)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _checkboxW,
              child: Center(
                child: Checkbox(
                  value: selectedIds.contains(student.id),
                  onChanged: isMutating ? null : (v) => onSelectRow(student.id, v ?? false),
                  activeColor: AppColors.studentListBrand,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            _studentCell(student),
            _admissionCell(student),
            _guardianCell(student),
            _dobCell(student),
            _plainCell(student.rollNo?.isNotEmpty == true ? student.rollNo! : '-', _rollW),
            _statusCell(student, isMutating),
            _actionsCell(context, student, isMutating),
          ],
        ),
      ),
    );
  }

  Widget _studentCell(StudentData student) {
    return SizedBox(
      width: _studentW,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.studentAvatarBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.studentAvatarText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.studentPrimaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${student.gender?.label ?? '-'} · Roll ${student.rollNo?.isNotEmpty == true ? student.rollNo : '-'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.studentSecondaryText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mirrors the frontend's plain `<td>{row.admission_no || "-"}</td>` —
  /// no ellipsis truncation, ever (see `_admissionW`'s comment for why the
  /// column itself is wide enough that this should never even need to wrap).
  Widget _admissionCell(StudentData student) {
    return SizedBox(
      width: _admissionW,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
        child: Text(
          student.admissionNo.isNotEmpty ? student.admissionNo : '-',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: const TextStyle(fontSize: 12.5, color: AppColors.studentListInk),
        ),
      ),
    );
  }

  /// Mirrors `resolveGuardianName`/`resolveGuardianPhone` exactly: "Not
  /// linked" (never a dash) when there's no guardian name, "-" for a missing
  /// phone.
  Widget _guardianCell(StudentData student) {
    return SizedBox(
      width: _guardianW,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              student.guardianName?.isNotEmpty == true ? student.guardianName! : 'Not linked',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.studentPrimaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              student.guardianPhone?.isNotEmpty == true ? student.guardianPhone! : '-',
              style: const TextStyle(fontSize: 12, color: AppColors.studentSecondaryText),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dobCell(StudentData student) {
    final dob = student.dateOfBirth;
    final age = student.ageYears;
    if (dob == null) return _plainCell('-', _dobW);
    return SizedBox(
      width: _dobW,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(dob),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.studentPrimaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (age != null)
              Text(
                '$age ${age == 1 ? 'yr' : 'yrs'}',
                style: const TextStyle(fontSize: 12, color: AppColors.studentSecondaryText),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _plainCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12.5, color: AppColors.studentListInk),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _statusCell(StudentData student, bool isMutating) {
    final (bg, text, label) = _statusVisuals(student);
    return SizedBox(
      width: _statusW,
      child: Center(
        child: InkWell(
          onTap: isMutating || student.isArchived ? null : () => onToggleStatus(student),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text),
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, String) _statusVisuals(StudentData student) {
    if (student.isArchived) {
      return (AppColors.studentStatusArchivedBg, AppColors.studentStatusArchivedText, 'Archived');
    }
    if (student.docsPendingCount > 0) {
      return (AppColors.studentStatusPendingBg, AppColors.studentStatusPendingText, 'Docs pending');
    }
    if (student.isActive) {
      return (AppColors.studentStatusActiveBg, AppColors.studentStatusActiveText, 'Active');
    }
    return (AppColors.studentStatusInactiveBg, AppColors.studentStatusInactiveText, 'Inactive');
  }

  // Order mirrors the frontend's row-actions exactly: View, Edit, Message
  // parent, Archive.
  Widget _actionsCell(BuildContext context, StudentData student, bool isMutating) {
    return SizedBox(
      width: _actionsW,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionIconButton(
            icon: Icons.visibility_outlined,
            tooltip: 'View student profile',
            onTap: () => onView(student),
            hoverBorder: AppColors.studentIconViewHoverBorder,
            hoverBg: AppColors.studentIconViewHoverBg,
            hoverText: AppColors.studentIconViewHoverText,
          ),
          _ActionIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit student',
            onTap: isMutating ? null : () => onEdit(student),
          ),
          // Permanently disabled — mirrors the reference frontend, which
          // also renders this as `disabled` with a "coming soon" tooltip
          // everywhere (row action, bulk bar, profile footer), not a
          // working feature this app should fake with a toast.
          const _ActionIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Message parent (coming soon)',
            onTap: null,
          ),
          _ActionIconButton(
            icon: Icons.archive_outlined,
            tooltip: 'Archive student',
            onTap: isMutating || student.isArchived ? null : () => onArchiveOne(student),
            hoverBorder: AppColors.studentIconArchiveHoverBorder,
            hoverBg: AppColors.studentIconArchiveHoverBg,
            hoverText: AppColors.studentIconArchiveHoverText,
          ),
        ],
      ),
    );
  }
}

/// A single row-action icon button — mirrors `.icon-action` exactly,
/// including its per-action hover colors (view=cyan, message=green,
/// archive=red, edit=brand purple via the shared defaults). Tooltip shows
/// on hover on web/desktop (and on long-press on touch) via [Tooltip];
/// [MouseRegion] separately drives the hover color swap, matching the
/// frontend's `:hover` pseudo-class since Flutter has no CSS equivalent.
class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color hoverBorder;
  final Color hoverBg;
  final Color hoverText;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.hoverBorder = AppColors.studentIconActionHoverBorder,
    this.hoverBg = AppColors.studentIconActionHoverBg,
    this.hoverText = AppColors.studentListBrand,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final hovering = _hovering && !disabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: widget.tooltip,
        child: Opacity(
          opacity: disabled ? 0.35 : 1,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(7),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: hovering ? widget.hoverBg : Colors.white,
                  border: Border.all(
                    color: hovering ? widget.hoverBorder : AppColors.studentIconActionBorder,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  widget.icon,
                  size: 14,
                  color: hovering ? widget.hoverText : AppColors.studentIconActionText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
