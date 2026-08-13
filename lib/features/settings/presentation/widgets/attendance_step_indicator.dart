import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class _StepDef {
  final String label;
  final IconData icon;
  const _StepDef(this.label, this.icon);
}

/// The wizard's 7 fixed steps — mirrors `AttendanceWizard`'s `WIZARD_STEPS`
/// (Clock→Basics, Users2→Applies To, Coffee→Grace & Breaks,
/// TrendingUp→Hours & Overtime, CalendarClock→Weekly Offs, Bell→Late Marks
/// & Alerts, ClipboardCheck→Review).
const List<_StepDef> _steps = [
  _StepDef('Basics', Icons.access_time),
  _StepDef('Applies To', Icons.groups_2_outlined),
  _StepDef('Grace & Breaks', Icons.coffee_outlined),
  _StepDef('Hours & Overtime', Icons.trending_up),
  _StepDef('Weekly Offs', Icons.event_repeat_outlined),
  _StepDef('Late Marks & Alerts', Icons.notifications_outlined),
  _StepDef('Review', Icons.fact_check_outlined),
];

/// The circular step-icon row — wrapped in a horizontal scroll view like
/// Leave Policy's own 9-step indicator, since 7 circles + connectors don't
/// fit a phone width at a legible size either.
class AttendanceStepIndicator extends StatelessWidget {
  final int currentStep;
  final bool Function(int index) canJumpTo;
  final ValueChanged<int> onStepTap;

  const AttendanceStepIndicator({
    super.key,
    required this.currentStep,
    required this.canJumpTo,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            _StepCircle(
              label: _steps[i].label,
              icon: _steps[i].icon,
              isActive: i == currentStep,
              isDone: i < currentStep,
              onTap: (canJumpTo(i) && i != currentStep) ? () => onStepTap(i) : null,
            ),
            if (i < _steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Container(
                  width: 18,
                  height: 2,
                  color: i < currentStep ? AppColors.purpleSoft : AppColors.borderPrimary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDone;
  final VoidCallback? onTap;

  const _StepCircle({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color background =
        isActive ? AppColors.purpleAccent : (isDone ? AppColors.purpleTint : AppColors.bgSecondary);
    final Color foreground =
        isActive ? Colors.white : (isDone ? AppColors.purpleAccent : AppColors.textTertiary);
    final Border? border =
        isActive ? null : Border.all(color: isDone ? AppColors.purpleSoft : AppColors.borderSecondary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle, border: border),
              child: Icon(isDone ? Icons.check_circle : icon, size: isDone ? 15 : 14, color: foreground),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.purpleAccent : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
