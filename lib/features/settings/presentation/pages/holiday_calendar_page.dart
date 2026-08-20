import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../administration/presentation/widgets/admin_confirm_dialog.dart';
import '../../domain/entities/holiday_entity.dart';
import '../providers/holiday_calendar_provider.dart';
import '../providers/holiday_calendar_state.dart';
import '../widgets/holiday_row.dart';
import '../widgets/holiday_wizard.dart';
import '../widgets/settings_card.dart';

/// Settings → Holiday Calendar — a 1:1 port of
/// `frontend/components/settings/HolidaysPanel.tsx`: school-wide holidays
/// (with an exclude-for-staff toggle), staff-only holidays (add/edit/delete
/// via a 3-step wizard), and a read-only staff calendar preview.
class HolidayCalendarPage extends ConsumerWidget {
  const HolidayCalendarPage({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, HolidayEntity holiday) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Holiday',
      message: 'Delete "${holiday.name}"?',
    );
    if (!confirmed) return;
    await ref.read(holidayCalendarNotifierProvider.notifier).delete(holiday);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(holidayCalendarNotifierProvider);
    final notifier = ref.read(holidayCalendarNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.load,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(state),
                if (state.error != null) _banner(state.error!, AppColors.dangerRed, AppColors.redSoft, Icons.warning_amber_rounded),
                if (state.success != null) _banner(state.success!, AppColors.successGreen, AppColors.greenSoft, Icons.check_circle),
                if (state.loading) _loading(),
                if (!state.loading) ..._body(context, ref, state, notifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(HolidayCalendarState state) {
    // Title + subtitle get the full screen width; the "N in staff
    // calendar" pill sits on its own line below instead of squeezing the
    // (fairly long) subtitle into a narrower side-column — same fix as
    // Leave Policy's header.
    //
    // Own card — same white/gray-bordered style already used by every
    // other section on this page (the school-wide/staff-only/preview
    // `SettingsCard`s below) — instead of floating text directly on the
    // page background.
    return SettingsCard(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Staff Holiday ', style: AppTextStyles.pageTitle),
              Text('Calendar', style: AppTextStyles.pageTitleAccent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Shares one calendar with Academics > Foundation — a holiday added in either place shows '
            'up in both, blocks exam scheduling, appears on the parent portal, and auto-marks '
            'attendance on that date. Exclude school-wide holidays not applicable to staff, or add '
            'staff-only holidays below.',
            style: AppTextStyles.pageSubtitle,
          ),
          if (!state.loading && state.staffCalendar.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 12, color: AppColors.purpleAccent),
                  const SizedBox(width: 6),
                  Text(
                    '${state.staffCalendar.length} in staff calendar',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.purpleAccent),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _banner(String message, Color fg, Color bg, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.only(top: 28),
      child: Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)),
          SizedBox(width: 10),
          Text('Loading holiday calendar…', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, WidgetRef ref, HolidayCalendarState state, HolidayCalendarNotifier notifier) {
    // Each sub-section is now its own card (was previously just a heading
    // floating loose inside one giant page-level card), and the page's
    // own padding was cut from 16+20 (nested) to a flat 14 — see
    // `SettingsCard` in `settings_card.dart`, shared with School Info and
    // Leave Policy.
    return [
      const SizedBox(height: 14),
      SettingsCard(child: _schoolWideSection(state, notifier)),
      const SizedBox(height: 12),
      SettingsCard(child: _staffOnlySection(context, ref, state, notifier)),
      const SizedBox(height: 12),
      SettingsCard(child: _previewSection(state)),
    ];
  }

  Widget _schoolWideSection(HolidayCalendarState state, HolidayCalendarNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('School-wide holidays', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        const Text('Managed in Academics > Foundation — exclude any not applicable to staff.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        if (state.schoolWideHolidays.isEmpty)
          const Text('No school-wide holidays set yet in Foundation.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          Column(
            children: [
              for (var i = 0; i < state.schoolWideHolidays.length; i++) ...[
                SchoolWideHolidayRow(
                  holiday: state.schoolWideHolidays[i],
                  excluded: notifier.isExcluded(state.schoolWideHolidays[i].id),
                  busy: state.busyId == state.schoolWideHolidays[i].id,
                  onToggle: () => notifier.toggleExclusion(state.schoolWideHolidays[i]),
                ),
                if (i != state.schoolWideHolidays.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }

  Widget _staffOnlySection(BuildContext context, WidgetRef ref, HolidayCalendarState state, HolidayCalendarNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Staff-only holidays', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        const Text('Holidays that apply only to staff, not the school-wide calendar.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        if (!state.wizardOpen && state.staffOnlyHolidays.isEmpty) _emptyStaffOnlyState(notifier),
        if (!state.wizardOpen && state.staffOnlyHolidays.isNotEmpty) ..._staffOnlyList(context, ref, state, notifier),
        if (state.wizardOpen) const HolidayWizard(),
      ],
    );
  }

  Widget _previewSection(HolidayCalendarState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Staff calendar preview', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        const Text('School-wide holidays minus exclusions, plus staff-only holidays — what staff actually see.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 10),
        if (state.staffCalendar.isEmpty)
          const Text('Nothing on the staff calendar yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          Column(
            children: [
              for (final h in state.staffCalendar)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderPrimary))),
                  // Stacked (name, then meta line below) rather than a
                  // Row with a fixed-width trailing Text — the combined
                  // "date range · staff only · restricted" string can run
                  // long enough to overflow a same-line Row at phone
                  // width.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        '${formatHolidayRange(h.date, h.endDate)}'
                        '${h.audience == 'staff_only' ? ' · staff only' : ''}'
                        '${h.isOptional ? ' · restricted' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _emptyStaffOnlyState(HolidayCalendarNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSecondary),
        borderRadius: BorderRadius.circular(14),
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.1,
          colors: [AppColors.purpleTint, AppColors.bgPrimary],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event_available_outlined, size: 19, color: AppColors.purpleAccent),
          ),
          const SizedBox(height: 12),
          const Text('No staff-only holidays yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            "A short guided setup — name, date range, and whether it's opt-in (restricted).",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: notifier.startCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 13),
                SizedBox(width: 6),
                Text('Add Staff-Only Holiday', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _staffOnlyList(BuildContext context, WidgetRef ref, HolidayCalendarState state, HolidayCalendarNotifier notifier) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            for (var i = 0; i < state.staffOnlyHolidays.length; i++) ...[
              StaffOnlyHolidayCard(
                holiday: state.staffOnlyHolidays[i],
                busy: state.busyId == state.staffOnlyHolidays[i].id,
                onEdit: () => notifier.startEdit(state.staffOnlyHolidays[i]),
                onDelete: () => _confirmDelete(context, ref, state.staffOnlyHolidays[i]),
              ),
              if (i != state.staffOnlyHolidays.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ElevatedButton(
          onPressed: notifier.startCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14),
              SizedBox(width: 6),
              Text('Add Another Staff-Only Holiday', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ];
  }
}
