import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

const List<({String label, String description})> _holidayWizardHelpSteps = [
  (label: 'Details', description: 'Name the holiday and set its date (or a date range for a multi-day holiday).'),
  (
    label: 'Options',
    description:
        "Mark it Restricted/opt-in if staff can choose whether to take it, instead of it applying to everyone automatically.",
  ),
  (label: 'Review', description: 'Check the name, dates and type at a glance before saving.'),
];

/// A small "?" icon button opening a dialog listing one line per wizard
/// step — mirrors `WizardHelpButton.tsx`'s popover, same mobile treatment
/// already used for Leave Policy's wizard help.
class HolidayWizardHelpButton extends StatelessWidget {
  const HolidayWizardHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showHelp(context),
      icon: const Icon(Icons.help_outline, size: 18, color: AppColors.textSecondary),
      tooltip: 'Holiday Wizard Guide',
      visualDensity: VisualDensity.compact,
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Holiday Wizard Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A quick walkthrough of what each step configures.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 14),
              for (final step in _holidayWizardHelpSteps)
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
