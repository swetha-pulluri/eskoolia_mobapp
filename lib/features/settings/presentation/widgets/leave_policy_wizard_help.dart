import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/leave_policy_choices.dart';

/// A small "?" icon button opening a dialog listing one line per wizard
/// step — the mobile equivalent of `WizardHelpButton.tsx`'s absolutely
/// positioned popover. A centered dialog is the sane native idiom for an
/// info popover on a phone (same reasoning as swapping the browser's
/// `confirm()` for a styled `AlertDialog` elsewhere in this app), not a
/// redesign of the feature.
class LeavePolicyWizardHelpButton extends StatelessWidget {
  const LeavePolicyWizardHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showHelp(context),
      icon: const Icon(Icons.help_outline, size: 18, color: AppColors.textSecondary),
      tooltip: 'Leave Type Wizard Guide',
      visualDensity: VisualDensity.compact,
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Leave Type Wizard Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Each step configures one part of the leave type. Jump to any step you've already "
                'unlocked using the icons above.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 14),
              for (final step in leaveWizardHelpSteps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(step.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.45)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
