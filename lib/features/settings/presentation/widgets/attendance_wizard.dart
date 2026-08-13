import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/attendance_rules_provider.dart';
import '../providers/attendance_rules_state.dart';
import 'attendance_fields.dart';
import 'attendance_stat_tile.dart';
import 'attendance_step_indicator.dart';
import 'attendance_wizard_help.dart';

const List<MapEntry<String, String>> _lopDeductionOptions = [
  MapEntry('full_day', 'Full day'),
  MapEntry('half_day', 'Half day'),
];

const List<MapEntry<String, String>> _notifyWhomOptions = [
  MapEntry('manager_and_hr', 'Manager & HR'),
  MapEntry('hr_only', 'HR only'),
  MapEntry('manager_only', 'Manager only'),
];

const List<String> _weeklyOffLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// The 7-step Basics → ... → Review wizard — mirrors `AttendanceWizard` in
/// `AttendanceRulesPanel.tsx`.
class AttendanceWizard extends ConsumerWidget {
  const AttendanceWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceRulesNotifierProvider);
    final notifier = ref.read(attendanceRulesNotifierProvider.notifier);
    final draft = state.draft;
    final hasName = ((draft['name'] as String?) ?? '').trim().isNotEmpty;
    final canGoNext = state.step == 0 ? hasName : true;
    bool canJumpTo(int target) => state.isEditing || target == 0 || hasName;

    const stepCount = 7;
    final isLastStep = state.step == stepCount - 1;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AttendanceStepIndicator(
                  currentStep: state.step,
                  canJumpTo: canJumpTo,
                  onStepTap: notifier.setStep,
                ),
              ),
              const AttendanceWizardHelpButton(),
            ],
          ),
          switch (state.step) {
            0 => _basicsStep(draft, notifier),
            1 => _appliesToStep(state, notifier),
            2 => _graceBreaksStep(draft, notifier),
            3 => _hoursOvertimeStep(draft, notifier),
            4 => _weeklyOffsStep(draft, notifier),
            5 => _lateMarksStep(draft, notifier),
            _ => _reviewStep(state),
          },
          const SizedBox(height: 22),
          _footer(state, notifier, canGoNext, isLastStep),
        ],
      ),
    );
  }

  Widget _stepPad(Widget child) => Padding(padding: const EdgeInsets.only(top: 18), child: child);

  Widget _pairedGrid(List<Widget> fields) {
    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += 2) {
      final hasSecond = i + 1 < fields.length;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: fields[i]),
          const SizedBox(width: 18),
          Expanded(child: hasSecond ? fields[i + 1] : const SizedBox.shrink()),
        ],
      ));
      if (i + 2 < fields.length) rows.add(const SizedBox(height: 18));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _basicsStep(Map<String, dynamic> draft, AttendanceRulesNotifier notifier) {
    return _stepPad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AttendanceField(
          label: 'Policy Name (e.g. "Teaching Staff", "Non-Teaching Staff")',
          value: (draft['name'] as String?) ?? '',
          autofocus: true,
          onChanged: (v) => notifier.setDraftField('name', v),
        ),
        const SizedBox(height: 18),
        _pairedGrid([
          AttendanceTimeField(
            label: 'Shift Start',
            value: (draft['shift_start'] as String?) ?? '09:00',
            onChanged: (v) => notifier.setDraftField('shift_start', v),
          ),
          AttendanceTimeField(
            label: 'Shift End',
            value: (draft['shift_end'] as String?) ?? '17:00',
            onChanged: (v) => notifier.setDraftField('shift_end', v),
          ),
        ]),
      ],
    ));
  }

  Widget _appliesToStep(AttendanceRulesState state, AttendanceRulesNotifier notifier) {
    final selected = List<int>.from((state.draft['applies_to_roles'] as List?) ?? const <int>[]);
    return _stepPad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Which roles does this policy apply to? Leave empty to apply to all staff who aren't covered by a "
          'more specific policy.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 14),
        if (state.roles.isEmpty)
          const Text('No roles found for this school yet.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in state.roles)
                AttendanceChip(
                  label: role.name,
                  checked: selected.contains(role.id),
                  uncheckedIcon: Icons.groups_2_outlined,
                  onTap: () => notifier.toggleRole(role.id),
                ),
            ],
          ),
      ],
    ));
  }

  Widget _graceBreaksStep(Map<String, dynamic> draft, AttendanceRulesNotifier notifier) {
    int asInt(String key) => (draft[key] as num?)?.toInt() ?? 0;
    return _stepPad(_pairedGrid([
      AttendanceField(
        label: 'Grace period (minutes) — how late staff can arrive without being marked late',
        value: '${asInt('grace_period_minutes')}',
        kind: AttendanceFieldKind.integer,
        onChanged: (v) => notifier.setDraftField('grace_period_minutes', int.tryParse(v) ?? 0),
      ),
      AttendanceField(
        label: 'Missing-punch grace (minutes)',
        value: '${asInt('missing_punch_grace_minutes')}',
        kind: AttendanceFieldKind.integer,
        onChanged: (v) => notifier.setDraftField('missing_punch_grace_minutes', int.tryParse(v) ?? 0),
      ),
      AttendanceField(
        label: 'Break duration (minutes)',
        value: '${asInt('break_duration_minutes')}',
        kind: AttendanceFieldKind.integer,
        onChanged: (v) => notifier.setDraftField('break_duration_minutes', int.tryParse(v) ?? 0),
      ),
      AttendanceField(
        label: 'Early-exit grace (minutes)',
        value: '${asInt('early_exit_grace_minutes')}',
        kind: AttendanceFieldKind.integer,
        onChanged: (v) => notifier.setDraftField('early_exit_grace_minutes', int.tryParse(v) ?? 0),
      ),
    ]));
  }

  Widget _hoursOvertimeStep(Map<String, dynamic> draft, AttendanceRulesNotifier notifier) {
    String asStr(String key, String fallback) => (draft[key] as String?) ?? fallback;
    return _stepPad(_pairedGrid([
      AttendanceField(
        label: 'Min. hours — full day',
        value: asStr('min_hours_full_day', '8.00'),
        kind: AttendanceFieldKind.decimal,
        onChanged: (v) => notifier.setDraftField('min_hours_full_day', v),
      ),
      AttendanceField(
        label: 'Min. hours — half day',
        value: asStr('min_hours_half_day', '4.00'),
        kind: AttendanceFieldKind.decimal,
        onChanged: (v) => notifier.setDraftField('min_hours_half_day', v),
      ),
      AttendanceField(
        label: 'Overtime threshold (hours)',
        value: asStr('ot_threshold_hours', '9.00'),
        kind: AttendanceFieldKind.decimal,
        onChanged: (v) => notifier.setDraftField('ot_threshold_hours', v),
      ),
      AttendanceField(
        label: 'OT multiplier — regular day',
        value: asStr('ot_multiplier_regular', '1.50'),
        kind: AttendanceFieldKind.decimal,
        onChanged: (v) => notifier.setDraftField('ot_multiplier_regular', v),
      ),
      AttendanceField(
        label: 'OT multiplier — holiday',
        value: asStr('ot_multiplier_holiday', '2.00'),
        kind: AttendanceFieldKind.decimal,
        onChanged: (v) => notifier.setDraftField('ot_multiplier_holiday', v),
      ),
    ]));
  }

  Widget _weeklyOffsStep(Map<String, dynamic> draft, AttendanceRulesNotifier notifier) {
    return _stepPad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Which days are weekly off under this policy?', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < attendanceWeeklyOffKeys.length; i++)
              AttendanceChip(
                label: _weeklyOffLabels[i],
                checked: (draft[attendanceWeeklyOffKeys[i]] as bool?) ?? false,
                uncheckedIcon: Icons.event_repeat_outlined,
                onTap: () => notifier.toggleWeeklyOff(attendanceWeeklyOffKeys[i]),
              ),
          ],
        ),
      ],
    ));
  }

  Widget _lateMarksStep(Map<String, dynamic> draft, AttendanceRulesNotifier notifier) {
    final alertsEnabled = (draft['absence_alert_enabled'] as bool?) ?? false;
    return _stepPad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pairedGrid([
          AttendanceField(
            label: 'Late marks per LOP (0 = tracking only)',
            value: '${(draft['late_marks_per_lop'] as num?)?.toInt() ?? 0}',
            kind: AttendanceFieldKind.integer,
            onChanged: (v) => notifier.setDraftField('late_marks_per_lop', int.tryParse(v) ?? 0),
          ),
          AttendanceSelectField(
            label: 'LOP deduction unit',
            value: (draft['lop_deduction_unit'] as String?) ?? 'full_day',
            options: _lopDeductionOptions,
            onChanged: (v) => notifier.setDraftField('lop_deduction_unit', v),
          ),
        ]),
        const SizedBox(height: 18),
        AttendanceCheckboxField(
          label: 'Enable absence alerts',
          icon: Icons.notifications_outlined,
          value: alertsEnabled,
          onChanged: (v) => notifier.setDraftField('absence_alert_enabled', v),
        ),
        if (alertsEnabled) ...[
          const SizedBox(height: 18),
          _pairedGrid([
            AttendanceField(
              label: 'Alert after (days)',
              value: '${(draft['absence_alert_after_days'] as num?)?.toInt() ?? 3}',
              kind: AttendanceFieldKind.integer,
              onChanged: (v) => notifier.setDraftField('absence_alert_after_days', int.tryParse(v) ?? 1),
            ),
            AttendanceSelectField(
              label: 'Notify',
              value: (draft['absence_alert_notify_whom'] as String?) ?? 'manager_and_hr',
              options: _notifyWhomOptions,
              onChanged: (v) => notifier.setDraftField('absence_alert_notify_whom', v),
            ),
          ]),
        ],
      ],
    ));
  }

  Widget _reviewStep(AttendanceRulesState state) {
    final draft = state.draft;
    String asStr(String key, [String fallback = '']) => (draft[key] as String?) ?? fallback;
    int asInt(String key, [int fallback = 0]) => (draft[key] as num?)?.toInt() ?? fallback;
    bool asBool(String key) => (draft[key] as bool?) ?? false;

    final selectedRoleIds = List<int>.from((draft['applies_to_roles'] as List?) ?? const <int>[]);
    final appliesTo = selectedRoleIds.isEmpty
        ? 'All roles'
        : state.roles.where((r) => selectedRoleIds.contains(r.id)).map((r) => r.name).join(', ');

    final offDays = [
      for (var i = 0; i < attendanceWeeklyOffKeys.length; i++)
        if (asBool(attendanceWeeklyOffKeys[i])) _weeklyOffLabels[i],
    ];

    final tiles = [
      AttendanceStatTile(icon: Icons.badge_outlined, tone: AttendanceStatTone.purple, label: 'Name', value: asStr('name').isEmpty ? '—' : asStr('name')),
      AttendanceStatTile(icon: Icons.groups_2_outlined, tone: AttendanceStatTone.purple, label: 'Applies to', value: appliesTo.isEmpty ? 'All roles' : appliesTo),
      AttendanceStatTile(icon: Icons.access_time, tone: AttendanceStatTone.blue, label: 'Shift', value: '${asStr('shift_start', '09:00')}–${asStr('shift_end', '17:00')}'),
      AttendanceStatTile(icon: Icons.timer_outlined, tone: AttendanceStatTone.blue, label: 'Grace period', value: '${asInt('grace_period_minutes', 15)} min'),
      AttendanceStatTile(icon: Icons.free_breakfast_outlined, tone: AttendanceStatTone.amber, label: 'Break', value: '${asInt('break_duration_minutes', 30)} min'),
      AttendanceStatTile(
        icon: Icons.trending_up,
        tone: AttendanceStatTone.amber,
        label: 'Overtime',
        value: 'after ${asStr('ot_threshold_hours', '9.00')}h · ×${asStr('ot_multiplier_regular', '1.50')} (×${asStr('ot_multiplier_holiday', '2.00')} holiday)',
      ),
      AttendanceStatTile(icon: Icons.event_repeat_outlined, tone: AttendanceStatTone.purple, label: 'Weekly off', value: offDays.isEmpty ? 'None' : offDays.join(', ')),
      AttendanceStatTile(
        icon: Icons.warning_amber_rounded,
        tone: AttendanceStatTone.rose,
        label: 'Late marks',
        value: asInt('late_marks_per_lop', 3) == 0
            ? 'Tracking only'
            : '${asInt('late_marks_per_lop', 3)} = 1 ${asStr('lop_deduction_unit', 'full_day') == 'half_day' ? 'half-day' : 'full-day'} LOP',
      ),
      AttendanceStatTile(
        icon: Icons.notifications_outlined,
        tone: AttendanceStatTone.rose,
        label: 'Absence alerts',
        value: asBool('absence_alert_enabled') ? 'after ${asInt('absence_alert_after_days', 3)} days' : 'Off',
      ),
    ];

    return _stepPad(Column(
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
    ));
  }

  Widget _footer(AttendanceRulesState state, AttendanceRulesNotifier notifier, bool canGoNext, bool isLastStep) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          state.step > 0
              ? TextButton.icon(
                  onPressed: () => notifier.setStep(state.step - 1),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  icon: const Icon(Icons.chevron_left, size: 15),
                  label: const Text('Back', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                )
              : const SizedBox.shrink(),
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
                              state.isEditing ? 'Save Changes' : 'Create Policy',
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

  Future<void> _submit(AttendanceRulesNotifier notifier) async {
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
