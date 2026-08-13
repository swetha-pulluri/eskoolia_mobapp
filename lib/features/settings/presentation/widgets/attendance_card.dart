import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../administration/presentation/widgets/admin_confirm_dialog.dart';
import '../../domain/entities/attendance_policy_entity.dart';
import '../providers/attendance_rules_provider.dart';
import '../providers/attendance_rules_state.dart';
import 'attendance_stat_tile.dart';
import 'attendance_week_strip.dart';

final _historyDateFormat = DateFormat('MMM d, y · h:mm a');
final _metaDateFormat = DateFormat('MMM d, y, h:mm a');

/// One attendance-policy card in the list — mirrors
/// `AttendanceRulesPanel.tsx`'s per-policy card markup (left accent bar,
/// default/inactive badges, stat grid, weekly-off strip, applies-to chips,
/// expandable history).
class AttendanceCard extends ConsumerWidget {
  final AttendancePolicyEntity policy;

  const AttendanceCard({super.key, required this.policy});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Attendance Policy',
      message: 'Delete "${policy.name}"? This cannot be undone.',
    );
    if (!confirmed) return;
    await ref.read(attendanceRulesNotifierProvider.notifier).delete(policy);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceRulesNotifierProvider);
    final notifier = ref.read(attendanceRulesNotifierProvider.notifier);
    final isBusy = state.busyId == policy.id;
    final historyOpen = state.historyOpenId == policy.id;
    final isTeaching = RegExp('teach', caseSensitive: false).hasMatch(policy.name);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: policy.isDefault
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment(0.4, 0.4),
                colors: [AppColors.purpleTint, AppColors.bgPrimary],
              )
            : null,
        color: policy.isDefault ? null : AppColors.bgPrimary,
        border: Border.all(color: policy.isDefault ? AppColors.purpleSoft : AppColors.borderPrimary),
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
            child: Container(color: policy.isDefault ? AppColors.purpleAccent : AppColors.borderSecondary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 16, 12),
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
                            decoration: BoxDecoration(
                              color: policy.isDefault ? AppColors.purpleAccent : AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              isTeaching ? Icons.school_outlined : Icons.groups_2_outlined,
                              size: 15,
                              color: policy.isDefault ? Colors.white : AppColors.textSecondary,
                            ),
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
                                    if (policy.isDefault) _defaultBadge(),
                                    if (!policy.isActive) _inactiveBadge(),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(_metaLine(), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        if (!policy.isDefault)
                          _AttendanceIconButton(
                            icon: Icons.star_border,
                            label: 'Set Default',
                            color: AppColors.successGreen,
                            disabled: isBusy,
                            onTap: () => notifier.makeDefault(policy),
                          ),
                        const SizedBox(width: 6),
                        _AttendanceIconButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: AppColors.purpleAccent,
                          onTap: () => notifier.startEdit(policy),
                        ),
                        const SizedBox(width: 6),
                        _AttendanceIconButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: AppColors.dangerRed,
                          disabled: isBusy,
                          onTap: () => _confirmDelete(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _statGrid(),
                const SizedBox(height: 10),
                AttendanceWeekStrip(policy: policy),
                const SizedBox(height: 10),
                _appliesToRow(),
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

  String _metaLine() {
    final updatedAt = policy.updatedAt;
    final parsed = updatedAt != null ? DateTime.tryParse(updatedAt) : null;
    final dateText = parsed != null ? _metaDateFormat.format(parsed.toLocal()) : '—';
    final byName = policy.updatedByName;
    return byName != null && byName.isNotEmpty ? 'Last updated by $byName on $dateText' : 'Last updated on $dateText';
  }

  Widget _statGrid() {
    final shift = '${_shortTime(policy.shiftStart)}–${_shortTime(policy.shiftEnd)}';
    final overtime = 'after ${policy.otThresholdHours}h · ×${policy.otMultiplierRegular} (×${policy.otMultiplierHoliday} holiday)';
    final lateMarks = policy.lateMarksPerLop == 0
        ? 'Tracking only'
        : '${policy.lateMarksPerLop} = 1 ${policy.lopDeductionUnit == 'half_day' ? 'half-day' : 'full-day'} LOP';

    final tiles = [
      AttendanceStatTile(icon: Icons.access_time, tone: AttendanceStatTone.purple, label: 'Shift', value: shift),
      AttendanceStatTile(icon: Icons.timer_outlined, tone: AttendanceStatTone.blue, label: 'Grace period', value: '${policy.gracePeriodMinutes} min'),
      AttendanceStatTile(icon: Icons.trending_up, tone: AttendanceStatTone.amber, label: 'Overtime', value: overtime),
      AttendanceStatTile(icon: Icons.warning_amber_rounded, tone: AttendanceStatTone.rose, label: 'Late marks', value: lateMarks),
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

  String _shortTime(String value) => value.length >= 5 ? value.substring(0, 5) : value;

  Widget _appliesToRow() {
    if (policy.appliesToRolesDetail.isEmpty) {
      return const Text('All roles (no restriction set)', style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final role in policy.appliesToRolesDetail)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(999)),
            child: Text(role.name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.purpleAccent)),
          ),
      ],
    );
  }

  Widget _historyPanel(AttendanceRulesState state) {
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

Widget _defaultBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(999)),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 9, color: AppColors.successGreen),
        SizedBox(width: 3),
        Text('DEFAULT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.successGreen)),
      ],
    ),
  );
}

Widget _inactiveBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(999)),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block, size: 9, color: AppColors.dangerRed),
        SizedBox(width: 3),
        Text('Inactive', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.dangerRed)),
      ],
    ),
  );
}

class _AttendanceIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _AttendanceIconButton({
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
