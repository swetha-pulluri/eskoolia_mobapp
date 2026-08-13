import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../administration/presentation/widgets/admin_data_table.dart';
import '../providers/leave_policy_provider.dart';
import '../providers/leave_policy_state.dart';

/// "Leave Balance Carry-Forward" — mirrors `CarryForwardSection` in
/// `LeavePolicyPanel.tsx`: From/To Year, Preview → the one real table on
/// this whole screen, Run, and a Run History list. Self-contained, reading
/// its own [carryForwardNotifierProvider] rather than being threaded
/// through the page — matches the web's independent component.
class CarryForwardSection extends ConsumerWidget {
  const CarryForwardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(carryForwardNotifierProvider);
    final notifier = ref.read(carryForwardNotifierProvider.notifier);
    final canRun = state.rows != null && state.rows!.isNotEmpty;

    // No outer margin/border/padding here — the caller (`LeavePolicyPage`)
    // now wraps this whole section in its own `SettingsCard`, which
    // already supplies the card boundary.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Balance Carry-Forward', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Roll over unused balance from one year to the next for leave types with carry-forward enabled. '
            'Preview before running.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.dangerRed)),
            ),
          if (state.success != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.success!, style: const TextStyle(fontSize: 13, color: AppColors.successGreen)),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _yearField('From Year', state.fromYear, notifier.setFromYear),
                _yearField('To Year', state.toYear, notifier.setToYear),
                OutlinedButton(
                  onPressed: state.loading ? null : notifier.preview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purpleAccent,
                    side: const BorderSide(color: AppColors.purpleAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(state.loading ? '…' : 'Preview', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (canRun)
                  ElevatedButton(
                    onPressed: state.loading ? null : notifier.run,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(state.loading ? '…' : 'Run Carry-Forward', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          if (state.rows != null) Padding(padding: const EdgeInsets.only(top: 16), child: _previewTable(state)),
          if (state.history.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: _historyList(state)),
        ],
      );
  }

  Widget _yearField(String label, int value, ValueChanged<int> onChanged) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: '$value',
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged(int.tryParse(v) ?? value),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderPrimary)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderPrimary)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.purpleAccent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewTable(CarryForwardState state) {
    final rows = state.rows!;
    if (rows.isEmpty) {
      return Text(
        'No carry-forward-eligible balances found for ${state.fromYear}.',
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }
    return AdminDataTable(
      columns: const [
        AdminColumn('Staff', width: 140),
        AdminColumn('Leave Type', width: 130),
        AdminColumn('Carried Forward', width: 120),
        AdminColumn('Note', width: 170),
      ],
      rows: [
        for (final row in rows)
          [
            Text('${row['staff_name'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            Text('${row['leave_type_name'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            Text('${row['carried_forward'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            Text('${row['skipped_reason'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
      ],
    );
  }

  Widget _historyList(CarryForwardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RUN HISTORY',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.4),
        ),
        const SizedBox(height: 8),
        for (final entry in state.history)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderPrimary))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${entry['from_year']} → ${entry['to_year']} by ${entry['executed_by_name'] ?? '—'}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${entry['total_processed'] ?? 0} processed · ${entry['total_skipped'] ?? 0} skipped · ${entry['total_failed'] ?? 0} failed',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
