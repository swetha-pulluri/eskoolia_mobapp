import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Delete confirmation dialog — mirrors frontend
/// components/common/ConfirmationModal.tsx in its "danger" variant, as used
/// by RoleManagementPanel.tsx for role deletion.
///
/// Returns true if the admin confirmed deletion.
Future<bool> showRoleDeleteConfirmDialog(
  BuildContext context, {
  required String roleName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _RoleDeleteConfirmDialog(roleName: roleName),
  );
  return result ?? false;
}

class _RoleDeleteConfirmDialog extends StatelessWidget {
  final String roleName;

  const _RoleDeleteConfirmDialog({required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('⚠️', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Delete Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete "$roleName"? This cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.inkSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.inkPrimary,
                      side: BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Delete'),
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
