import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../administration/presentation/widgets/admin_confirm_dialog.dart';
import '../../domain/entities/smtp_config_entity.dart';
import '../providers/smtp_settings_provider.dart';
import '../providers/smtp_settings_state.dart';
import 'smtp_stat_tile.dart';

final _historyDateFormat = DateFormat('MMM d, y · h:mm a');

String _capitalize(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

/// One SMTP config card — mirrors `SmtpSettingsPanel.tsx`'s per-config card
/// markup: accent bar + purple gradient when active, Server icon avatar,
/// "Active" star pill, stat grid, expandable audit history, Activate/Edit/
/// Delete icon-buttons.
class SmtpCard extends ConsumerWidget {
  final SmtpConfigEntity config;

  const SmtpCard({super.key, required this.config});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete SMTP Config',
      message: 'Delete "${config.name}"?',
    );
    if (!confirmed) return;
    await ref.read(smtpSettingsNotifierProvider.notifier).delete(config);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smtpSettingsNotifierProvider);
    final notifier = ref.read(smtpSettingsNotifierProvider.notifier);
    final isBusy = state.busyId == config.id;
    final historyOpen = state.historyOpenId == config.id;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: config.isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.purpleTint, AppColors.bgPrimary],
                stops: const [0, 0.45],
              )
            : null,
        color: config.isActive ? null : AppColors.bgPrimary,
        border: Border.all(color: config.isActive ? AppColors.purpleSoft : AppColors.borderPrimary),
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
            child: Container(color: config.isActive ? AppColors.purpleAccent : AppColors.borderSecondary),
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
                              color: config.isActive ? AppColors.purpleAccent : AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(Icons.dns_outlined, size: 15, color: config.isActive ? Colors.white : AppColors.textSecondary),
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
                                    Text(config.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    if (config.isActive) _activeBadge(),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${config.host}:${config.port} · ${config.fromEmail}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                  overflow: TextOverflow.ellipsis,
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
                        if (!config.isActive)
                          _IconButton(
                            icon: Icons.star_outline,
                            label: 'Activate',
                            color: AppColors.successGreen,
                            disabled: isBusy,
                            onTap: () => notifier.activate(config.id),
                          ),
                        const SizedBox(width: 6),
                        _IconButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: AppColors.purpleAccent,
                          onTap: () => notifier.startEdit(config),
                        ),
                        const SizedBox(width: 6),
                        _IconButton(
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => notifier.toggleHistory(config),
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

  Widget _activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(999)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 9, color: AppColors.successGreen),
          SizedBox(width: 3),
          Text('ACTIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.successGreen, letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _statGrid() {
    final tiles = [
      SmtpStatTile(icon: Icons.dns_outlined, tone: SmtpStatTone.purple, label: 'Type', value: config.smtpType == 'server' ? 'Server' : 'Local'),
      SmtpStatTile(icon: Icons.key_outlined, tone: SmtpStatTone.blue, label: 'Security', value: config.useTls ? 'TLS' : 'None'),
      SmtpStatTile(icon: Icons.send_outlined, tone: SmtpStatTone.amber, label: 'Priority', value: _capitalize(config.priority)),
      SmtpStatTile(
        icon: Icons.mail_outline,
        tone: SmtpStatTone.rose,
        label: 'Sender',
        value: config.senderName.isNotEmpty ? config.senderName : (config.fromEmail.isNotEmpty ? config.fromEmail : '—'),
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

  Widget _historyPanel(SmtpSettingsState state) {
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _IconButton({
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
