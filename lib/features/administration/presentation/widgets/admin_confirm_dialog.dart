import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Delete-confirmation dialog matching the real, currently-shipped web
/// design's shared delete modal (`VisitorBookPanel.module.css`'s
/// `.backdrop`/`.modal`, reused verbatim by `ComplaintPanel.tsx`,
/// `PhoneCallLogPanel.tsx`, `PostalReceivePanel.tsx`,
/// `PostalDispatchPanel.tsx`): a circular red trash-icon badge, plain
/// title "Confirm Delete", body message, Cancel + red "Delete" button.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String message,
  String title = 'Confirm Delete',
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.redSoft, shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline, color: AppColors.dangerRed, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.borderPrimary)),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed, foregroundColor: Colors.white, elevation: 0),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
