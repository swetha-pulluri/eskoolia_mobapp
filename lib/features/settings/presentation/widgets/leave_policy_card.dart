import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../administration/presentation/widgets/admin_confirm_dialog.dart';
import '../../domain/entities/leave_policy_entity.dart';
import '../providers/leave_policy_provider.dart';
import '../providers/leave_policy_state.dart';
import 'leave_policy_stat_tile.dart';
import 'leave_policy_summary.dart';

final _historyDateFormat = DateFormat('MMM d, y · h:mm a');

/// One leave-type card in the list — mirrors `LeavePolicyPanel.tsx`'s
/// per-policy card markup exactly (left accent bar, badges, stat grid,
/// expandable history).
class LeavePolicyCard extends ConsumerWidget {
  final LeavePolicyEntity policy;

  const LeavePolicyCard({super.key, required this.policy});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Leave Type',
      message: 'Delete "${policy.name}"? This cannot be undone.',
    );
    if (!confirmed) return;
    await ref.read(leavePolicyNotifierProvider.notifier).delete(policy);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leavePolicyNotifierProvider);
    final notifier = ref.read(leavePolicyNotifierProvider.notifier);
    final isBusy = state.busyId == policy.id;
    final historyOpen = state.historyOpenId == policy.id;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1222), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: Container(color: policy.isActive ? AppColors.purpleAccent : AppColors.borderSecondary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(9)),
                            child: const Icon(Icons.event_note_outlined, size: 15, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 7,
                                  runSpacing: 4,
                                  children: [
                                    Text(policy.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    if (policy.isBuiltin) _outlinedBadge('Built-in'),
                                    if (!policy.isActive) _inactiveBadge(),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${policy.maxDaysPerYear == 0 ? 'Unlimited' : policy.maxDaysPerYear} days/yr · ${policy.isPaid ? 'Paid' : 'Unpaid'}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        _LeaveIconButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: AppColors.purpleAccent,
                          onTap: () => notifier.startEdit(policy),
                        ),
                        if (!policy.isBuiltin) ...[
                          const SizedBox(width: 6),
                          _LeaveIconButton(
                            icon: Icons.delete_outline,
                            label: 'Delete',
                            color: AppColors.dangerRed,
                            disabled: isBusy,
                            onTap: () => _confirmDelete(context, ref),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _statGrid(state),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => notifier.toggleHistory(policy),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 13, color: AppColors.purpleAccent),
                        const SizedBox(width: 4),
                        Text(
                          historyOpen ? 'Hide history' : 'View history',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purpleAccent),
                        ),
                      ],
                    ),
                  ),
                ),
                if (historyOpen) _historyPanel(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid(LeavePolicyState state) {
    final tiles = [
      LeaveStatTile(
        icon: Icons.event_note_outlined,
        tone: LeaveStatTone.purple,
        label: 'Days / year',
        value: policy.maxDaysPerYear == 0 ? 'Unlimited' : '${policy.maxDaysPerYear}',
      ),
      LeaveStatTile(
        icon: Icons.refresh,
        tone: LeaveStatTone.blue,
        label: 'Carry-forward',
        value: policy.canCarryForward
            ? 'Up to ${policy.maxCarryForwardDays == 0 ? '∞' : policy.maxCarryForwardDays} days'
            : 'Off',
      ),
      LeaveStatTile(
        icon: Icons.people_outline,
        tone: LeaveStatTone.amber,
        label: 'Eligibility',
        value: leaveEligibilitySummary(
          gender: policy.applicableGender,
          departmentIds: policy.applicableDepartments,
          designationIds: policy.applicableDesignations,
          employmentTypes: policy.applicableEmploymentTypes,
          minimumServicePeriod: policy.minimumServicePeriod,
          departments: state.departments,
          designations: state.designations,
        ),
      ),
      LeaveStatTile(
        icon: Icons.description_outlined,
        tone: LeaveStatTone.rose,
        label: 'Documentation',
        value: policy.medicalCertificateRequired
            ? 'Medical cert. after ${policy.medicalCertificateAfterDays}d'
            : policy.attachmentRequired
                ? 'Attachment required'
                : 'None required',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 8 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 8),
                Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _historyPanel(LeavePolicyState state) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 9),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
      child: state.historyLoading
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)),
                SizedBox(width: 6),
                Text('Loading…', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            )
          : state.history.isEmpty
              ? const Text('No history yet.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in state.history)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4, right: 7),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(color: AppColors.purpleAccent, shape: BoxShape.circle),
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  children: [
                                    TextSpan(
                                      text: entry.createdAt != null ? _historyDateFormat.format(entry.createdAt!) : '—',
                                      style: const TextStyle(color: AppColors.textTertiary),
                                    ),
                                    const TextSpan(text: '  —  '),
                                    TextSpan(
                                      text: entry.action,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    TextSpan(text: '  by ${entry.actorName}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

Widget _outlinedBadge(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(border: Border.all(color: AppColors.borderSecondary), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
  );
}

Widget _inactiveBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.block, size: 9, color: AppColors.dangerRed),
        SizedBox(width: 3),
        Text('Inactive', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.dangerRed)),
      ],
    ),
  );
}

class _LeaveIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _LeaveIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            border: Border.all(color: AppColors.borderSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
