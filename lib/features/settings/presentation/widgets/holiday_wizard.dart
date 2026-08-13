import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/holiday_calendar_provider.dart';
import '../providers/holiday_calendar_state.dart';
import 'holiday_calendar_fields.dart';
import 'holiday_row.dart';
import 'holiday_stat_tile.dart';
import 'holiday_step_indicator.dart';
import 'holiday_wizard_help.dart';

const int _stepCount = 3;

/// The Details → Options → Review wizard for a staff-only holiday — mirrors
/// `HolidayWizard` in `HolidaysPanel.tsx`.
class HolidayWizard extends ConsumerWidget {
  const HolidayWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(holidayCalendarNotifierProvider);
    final notifier = ref.read(holidayCalendarNotifierProvider.notifier);
    final draft = state.draft;
    final hasDetails = ((draft['name'] as String?) ?? '').trim().isNotEmpty && ((draft['date'] as String?) ?? '').isNotEmpty;
    final canGoNext = state.step == 0 ? hasDetails : true;
    bool canJumpTo(int target) => state.isEditing || target == 0 || hasDetails;
    final isLastStep = state.step == _stepCount - 1;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1222), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HolidayStepIndicator(currentStep: state.step, canJumpTo: canJumpTo, onStepTap: notifier.setStep),
              ),
              const HolidayWizardHelpButton(),
            ],
          ),
          if (state.step == 0) _detailsStep(draft, notifier),
          if (state.step == 1) _optionsStep(draft, notifier),
          if (isLastStep) _reviewStep(draft),
          const SizedBox(height: 22),
          _footer(state, notifier, canGoNext, isLastStep),
        ],
      ),
    );
  }

  Widget _detailsStep(Map<String, dynamic> draft, HolidayCalendarNotifier notifier) {
    final date = (draft['date'] as String?) ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HolidayField(
            label: 'Name',
            value: (draft['name'] as String?) ?? '',
            autofocus: true,
            onChanged: (v) => notifier.setDraftField('name', v),
          ),
          const SizedBox(height: 16),
          // Stacked rather than side-by-side — "End date (optional — for
          // multi-day breaks)" is too long a label to share half the
          // wizard's width at phone size without wrapping awkwardly.
          HolidayDateField(
            label: 'Start date',
            value: date,
            onChanged: (v) => notifier.setDraftField('date', v),
          ),
          const SizedBox(height: 16),
          HolidayDateField(
            label: 'End date',
            sublabel: '(optional — for multi-day breaks)',
            value: (draft['end_date'] as String?) ?? '',
            minDate: date,
            onChanged: (v) => notifier.setDraftField('end_date', v),
          ),
        ],
      ),
    );
  }

  Widget _optionsStep(Map<String, dynamic> draft, HolidayCalendarNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: HolidayCheckboxField(
        label: "Restricted (staff opt-in) — not counted automatically, staff choose to take it",
        value: (draft['is_optional'] as bool?) ?? false,
        onChanged: (v) => notifier.setDraftField('is_optional', v),
      ),
    );
  }

  Widget _reviewStep(Map<String, dynamic> draft) {
    final name = (draft['name'] as String?) ?? '';
    final date = (draft['date'] as String?) ?? '';
    final endDate = (draft['end_date'] as String?) ?? '';
    final isOptional = (draft['is_optional'] as bool?) ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined, size: 15, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Review before saving:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HolidayStatTile(
                  icon: Icons.event_outlined,
                  tone: HolidayStatTone.purple,
                  label: 'Name',
                  value: name.isEmpty ? '—' : name,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HolidayStatTile(
                  icon: Icons.event_note_outlined,
                  tone: HolidayStatTone.blue,
                  label: 'Dates',
                  value: date.isEmpty ? '—' : formatHolidayRange(date, endDate.isEmpty ? null : endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HolidayStatTile(
            icon: Icons.tune,
            tone: HolidayStatTone.amber,
            label: 'Type',
            value: isOptional ? 'Restricted (opt-in)' : 'Standard',
          ),
        ],
      ),
    );
  }

  Widget _footer(HolidayCalendarState state, HolidayCalendarNotifier notifier, bool canGoNext, bool isLastStep) {
    // Back on its own row above the action buttons — a sibling Wrap could
    // otherwise be offered more width than actually remains next to Back
    // and overflow at phone width (same fix as Leave Policy's footer).
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.step > 0) ...[
            TextButton.icon(
              onPressed: () => notifier.setStep(state.step - 1),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.chevron_left, size: 15),
              label: const Text('Back', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: notifier.closeWizard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderSecondary),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              if (state.isEditing && !isLastStep)
                OutlinedButton(
                  onPressed: state.saving ? null : () => _submit(notifier),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purpleAccent,
                    side: const BorderSide(color: AppColors.purpleSoft),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: state.saving
                      ? _savingRow(AppColors.purpleAccent)
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 15, color: AppColors.purpleAccent),
                            SizedBox(width: 6),
                            Text('Save & Exit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.purpleAccent)),
                          ],
                        ),
                ),
              if (!isLastStep)
                ElevatedButton(
                  onPressed: canGoNext ? () => notifier.setStep(state.step + 1) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 15),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: state.saving ? null : () => _submit(notifier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: state.saving
                      ? _savingRow(Colors.white)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(state.isEditing ? Icons.check_circle : Icons.add, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              state.isEditing ? 'Save Changes' : 'Add Holiday',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit(HolidayCalendarNotifier notifier) async {
    try {
      await notifier.submit();
    } catch (_) {
      // Error already surfaced via state.error.
    }
  }

  Widget _savingRow(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
        const SizedBox(width: 6),
        Text('Saving…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
