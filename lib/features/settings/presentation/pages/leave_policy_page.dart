import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/leave_policy_provider.dart';
import '../providers/leave_policy_state.dart';
import '../widgets/carry_forward_section.dart';
import '../widgets/leave_policy_card.dart';
import '../widgets/leave_policy_wizard.dart';
import '../widgets/settings_card.dart';

/// Settings → Leave Policy — a 1:1 port of
/// `frontend/components/settings/LeavePolicyPanel.tsx`: a card list + 9-step
/// wizard for leave-type CRUD, plus the standalone Carry-Forward section.
class LeavePolicyPage extends ConsumerWidget {
  const LeavePolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leavePolicyNotifierProvider);
    final notifier = ref.read(leavePolicyNotifierProvider.notifier);

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
                if (state.error != null)
                  _banner(
                    state.error!,
                    AppColors.dangerRed,
                    AppColors.redSoft,
                    Icons.warning_amber_rounded,
                  ),
                if (state.success != null)
                  _banner(
                    state.success!,
                    AppColors.successGreen,
                    AppColors.greenSoft,
                    Icons.check_circle,
                  ),
                if (state.loading) _loading(),
                if (!state.loading &&
                    !state.wizardOpen &&
                    state.policies.isEmpty)
                  _emptyState(notifier),
                if (!state.loading &&
                    !state.wizardOpen &&
                    state.policies.isNotEmpty)
                  _list(state, notifier),
                if (state.wizardOpen) const LeavePolicyWizard(),
                const SettingsCard(
                  margin: EdgeInsets.only(top: 20),
                  child: CarryForwardSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(LeavePolicyState state) {
    // Title + subtitle now get the full screen width to themselves —
    // previously the "N leave types configured" pill sat beside them in a
    // Row, squeezing the subtitle into a narrower column and forcing it to
    // wrap onto extra lines. The pill now sits on its own line below,
    // where it only takes the width it needs.
    //
    // Own card — same white/gray-bordered style already used by every
    // other section on this page (each `LeavePolicyCard`, the Carry
    // Forward `SettingsCard`) — instead of floating text directly on the
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
              Text('Leave ', style: AppTextStyles.pageTitle),
              Text('Policy', style: AppTextStyles.pageTitleAccent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Create leave types and design their eligibility, carry-forward, and documentation rules. '
            'Per-staff day allocations still happen in HR > Leave.',
            style: AppTextStyles.pageSubtitle,
          ),
          if (!state.loading && state.policies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purpleTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: AppColors.purpleAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${state.policies.length} leave ${state.policies.length == 1 ? 'type' : 'types'} configured',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purpleAccent,
                    ),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.only(top: 28),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading leave policies…',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(LeavePolicyNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.purpleTint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.date_range_outlined,
              size: 21,
              color: AppColors.purpleAccent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Set up your first leave type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A short guided setup — days per year, carry-forward, eligibility, documentation and more. '
            'Staff will see these rules once saved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: notifier.startCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14),
                SizedBox(width: 6),
                Text(
                  'Start Setup',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(LeavePolicyState state, LeavePolicyNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        for (var i = 0; i < state.policies.length; i++) ...[
          LeavePolicyCard(policy: state.policies[i]),
          if (i != state.policies.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: notifier.startCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14),
              SizedBox(width: 6),
              Text(
                'Add Another Leave Type',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
