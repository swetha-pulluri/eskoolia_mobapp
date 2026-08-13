import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../administration/presentation/widgets/admin_confirm_dialog.dart';
import '../../domain/entities/policy_document_entity.dart';
import '../providers/documents_provider.dart';
import '../providers/documents_state.dart';

final _historyDateFormat = DateFormat('MMM d, y · h:mm a');
final _metaDateFormat = DateFormat('MMM d, y, h:mm a');

/// Mirrors `formatSize` in `DocumentsPanel.tsx` exactly.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

/// One policy-document card in the list — mirrors `DocumentsPanel.tsx`'s
/// per-document card markup (left accent bar, meta line, View/Edit/Delete
/// actions, expandable history).
class DocumentCard extends ConsumerWidget {
  final PolicyDocumentEntity document;

  const DocumentCard({super.key, required this.document});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Document',
      message: 'Delete "${document.title}"?',
    );
    if (!confirmed) return;
    await ref.read(documentsNotifierProvider.notifier).delete(document);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentsNotifierProvider);
    final notifier = ref.read(documentsNotifierProvider.notifier);
    final isDeleting = state.busyId == document.id;
    final isViewing = state.viewingId == document.id;
    final historyOpen = state.historyOpenId == document.id;

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
            child: Container(color: AppColors.purpleAccent),
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
                            decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(9)),
                            child: const Icon(Icons.description_outlined, size: 15, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(document.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
                        _DocumentIconButton(
                          icon: Icons.visibility_outlined,
                          label: 'View',
                          color: AppColors.textSecondary,
                          busy: isViewing,
                          onTap: () => notifier.viewDocument(document),
                        ),
                        const SizedBox(width: 6),
                        _DocumentIconButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: AppColors.purpleAccent,
                          onTap: () => notifier.startEdit(document),
                        ),
                        const SizedBox(width: 6),
                        _DocumentIconButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: AppColors.dangerRed,
                          busy: isDeleting,
                          onTap: () => _confirmDelete(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => notifier.toggleHistory(document),
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
    final parts = <String>[policyDocumentCategoryLabel(document.category)];
    if (document.fileType.isNotEmpty) parts.add(document.fileType);
    parts.add(formatFileSize(document.fileSize));
    final parsed = DateTime.tryParse(document.uploadedAt);
    parts.add(parsed != null ? _metaDateFormat.format(parsed.toLocal()) : document.uploadedAt);
    return parts.join(' · ');
  }

  Widget _historyPanel(DocumentsState state) {
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

class _DocumentIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _DocumentIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.55 : 1,
      child: InkWell(
        onTap: busy ? null : onTap,
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
              busy
                  ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
