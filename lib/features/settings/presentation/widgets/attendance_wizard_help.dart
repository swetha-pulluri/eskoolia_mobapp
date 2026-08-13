import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mirrors `WIZARD_HELP_STEPS` in `AttendanceRulesPanel.tsx` — exact copy.
const List<({String label, String description})> _attendanceWizardHelpSteps = [
  (label: 'Basics', description: 'Name the policy and set the standard shift start/end time.'),
  (
    label: 'Applies To',
    description:
        'Which roles this policy covers. Leave empty to make it the fallback for anyone not covered by a more specific policy.',
  ),
  (
    label: 'Grace & Breaks',
    description: 'How late staff can arrive/leave without penalty, missing-punch grace, and break duration.',
  ),
  (
    label: 'Hours & Overtime',
    description:
        'Minimum hours for a full/half day, when overtime kicks in, and its pay multipliers on regular days vs. holidays.',
  ),
  (label: 'Weekly Offs', description: 'Which days of the week are off under this policy.'),
  (
    label: 'Late Marks & Alerts',
    description:
        'How many late marks convert to a Loss-of-Pay day, and whether/when absence alerts fire and who gets notified.',
  ),
  (label: 'Review', description: 'Check the whole policy at a glance before saving.'),
];

/// A small "?" icon button opening a dialog listing one line per wizard
/// step — same mobile treatment as every other Settings wizard's help
/// button (Leave Policy, Holiday Calendar).
class AttendanceWizardHelpButton extends StatelessWidget {
  const AttendanceWizardHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showHelp(context),
      icon: const Icon(Icons.help_outline, size: 18, color: AppColors.textSecondary),
      tooltip: 'Attendance Policy Wizard Guide',
      visualDensity: VisualDensity.compact,
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Attendance Policy Wizard Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
              for (final step in _attendanceWizardHelpSteps)
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
