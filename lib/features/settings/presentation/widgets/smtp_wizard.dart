import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/smtp_settings_provider.dart';
import '../providers/smtp_settings_state.dart';
import 'smtp_fields.dart';
import 'smtp_stat_tile.dart';
import 'smtp_step_indicator.dart';

const int _stepCount = 5;

String _capitalize(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

/// The Basics → Authentication → Sender Identity → Delivery → Test & Review
/// wizard — mirrors `SmtpWizard` in `SmtpSettingsPanel.tsx`.
class SmtpWizard extends ConsumerWidget {
  const SmtpWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smtpSettingsNotifierProvider);
    final notifier = ref.read(smtpSettingsNotifierProvider.notifier);
    final draft = state.draft;
    final hasBasics = ((draft['name'] as String?) ?? '').trim().isNotEmpty && ((draft['host'] as String?) ?? '').trim().isNotEmpty;
    final canGoNext = state.step == 0 ? hasBasics : true;
    bool canJumpTo(int target) => state.isEditing || target == 0 || hasBasics;
    final isLastStep = state.step == _stepCount - 1;

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
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SmtpStepIndicator(currentStep: state.step, canJumpTo: canJumpTo, onStepTap: notifier.setStep),
          ),
          if (state.step == 0) _basicsStep(draft, notifier),
          if (state.step == 1) _authenticationStep(draft, state.isEditing, notifier),
          if (state.step == 2) _senderIdentityStep(draft, notifier),
          if (state.step == 3) _deliveryStep(draft, notifier),
          if (isLastStep) _testAndReviewStep(context, ref, draft, state, notifier),
          const SizedBox(height: 22),
          _footer(state, notifier, canGoNext, isLastStep),
        ],
      ),
    );
  }

  Widget _grid(List<Widget> fields) {
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

  Widget _basicsStep(Map<String, dynamic> draft, SmtpSettingsNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _grid([
        SmtpField(
          label: 'Config Name',
          value: (draft['name'] as String?) ?? '',
          autofocus: true,
          onChanged: (v) => notifier.setDraftField('name', v),
        ),
        SmtpSelectField(
          label: 'Type',
          value: (draft['smtp_type'] as String?) ?? 'server',
          options: const [MapEntry('server', 'Server'), MapEntry('local', 'Local')],
          onChanged: (v) => notifier.setDraftField('smtp_type', v),
        ),
        SmtpField(
          label: 'Host',
          value: (draft['host'] as String?) ?? '',
          onChanged: (v) => notifier.setDraftField('host', v),
        ),
        SmtpField(
          label: 'Port',
          value: '${(draft['port'] as num?)?.toInt() ?? 587}',
          isNumber: true,
          onChanged: (v) => notifier.setDraftField('port', int.tryParse(v) ?? 587),
        ),
      ]),
    );
  }

  Widget _authenticationStep(Map<String, dynamic> draft, bool isEditing, SmtpSettingsNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grid([
            SmtpField(
              label: 'Username',
              value: (draft['username'] as String?) ?? '',
              onChanged: (v) => notifier.setDraftField('username', v),
            ),
            SmtpPasswordField(
              value: (draft['password'] as String?) ?? '',
              hint: isEditing ? '(leave blank to keep current)' : null,
              onChanged: (v) => notifier.setDraftField('password', v),
            ),
          ]),
          const SizedBox(height: 18),
          SmtpCheckboxField(
            label: 'Use TLS',
            value: (draft['use_tls'] as bool?) ?? true,
            onChanged: (v) => notifier.setDraftField('use_tls', v),
          ),
        ],
      ),
    );
  }

  Widget _senderIdentityStep(Map<String, dynamic> draft, SmtpSettingsNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _grid([
        SmtpField(
          label: 'From Email',
          value: (draft['from_email'] as String?) ?? '',
          onChanged: (v) => notifier.setDraftField('from_email', v),
        ),
        SmtpField(
          label: 'BCC Email',
          value: (draft['bcc_email'] as String?) ?? '',
          onChanged: (v) => notifier.setDraftField('bcc_email', v),
        ),
        SmtpField(
          label: 'Sender Name',
          value: (draft['sender_name'] as String?) ?? '',
          onChanged: (v) => notifier.setDraftField('sender_name', v),
        ),
      ]),
    );
  }

  Widget _deliveryStep(Map<String, dynamic> draft, SmtpSettingsNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _grid([
        SmtpSelectField(
          label: 'Priority',
          value: (draft['priority'] as String?) ?? 'normal',
          options: const [MapEntry('normal', 'Normal'), MapEntry('high', 'High'), MapEntry('low', 'Low')],
          onChanged: (v) => notifier.setDraftField('priority', v),
        ),
        SmtpSelectField(
          label: 'Receiver Email Type',
          value: (draft['receiver_email_type'] as String?) ?? 'email_id',
          options: const [MapEntry('email_id', 'Official Email ID'), MapEntry('personal_email_id', 'Personal Email ID')],
          onChanged: (v) => notifier.setDraftField('receiver_email_type', v),
        ),
      ]),
    );
  }

  Widget _testAndReviewStep(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> draft,
    SmtpSettingsState state,
    SmtpSettingsNotifier notifier,
  ) {
    final name = (draft['name'] as String?) ?? '';
    final host = (draft['host'] as String?) ?? '';
    final port = (draft['port'] as num?)?.toInt() ?? 587;
    final useTls = (draft['use_tls'] as bool?) ?? true;
    final senderName = (draft['sender_name'] as String?) ?? '';
    final fromEmail = (draft['from_email'] as String?) ?? '';
    final priority = (draft['priority'] as String?) ?? 'normal';

    final tiles = [
      SmtpStatTile(icon: Icons.verified_outlined, tone: SmtpStatTone.purple, label: 'Name', value: name.isEmpty ? '—' : name),
      SmtpStatTile(icon: Icons.dns_outlined, tone: SmtpStatTone.purple, label: 'Connection', value: '${host.isEmpty ? '—' : host}:$port'),
      SmtpStatTile(icon: Icons.key_outlined, tone: SmtpStatTone.blue, label: 'Security', value: useTls ? 'TLS' : 'None'),
      SmtpStatTile(icon: Icons.mail_outline, tone: SmtpStatTone.rose, label: 'Sender', value: senderName.isNotEmpty ? senderName : (fromEmail.isNotEmpty ? fromEmail : '—')),
      SmtpStatTile(icon: Icons.send_outlined, tone: SmtpStatTone.amber, label: 'Priority', value: _capitalize(priority)),
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
              Expanded(
                child: Text(
                  'Review, and optionally send a test email before saving:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < tiles.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 10 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: 10),
                  Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    onChanged: notifier.setTestEmail,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Send test to (default: you)',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                      filled: true,
                      fillColor: AppColors.bgPrimary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSecondary)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSecondary)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.purpleAccent)),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: state.testSending ? null : notifier.sendTestEmail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purpleAccent,
                    side: const BorderSide(color: AppColors.purpleAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    state.testSending ? 'Sending…' : 'Send Test Email',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(SmtpSettingsState state, SmtpSettingsNotifier notifier, bool canGoNext, bool isLastStep) {
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
                              state.isEditing ? 'Save Changes' : 'Create Config',
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

  Future<void> _submit(SmtpSettingsNotifier notifier) async {
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
