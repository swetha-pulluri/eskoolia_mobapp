import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/models/academic_year.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_stats.dart';
import '../../domain/repositories/student_repository.dart';
import '../providers/student_list_notifier.dart';
import '../providers/student_list_state.dart';
import '../providers/student_providers.dart';

/// "Panel 01 — Smart filters" — mirrors frontend StudentListPanel.tsx's
/// collapsible filters panel exactly: Row 1 (search · academic year · class ·
/// section, stacked below the frontend's own 860px breakpoint — real phones
/// are always under that, so this always renders as a full-width column,
/// same as the reference at mobile widths), Row 2 (status pills + special/
/// medical pills), and a footer (result count, saved presets, Reset all /
/// Apply). Values only take effect when Apply is pressed (`filterApplied`
/// gate), matching the frontend precisely.
class StudentFiltersPanel extends ConsumerWidget {
  const StudentFiltersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentListNotifierProvider);
    final notifier = ref.read(studentListNotifierProvider.notifier);
    final stats = state.stats;

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
          _buildHeader(context, state, notifier),
          if (state.filtersPanelExpanded) ...[
            Container(height: 1, color: AppColors.studentFilterDividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterFields(state, notifier),
                  const SizedBox(height: 10),
                  Container(height: 1, color: AppColors.studentFilterDividerColor),
                  const SizedBox(height: 10),
                  _buildSectionLabel('STATUS'),
                  const SizedBox(height: 6),
                  _buildStatusPills(state, notifier, stats),
                  const SizedBox(height: 10),
                  _buildSectionLabel('SPECIAL & MEDICAL'),
                  const SizedBox(height: 6),
                  _buildSpecialPills(state, notifier),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            _buildFooter(context, state, notifier),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    StudentListState state,
    StudentListNotifier notifier,
  ) {
    final activeTags = _activeFilterTags(state);
    return InkWell(
      onTap: notifier.toggleFiltersPanel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                '01',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.studentPanelNumText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart filters',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.studentPanelTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Filter by status · academic year · class · section · special needs',
                    style: TextStyle(fontSize: 11, color: AppColors.studentPanelDesc),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (activeTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: activeTags),
                  ],
                ],
              ),
            ),
            Icon(
              state.filtersPanelExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.studentPanelDesc,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _activeFilterTags(StudentListState state) {
    if (!state.filtersApplied) return const [];
    final tags = <Widget>[];
    if (state.appliedStatus != StudentStatusFilter.all) {
      tags.add(_tag(_statusLabel(state.appliedStatus), _TagStyle.purple));
    }
    if (state.appliedSpecialNeeds) tags.add(_tag('Special needs', _TagStyle.amber));
    if (state.appliedHasAllergy) tags.add(_tag('Has allergy', _TagStyle.amber));
    if (state.appliedOnMedication) tags.add(_tag('On medication', _TagStyle.amber));
    if (state.appliedClassId != null) {
      final matches = state.classes.where((c) => c.id == state.appliedClassId);
      if (matches.isNotEmpty) tags.add(_tag(matches.first.name, _TagStyle.gray));
    }
    if (state.appliedSearch.isNotEmpty) {
      tags.add(_tag('"${state.appliedSearch}"', _TagStyle.blue));
    }
    return tags;
  }

  Widget _tag(String label, _TagStyle style) {
    final (bg, border, text) = switch (style) {
      _TagStyle.purple => (
          AppColors.studentTagPurpleBg,
          AppColors.studentTagPurpleBorder,
          AppColors.studentTagPurpleText,
        ),
      _TagStyle.blue => (
          AppColors.studentTagBlueBg,
          AppColors.studentTagBlueBorder,
          AppColors.studentTagBlueText,
        ),
      _TagStyle.amber => (
          AppColors.studentTagAmberBg,
          AppColors.studentTagAmberBorder,
          AppColors.studentTagAmberText,
        ),
      _TagStyle.gray => (
          AppColors.studentTagGrayBg,
          AppColors.studentTagGrayBorder,
          AppColors.studentTagGrayText,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: text),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.studentPanelDesc,
      ),
    );
  }

  Widget _buildField({required String label, required Widget field}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  /// Row 1 — mirrors `.sl-filter-row1`: search + academic year + class +
  /// section. The frontend itself stacks these into a full-width column
  /// below 860px (`@media (max-width: 860px) { .sl-filter-row1 { flex-
  /// direction: column } }`) — since every real phone is under that width,
  /// this always renders stacked in practice; the row layout is kept for
  /// wider (tablet) widths so the same widget matches the frontend at every
  /// breakpoint, not just phone-sized ones.
  Widget _buildFilterFields(StudentListState state, StudentListNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final search = _buildField(label: 'SEARCH', field: _buildSearchBox(state, notifier));
        final year = _buildField(label: 'ACADEMIC YEAR', field: _buildYearSelect(state, notifier));
        final klass = _buildField(label: 'CLASS', field: _buildClassSelect(state, notifier));
        final section = _buildField(label: 'SECTION', field: _buildSectionSelect(state, notifier));
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              search,
              const SizedBox(height: 10),
              year,
              const SizedBox(height: 10),
              klass,
              const SizedBox(height: 10),
              section,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: 220, child: search),
            const SizedBox(width: 10),
            Expanded(child: year),
            const SizedBox(width: 10),
            Expanded(child: klass),
            const SizedBox(width: 10),
            Expanded(child: section),
          ],
        );
      },
    );
  }

  Widget _buildSearchBox(StudentListState state, StudentListNotifier notifier) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.studentSearchBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(Icons.search_rounded, size: 16, color: AppColors.studentPanelDesc),
          ),
          Expanded(
            child: TextField(
              onChanged: notifier.updateSearchDraft,
              controller: TextEditingController(text: state.searchDraft)
                ..selection = TextSelection.collapsed(offset: state.searchDraft.length),
              style: const TextStyle(fontSize: 13, color: AppColors.studentSearchText),
              decoration: const InputDecoration(
                hintText: 'Name, admission no, phone…',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.studentPanelDesc),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shared select shell — mirrors `.sl-fsel` (36px tall, 8px radius, 12px
  /// font). Always renders a white popup via [AppDropdown], regardless of
  /// the app's dark global theme.
  Widget _buildFilterSelect<T>({
    required T? value,
    required List<DropdownMenuItem<T?>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return AppDropdown<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      height: 36,
      fontSize: 12,
      textColor: AppColors.studentSelectText,
      borderColor: AppColors.studentSearchBorder,
      iconColor: AppColors.studentPanelDesc,
    );
  }

  Widget _buildYearSelect(StudentListState state, StudentListNotifier notifier) {
    return _buildFilterSelect<int>(
      value: state.academicYearIdDraft,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All years', style: TextStyle(fontSize: 12, color: AppColors.studentSelectText)),
        ),
        for (final AcademicYear y in state.academicYears)
          DropdownMenuItem<int?>(
            value: y.id,
            child: Text(y.name, style: const TextStyle(fontSize: 12, color: AppColors.studentSelectText)),
          ),
      ],
      onChanged: notifier.updateAcademicYearDraft,
    );
  }

  Widget _buildClassSelect(StudentListState state, StudentListNotifier notifier) {
    return _buildFilterSelect<int>(
      value: state.classIdFilterDraft,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All classes', style: TextStyle(fontSize: 12, color: AppColors.studentSelectText)),
        ),
        for (final SchoolClass c in state.classes)
          DropdownMenuItem<int?>(
            value: c.id,
            child: Text(
              c.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.studentSelectText),
            ),
          ),
      ],
      onChanged: notifier.updateClassFilterDraft,
    );
  }

  Widget _buildSectionSelect(StudentListState state, StudentListNotifier notifier) {
    final matches = state.classes.where((c) => c.id == state.classIdFilterDraft);
    final selectedClass = matches.isEmpty ? null : matches.first;
    final sections = selectedClass?.sections ?? const <SectionData>[];
    final disabled = selectedClass == null || sections.isEmpty;
    final placeholder = selectedClass == null ? 'Select a class first' : 'All sections';
    return _buildFilterSelect<int>(
      value: disabled ? null : state.sectionIdFilterDraft,
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(placeholder, style: const TextStyle(fontSize: 12, color: AppColors.studentSelectText)),
        ),
        for (final SectionData s in sections)
          DropdownMenuItem<int?>(
            value: s.id,
            child: Text('Section ${s.name}', style: const TextStyle(fontSize: 12, color: AppColors.studentSelectText)),
          ),
      ],
      onChanged: disabled ? null : notifier.updateSectionFilterDraft,
    );
  }

  Widget _buildStatusPills(
    StudentListState state,
    StudentListNotifier notifier,
    StudentStats? stats,
  ) {
    final options = <(StudentStatusFilter, String, int?)>[
      (StudentStatusFilter.all, 'All', stats?.totalCount),
      (StudentStatusFilter.active, 'Active', stats?.activeCount),
      (StudentStatusFilter.inactive, 'Inactive', stats?.inactiveCount),
      (StudentStatusFilter.newThisMonth, 'New', stats?.newCount),
      (StudentStatusFilter.docsPending, 'Docs pending', stats?.docsPendingCount),
      (StudentStatusFilter.archived, 'Archived', stats?.archivedCount),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (filter, label, count) = opt;
        final isOn = state.statusDraft == filter;
        return _Pill(
          label: label,
          count: count,
          isOn: isOn,
          onTap: () => notifier.updateStatusDraft(filter),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialPills(StudentListState state, StudentListNotifier notifier) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(
          label: 'Special needs',
          isOn: state.specialNeedsDraft,
          isAmber: true,
          onTap: notifier.toggleSpecialNeedsDraft,
        ),
        _Pill(
          label: 'Has allergy',
          isOn: state.hasAllergyDraft,
          isAmber: true,
          onTap: notifier.toggleHasAllergyDraft,
        ),
        _Pill(
          label: 'On medication',
          isOn: state.onMedicationDraft,
          isAmber: true,
          onTap: notifier.toggleOnMedicationDraft,
        ),
      ],
    );
  }

  List<Widget> _presetChips(StudentListNotifier notifier) {
    return [
      _PresetChip(
        label: 'All active',
        onTap: () => notifier.applyPreset(status: StudentStatusFilter.active),
      ),
      _PresetChip(
        label: 'Special needs',
        onTap: () => notifier.applyPreset(specialNeeds: true),
      ),
      _PresetChip(
        label: 'Docs pending',
        onTap: () => notifier.applyPreset(status: StudentStatusFilter.docsPending),
      ),
      _PresetChip(
        label: '+ Save current',
        isDashed: true,
        onTap: () {}, // Saving custom presets isn't implemented in this mock/UI-only pass.
      ),
    ];
  }

  /// Mirrors `.sl-filter-foot` — result count (left) plus saved presets and
  /// Reset all / Apply, on a tinted `#fafbff` footer strip.
  Widget _buildFooter(BuildContext context, StudentListState state, StudentListNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.studentFilterFootBg,
        border: const Border(top: BorderSide(color: AppColors.studentFilterDividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterCountText(state),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              const Text(
                'SAVED PRESETS:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF9A9DB4),
                ),
              ),
              ..._presetChips(notifier),
            ],
          ),
          const SizedBox(height: 10),
          _buildActions(context, notifier),
        ],
      ),
    );
  }

  Widget _buildFilterCountText(StudentListState state) {
    if (!state.filtersApplied) {
      return const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Click ', style: TextStyle(fontSize: 11, color: Color(0xFF9A9DB4))),
            TextSpan(
              text: 'Apply',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.studentListBrand),
            ),
            TextSpan(text: ' to load students', style: TextStyle(fontSize: 11, color: Color(0xFF9A9DB4))),
          ],
        ),
      );
    }
    final count = state.sectionTotalCount;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Showing ', style: TextStyle(fontSize: 11, color: AppColors.studentPanelDesc)),
          TextSpan(
            text: '$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.studentPanelTitle),
          ),
          TextSpan(
            text: count == 1 ? ' student' : ' students',
            style: const TextStyle(fontSize: 11, color: AppColors.studentPanelDesc),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, StudentListNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: notifier.resetFilters,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.studentListMuted,
              side: const BorderSide(color: AppColors.studentSearchBorder),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reset all', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: notifier.applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.studentListBrand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  String _statusLabel(StudentStatusFilter filter) {
    switch (filter) {
      case StudentStatusFilter.all:
        return 'All';
      case StudentStatusFilter.active:
        return 'Active';
      case StudentStatusFilter.inactive:
        return 'Inactive';
      case StudentStatusFilter.newThisMonth:
        return 'New';
      case StudentStatusFilter.docsPending:
        return 'Docs pending';
      case StudentStatusFilter.archived:
        return 'Archived';
    }
  }
}

enum _TagStyle { purple, blue, amber, gray }

class _Pill extends StatelessWidget {
  final String label;
  final int? count;
  final bool isOn;
  final bool isAmber;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    this.count,
    required this.isOn,
    this.isAmber = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color text;
    final Color countBg;
    final Color countText;
    if (isOn && isAmber) {
      bg = AppColors.studentPillOnAmberBg;
      border = AppColors.studentPillOnAmberBorder;
      text = AppColors.studentPillOnAmberText;
      countBg = AppColors.studentPillOnAmberText.withValues(alpha: 0.15);
      countText = AppColors.studentPillOnAmberText;
    } else if (isOn) {
      bg = AppColors.studentListBrand;
      border = AppColors.studentListBrand;
      text = Colors.white;
      countBg = Colors.white.withValues(alpha: 0.22);
      countText = Colors.white;
    } else {
      bg = AppColors.studentPillBg;
      border = AppColors.studentPillBorder;
      text = AppColors.studentPillText;
      countBg = AppColors.studentPillCountBg;
      countText = const Color(0xFF3E4052);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        // No `alignment` here: Container + alignment + a Wrap's bounded
        // (but not infinite) width constraints makes Container EXPAND to
        // fill the available width instead of shrink-wrapping its child —
        // that was the real cause of pills rendering full-width instead of
        // hugging their content. Row's own default centering is enough.
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: text,
                fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: countBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: countText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDashed;

  const _PresetChip({required this.label, required this.onTap, this.isDashed = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        // See _Pill for why `alignment` is deliberately omitted here.
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDashed ? Colors.white : AppColors.studentPanelNumBg,
          border: Border.all(
            color: isDashed ? AppColors.studentListBrand : const Color(0xFFAFA9EC),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDashed ? AppColors.studentListBrand : AppColors.studentPanelNumText,
          ),
        ),
      ),
    );
  }
}
