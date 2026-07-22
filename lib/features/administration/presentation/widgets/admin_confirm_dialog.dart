import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'web_button.dart';

/// Delete-confirmation dialog matching the web `ConfirmationModal`
/// component — used by Complaints, Phone Call Log and the Postal panels:
/// warning icon, title, message, Cancel + danger Confirm buttons.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String message,
  String title = 'Confirm Delete',
  String confirmLabel = 'Yes, Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.redSoft, shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel, style: const TextStyle(color: AppColors.textPrimary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Visitor Book's own bespoke delete dialog — NOT the shared
/// `ConfirmationModal`: no icon, plain title, `#475569` message text,
/// grey `#94a3b8` Cancel + red `#dc2626` Delete filled buttons.
Future<bool> showVisitorBookDeleteDialog(BuildContext context, {required String message}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Confirm Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        WebButton(label: 'Cancel', color: const Color(0xFF94A3B8), onPressed: () => Navigator.of(context).pop(false)),
        WebButton(label: 'Delete', color: AppColors.dangerRed, onPressed: () => Navigator.of(context).pop(true)),
      ],
    ),
  );
  return result ?? false;
}
