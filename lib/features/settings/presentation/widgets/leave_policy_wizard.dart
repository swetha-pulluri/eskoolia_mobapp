import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/leave_policy_choices.dart';
import '../providers/leave_policy_provider.dart';
import '../providers/leave_policy_state.dart';
import 'leave_policy_fields.dart';
import 'leave_policy_stat_tile.dart';
import 'leave_policy_step_indicator.dart';
import 'leave_policy_summary.dart';
import 'leave_policy_wizard_help.dart';

/// The 9-step Identity → ... → Review wizard — mirrors `LeavePolicyWizard`
/// in `LeavePolicyPanel.tsx`.
class LeavePolicyWizard extends ConsumerWidget {
  const LeavePolicyWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leavePolicyNotifierProvider);
    final notifier = ref.read(leavePolicyNotifierProvider.notifier);
    final draft = state.draft;
    final hasName = ((draft['name'] as String?) ?? '').trim().isNotEmpty;
    final canGoNext = state.step == 0 ? hasName : true;
    bool canJumpTo(int target) => state.isEditing || target == 0 || hasName;

    final stepCount = leaveWizardSteps.length;
    final isLastStep = state.step == stepCount - 1;
    final groupStep = (state.step >= 1 && state.step <= leaveFieldGroups.length)
        ? leaveFieldGroups[state.step - 1]
        : null;

    return Container(
      margin: const EdgeInsets.only(top: 16),
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
                child: LeavePolicyStepIndicator(
                  currentStep: state.step,
                  canJumpTo: canJumpTo,
                  onStepTap: notifier.setStep,
                ),
              ),
              const LeavePolicyWizardHelpButton(),
            ],
          ),
          if (state.step == 0) _identityStep(draft, notifier),
          if (groupStep != null) _groupStep(groupStep, state, notifier),
          if (isLastStep) _reviewStep(draft, state),
          const SizedBox(height: 22),
          _footer(state, notifier, canGoNext, isLastStep),
        ],
      ),
    );
  }

  Widget _identityStep(Map<String, dynamic> draft, LeavePolicyNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LeavePolicyField(
            label: 'Leave Type Name (e.g. "Casual Leave", "Earned Leave")',
            value: (draft['name'] as String?) ?? '',
            autofocus: true,
            onChanged: (v) => notifier.setDraftField('name', v),
          ),
          const SizedBox(height: 16),
          LeavePolicyField(
            label: 'Max days/year (0 = unlimited/tracking-only)',
            value: '${(draft['max_days_per_year'] as num?)?.toInt() ?? 0}',
            isNumber: true,
            onChanged: (v) => notifier.setDraftField('max_days_per_year', int.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LeavePolicyCheckboxField(
                  label: 'Paid',
                  value: (draft['is_paid'] as bool?) ?? true,
                  onChanged: (v) => notifier.setDraftField('is_paid', v),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: LeavePolicyCheckboxField(
                  label: 'Active',
                  value: (draft['is_active'] as bool?) ?? true,
                  onChanged: (v) => notifier.setDraftField('is_active', v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupStep(LeaveFieldGroup group, LeavePolicyState state, LeavePolicyNotifier notifier) {
    final draft = state.draft;
    final pairable = <Widget>[];
    final fullWidth = <Widget>[];
    for (final field in group.fields) {
      final widget = _renderField(field, draft, notifier);
      if (field.type == LeaveFieldType.text) {
        fullWidth.add(widget);
      } else {
        pairable.add(widget);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pairable.isNotEmpty) _pairedGrid(pairable),
          for (final w in fullWidth) Padding(padding: const EdgeInsets.only(top: 14), child: w),
          if (group.title == 'Eligibility') _eligibilityPickers(state, notifier),
        ],
      ),
    );
  }

  /// Stacks fields one-per-row, full width — the web's 2-per-row grid left
  /// each field too narrow at phone width (dropdown/select text wrapping,
  /// checkboxes cramped), the same issue fixed for School Info.
  Widget _pairedGrid(List<Widget> fields) {
    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      rows.add(fields[i]);
      if (i != fields.length - 1) rows.add(const SizedBox(height: 14));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _renderField(LeaveFieldSpec field, Map<String, dynamic> draft, LeavePolicyNotifier notifier) {
    switch (field.type) {
      case LeaveFieldType.checkbox:
        return LeavePolicyCheckboxField(
          label: field.label,
          value: (draft[field.key] as bool?) ?? false,
          onChanged: (v) => notifier.setDraftField(field.key, v),
        );
      case LeaveFieldType.select:
        final options = leaveSelectOptions[field.key] ?? const ['all'];
        return LeavePolicySelectField(
          label: field.label,
          value: (draft[field.key] as String?) ?? options.first,
          options: options,
          onChanged: (v) => notifier.setDraftField(field.key, v),
        );
      case LeaveFieldType.text:
        return LeavePolicyField(
          label: field.label,
          value: (draft[field.key] as String?) ?? '',
          multiline: true,
          onChanged: (v) => notifier.setDraftField(field.key, v),
        );
      case LeaveFieldType.number:
        return LeavePolicyField(
          label: field.label,
          value: '${(draft[field.key] as num?)?.toInt() ?? 0}',
          isNumber: true,
          onChanged: (v) => notifier.setDraftField(field.key, int.tryParse(v) ?? 0),
        );
    }
  }

  Widget _eligibilityPickers(LeavePolicyState state, LeavePolicyNotifier notifier) {
    final draft = state.draft;
    final selectedDepts = List<String>.from((draft['applicable_departments'] as List?) ?? const []);
    final selectedDesigs = List<String>.from((draft['applicable_designations'] as List?) ?? const []);
    final selectedEmp = List<String>.from((draft['applicable_employment_types'] as List?) ?? const []);

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pickerGroup(
            'Applicable departments (none checked = all)',
            state.departments.isEmpty
                ? const [Text('No departments set up in HR yet.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))]
                : [
                    for (final d in state.departments)
                      LeavePolicyPill(
                        label: d.name,
                        checked: selectedDepts.contains(d.id.toString()),
                        onTap: () => notifier.toggleListValue('applicable_departments', d.id.toString()),
                      ),
                  ],
          ),
          const SizedBox(height: 14),
          _pickerGroup(
            'Applicable designations (none checked = all)',
            state.designations.isEmpty
                ? const [Text('No designations set up in HR yet.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))]
                : [
                    for (final d in state.designations)
                      LeavePolicyPill(
                        label: d.name,
                        checked: selectedDesigs.contains(d.id.toString()),
                        onTap: () => notifier.toggleListValue('applicable_designations', d.id.toString()),
                      ),
                  ],
          ),
          const SizedBox(height: 14),
          _pickerGroup('Applicable employment types (none checked = all)', [
            for (final t in employmentTypeOptions)
              LeavePolicyPill(
                label: t.label,
                checked: selectedEmp.contains(t.value),
                onTap: () => notifier.toggleListValue('applicable_employment_types', t.value),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _pickerGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }

  Widget _reviewStep(Map<String, dynamic> draft, LeavePolicyState state) {
    int asInt(String key) => (draft[key] as num?)?.toInt() ?? 0;
    bool asBool(String key) => (draft[key] as bool?) ?? false;
    String asStr(String key) => (draft[key] as String?) ?? '';

    final tiles = [
      LeaveStatTile(
        icon: Icons.verified_outlined,
        tone: LeaveStatTone.purple,
        label: 'Name',
        value: asStr('name').isEmpty ? '—' : asStr('name'),
      ),
      LeaveStatTile(
        icon: Icons.event_note_outlined,
        tone: LeaveStatTone.purple,
        label: 'Days / year',
        value: asInt('max_days_per_year') == 0 ? 'Unlimited' : '${asInt('max_days_per_year')}',
      ),
      LeaveStatTile(
        icon: Icons.fact_check_outlined,
        tone: LeaveStatTone.purple,
        label: 'Paid / Active',
        value: '${asBool('is_paid') ? 'Paid' : 'Unpaid'} · ${asBool('is_active') ? 'Active' : 'Inactive'}',
      ),
      LeaveStatTile(
        icon: Icons.refresh,
        tone: LeaveStatTone.blue,
        label: 'Carry-forward',
        value: asBool('can_carry_forward')
            ? 'Up to ${asInt('max_carry_forward_days') == 0 ? '∞' : asInt('max_carry_forward_days')} days (${asStr('carry_forward_mode')})'
            : 'Off',
      ),
      LeaveStatTile(
        icon: Icons.date_range_outlined,
        tone: LeaveStatTone.blue,
        label: 'Duration limits',
        value: '${asInt('maximum_leave_duration') == 0 ? 'No' : asInt('maximum_leave_duration')} max · ${asBool('allow_half_day') ? 'half-day ok' : 'no half-day'}',
      ),
      LeaveStatTile(
        icon: Icons.people_outline,
        tone: LeaveStatTone.amber,
        label: 'Eligibility',
        value: leaveEligibilitySummary(
          gender: asStr('applicable_gender').isEmpty ? 'all' : asStr('applicable_gender'),
          departmentIds: List<String>.from((draft['applicable_departments'] as List?) ?? const []),
          designationIds: List<String>.from((draft['applicable_designations'] as List?) ?? const []),
          employmentTypes: List<String>.from((draft['applicable_employment_types'] as List?) ?? const []),
          minimumServicePeriod: asInt('minimum_service_period'),
          departments: state.departments,
          designations: state.designations,
        ),
      ),
      LeaveStatTile(
        icon: Icons.description_outlined,
        tone: LeaveStatTone.rose,
        label: 'Documentation',
        value: asBool('medical_certificate_required')
            ? 'Medical cert. after ${asInt('medical_certificate_after_days')}d'
            : asBool('attachment_required')
                ? 'Attachment required'
                : 'None required',
      ),
      LeaveStatTile(
        icon: Icons.event_busy_outlined,
        tone: LeaveStatTone.purple,
        label: 'Holidays/week-offs',
        value: '${asBool('count_holidays_as_leave') ? 'Holidays count' : 'Holidays excluded'} · ${asBool('count_weekoffs_as_leave') ? 'Week-offs count' : 'Week-offs excluded'}',
      ),
      LeaveStatTile(
        icon: Icons.balance_outlined,
        tone: LeaveStatTone.rose,
        label: 'Balance',
        value: asBool('allow_negative_balance')
            ? 'Negative allowed'
            : asBool('convert_to_lop')
                ? 'Converts to LOP'
                : 'Standard',
      ),
    ];

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
          for (var i = 0; i < tiles.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 10 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: 10),
                  Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer(LeavePolicyState state, LeavePolicyNotifier notifier, bool canGoNext, bool isLastStep) {
    // Back sits on its own row above the action buttons rather than
    // sharing a Row with them — with up to 3 buttons ("Cancel", "Save &
    // Exit", "Create Leave Type"), a sibling Wrap could be offered more
    // width than actually remained next to Back and overflow at phone
    // width, even though the Wrap's own children wrap safely.
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
                              state.isEditing ? 'Save Changes' : 'Create Leave Type',
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

  Future<void> _submit(LeavePolicyNotifier notifier) async {
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
