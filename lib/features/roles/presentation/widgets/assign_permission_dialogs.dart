import 'package:flutter/material.dart';
import '../../domain/models/permission_tree.dart';
import '../../domain/models/sub_feature_row.dart';

/// Confirmation dialogs for the Assign Permissions screen — mirrors
/// frontend components/access-control/AssignPermissionPanel.tsx's
/// DeleteConfirmModal, FullControlModal, RiskyConfirmModal and ReviewModal
/// (all rendered via its ModalOverlay: fixed, rgba(15,17,42,.55) backdrop).

const Color _overlayBarrierColor = Color(0x8C0F112A); // rgba(15,17,42,.55)

Future<T?> _showOverlayDialog<T>(BuildContext context, Widget dialog) {
  return showDialog<T>(
    context: context,
    barrierColor: _overlayBarrierColor,
    builder: (_) => dialog,
  );
}

class _DialogShell extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const _DialogShell({required this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: child,
        ),
      ),
    );
  }
}

Widget _iconBadge(String emoji, Color background) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
  );
}

Widget _outlinedBtn(String label, VoidCallback onTap) {
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF5B5E72),
      side: const BorderSide(color: Color(0xFFE8E8EE), width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  );
}

Widget _filledBtn(String label, Color background, VoidCallback onTap) {
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
  );
}

// ── Confirm Delete Permission ─────────────────────────────────────────────
// Shown when GRANTING (not revoking) a delete-type permission checkbox.

Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String permCode,
  required String featureLabel,
}) async {
  final result = await _showOverlayDialog<bool>(
    context,
    _ConfirmDeletePermissionDialog(permCode: permCode, featureLabel: featureLabel),
  );
  return result ?? false;
}

class _ConfirmDeletePermissionDialog extends StatelessWidget {
  final String permCode;
  final String featureLabel;

  const _ConfirmDeletePermissionDialog({
    required this.permCode,
    required this.featureLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      maxWidth: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge('🗑', const Color(0xFFFEF2F2)),
          const SizedBox(height: 16),
          const Text(
            'Confirm Delete Permission',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF15172A),
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5B5E72),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'You are about to grant '),
                const TextSpan(
                  text: 'delete',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' access on "$featureLabel". Users with this role can ',
                ),
                const TextSpan(
                  text: 'permanently delete records',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '. This cannot be undone.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF9A9DB0)),
              children: [
                const TextSpan(text: 'Permission: '),
                TextSpan(
                  text: permCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    backgroundColor: Color(0xFFF5F5FB),
                    color: Color(0xFF5B5E72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _outlinedBtn('Cancel', () => Navigator.of(context).pop(false)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filledBtn(
                  'Grant Delete Access',
                  const Color(0xFFDC2626),
                  () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Full Control includes Delete ──────────────────────────────────────────
// Shown when the Full Control operation level is picked for a module that
// has a delete permission. Returns true = include delete, false = exclude
// delete (falls back to Create & Edit), null = cancelled.

Future<bool?> showFullControlDialog(
  BuildContext context, {
  required String moduleName,
}) {
  return _showOverlayDialog<bool>(context, _FullControlDialog(moduleName: moduleName));
}

class _FullControlDialog extends StatelessWidget {
  final String moduleName;

  const _FullControlDialog({required this.moduleName});

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      maxWidth: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge('🔒', const Color(0xFFEEEAFF)),
          const SizedBox(height: 16),
          const Text(
            'Full Control includes Delete',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF15172A),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5B5E72),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'You selected '),
                const TextSpan(
                  text: 'Full Control',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' for $moduleName. This includes the ability to'),
                const TextSpan(
                  text: ' permanently delete records',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '. Include delete permissions?'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _filledBtn(
              'Yes, Include Delete',
              const Color(0xFFDC2626),
              () => Navigator.of(context).pop(true),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFEEEAFF),
                foregroundColor: const Color(0xFF6D4AFF),
                side: const BorderSide(color: Color(0xFF6D4AFF), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'View + Add + Edit Only (no delete)',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9A9DB0),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sensitive Module Access (risky-module confirm) ────────────────────────

Future<bool> showRiskyConfirmDialog(
  BuildContext context, {
  required List<String> riskyModuleLabels,
}) async {
  final result = await _showOverlayDialog<bool>(
    context,
    _RiskyConfirmDialog(riskyModuleLabels: riskyModuleLabels),
  );
  return result ?? false;
}

class _RiskyConfirmDialog extends StatelessWidget {
  final List<String> riskyModuleLabels;

  const _RiskyConfirmDialog({required this.riskyModuleLabels});

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      maxWidth: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge('⚠️', const Color(0xFFFFF7ED)),
          const SizedBox(height: 16),
          const Text(
            'Sensitive Module Access',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF15172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You are granting access to sensitive modules:',
            style: TextStyle(fontSize: 13, color: Color(0xFF5B5E72)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: riskyModuleLabels
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        '⚠️ $m',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'These modules handle financial or sensitive data. Please confirm this is intentional.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9A9DB0)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _outlinedBtn('Review Again', () => Navigator.of(context).pop(false)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filledBtn(
                  'Yes, Save Anyway',
                  const Color(0xFFF59E0B),
                  () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Review Permissions (pre-save summary) ─────────────────────────────────

Future<bool> showReviewPermissionsDialog(
  BuildContext context, {
  required List<PermissionModule> modules,
  required Set<String> enabledModules,
  required Map<String, OperationLevel> operationLevels,
  required Set<int> selectedIds,
}) async {
  final result = await _showOverlayDialog<bool>(
    context,
    _ReviewPermissionsDialog(
      modules: modules,
      enabledModules: enabledModules,
      operationLevels: operationLevels,
      selectedIds: selectedIds,
    ),
  );
  return result ?? false;
}

class _ReviewPermissionsDialog extends StatelessWidget {
  final List<PermissionModule> modules;
  final Set<String> enabledModules;
  final Map<String, OperationLevel> operationLevels;
  final Set<int> selectedIds;

  const _ReviewPermissionsDialog({
    required this.modules,
    required this.enabledModules,
    required this.operationLevels,
    required this.selectedIds,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = modules.where((m) => enabledModules.contains(m.module)).toList();
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE8E8EE))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Review Permissions',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(0xFF15172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please verify the access before saving. Changes apply immediately.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9A9DB0)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                child: enabled.isEmpty
                    ? const Text(
                        'No modules enabled. Nothing will be saved.',
                        style: TextStyle(color: Color(0xFF9A9DB0), fontSize: 13),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: enabled.map(_buildModuleSection).toList(),
                      ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE8E8EE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _outlinedBtn('← Edit More', () => Navigator.of(context).pop(false)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _filledBtn(
                      'Confirm & Save',
                      const Color(0xFF5B4FCF),
                      () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSection(PermissionModule mod) {
    final level = operationLevels[mod.module] ?? OperationLevel.none;
    final isRisky = riskyModules.contains(mod.module);
    final rows = groupPermsBySubFeature(mod.permissions).where((row) {
      return [row.view, row.add, row.edit, row.delete]
          .any((p) => p != null && selectedIds.contains(p.id));
    }).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5FB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                prettyModuleName(mod.module),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF15172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEAFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  level.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D4AFF),
                  ),
                ),
              ),
              if (isRisky) const Text('⚠️', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text(
              'No specific permissions selected',
              style: TextStyle(fontSize: 12, color: Color(0xFF9A9DB0)),
            )
          else
            ...rows.map(_buildGrantedRow),
        ],
      ),
    );
  }

  Widget _buildGrantedRow(SubFeatureRow row) {
    final entries = <(String, bool)>[
      if (row.view != null && selectedIds.contains(row.view!.id)) ('View', false),
      if (row.add != null && selectedIds.contains(row.add!.id)) ('Add', false),
      if (row.edit != null && selectedIds.contains(row.edit!.id)) ('Edit', false),
      if (row.delete != null && selectedIds.contains(row.delete!.id)) ('Delete', true),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              row.label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5B5E72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: entries.map((e) {
                final (label, isDelete) = e;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDelete ? const Color(0xFFFEF2F2) : const Color(0xFFEEEAFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDelete ? const Color(0xFFDC2626) : const Color(0xFF6D4AFF),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
