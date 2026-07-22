import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Which bulk action is being confirmed — mirrors frontend
/// components/login-permission/ConfirmModal.tsx's BulkAction variants.
enum LoginPermissionBulkAction { enable, disable, reset }

/// Confirmation dialog shown before a bulk enable/disable/reset — mirrors
/// frontend ConfirmModal.tsx. Returns true if the admin confirmed.
///
/// The "reset" copy deliberately differs from the frontend's: the frontend's
/// text claims users "receive a temporary password by email", but the
/// backend's bulk-reset endpoint (views.py::LoginPermissionViewSet.bulk_reset)
/// sends no email and never returns the generated passwords — they're
/// unrecoverable once set. Repeating the frontend's claim here would
/// mislead admins into thinking users are notified automatically.
Future<bool> showLoginPermissionBulkConfirmDialog({
  required BuildContext context,
  required LoginPermissionBulkAction action,
  required int count,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _BulkConfirmDialog(action: action, count: count),
  );
  return result ?? false;
}

class _ConfirmCopy {
  final String title;
  final String description;
  final String confirmLabel;
  final Color accent;
  final Color accentBg;

  const _ConfirmCopy({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.accent,
    required this.accentBg,
  });
}

class _BulkConfirmDialog extends StatelessWidget {
  final LoginPermissionBulkAction action;
  final int count;

  const _BulkConfirmDialog({required this.action, required this.count});

  _ConfirmCopy _copyFor(LoginPermissionBulkAction action, int count) {
    final userWord = count == 1 ? 'user' : 'users';
    switch (action) {
      case LoginPermissionBulkAction.enable:
        return _ConfirmCopy(
          title: 'Enable Login Access',
          description:
              'You are about to enable login access for $count $userWord. '
              'They will be able to sign in immediately.',
          confirmLabel: 'Enable',
          accent: AppColors.dashboardPurple,
          accentBg: const Color(0xFFEEEAFF),
        );
      case LoginPermissionBulkAction.disable:
        return _ConfirmCopy(
          title: 'Disable Login Access',
          description:
              'You are about to disable login access for $count $userWord. '
              'They will not be able to sign in until re-enabled.',
          confirmLabel: 'Disable',
          accent: const Color(0xFFDC2626),
          accentBg: const Color(0xFFFEF2F2),
        );
      case LoginPermissionBulkAction.reset:
        return _ConfirmCopy(
          title: 'Reset Passwords',
          description:
              'You are about to force-reset passwords for $count $userWord. '
              'Unlike the single Reset Password action, bulk resets do not '
              'show the new passwords afterward — reset users individually '
              'if they need to know their new password right away.',
          confirmLabel: 'Reset Passwords',
          accent: const Color(0xFFB45309),
          accentBg: const Color(0xFFFFFBEB),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(action, count);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: copy.accentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 22,
                  color: copy.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                copy.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                copy.description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.inkSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.inkSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: copy.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(copy.confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
