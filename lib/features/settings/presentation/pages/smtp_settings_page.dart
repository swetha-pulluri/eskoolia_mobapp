import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/smtp_settings_provider.dart';
import '../providers/smtp_settings_state.dart';
import '../widgets/smtp_card.dart';
import '../widgets/smtp_wizard.dart';

/// Settings → SMTP Settings — a 1:1 port of
/// `frontend/components/settings/SmtpSettingsPanel.tsx`: a card list of mail
/// server configs (only one active at a time) + a 5-step wizard for
/// create/edit, with an inline test-email send in the last step.
class SmtpSettingsPage extends ConsumerWidget {
  const SmtpSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smtpSettingsNotifierProvider);
    final notifier = ref.read(smtpSettingsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.load,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                border: Border.all(color: AppColors.borderPrimary),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x0A0F1222), blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(state),
                  if (state.error != null) _banner(state.error!, AppColors.dangerRed, AppColors.redSoft, Icons.warning_amber_rounded),
                  if (state.success != null) _banner(state.success!, AppColors.successGreen, AppColors.greenSoft, Icons.check_circle),
                  if (state.loading) _loading(),
                  if (!state.loading && !state.wizardOpen && state.configs.isEmpty) _emptyState(notifier),
                  if (!state.loading && !state.wizardOpen && state.configs.isNotEmpty) _list(state, notifier),
                  if (state.wizardOpen) const SmtpWizard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(SmtpSettingsState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('SMTP ', style: AppTextStyles.pageTitle),
                  Text('Settings', style: AppTextStyles.pageTitleAccent),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Configure the mail server used to send messages and emails through the ERP. Only one '
                'config can be active at a time.',
                style: AppTextStyles.pageSubtitle,
              ),
            ],
          ),
        ),
        if (!state.loading && state.configs.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 12, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: AppColors.purpleAccent),
                const SizedBox(width: 6),
                Text(
                  '${state.configs.length} ${state.configs.length == 1 ? 'config' : 'configs'}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.purpleAccent),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _banner(String message, Color fg, Color bg, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
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
          Text('Loading SMTP settings…', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _emptyState(SmtpSettingsNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
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
            decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.dns_outlined, size: 21, color: AppColors.purpleAccent),
          ),
          const SizedBox(height: 14),
          const Text('Set up your first mail server', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'A short guided setup — connection, authentication, sender identity, and delivery options, '
            'with a test send before you commit.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: notifier.startCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14),
                SizedBox(width: 6),
                Text('Start Setup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(SmtpSettingsState state, SmtpSettingsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        for (var i = 0; i < state.configs.length; i++) ...[
          SmtpCard(config: state.configs[i]),
          if (i != state.configs.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
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
              Text('Add Another Config', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
