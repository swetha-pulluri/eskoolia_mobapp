import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/leave_policy_choices.dart';

/// The wizard's circular step-icon row — mirrors `LeavePolicyWizard`'s step
/// markup. Unlike School Info's fixed 6-step version, this one is
/// parameterized (9 steps here) and takes a [canJumpTo] gate, since this
/// wizard's jump rule differs (`isEditing || target === 0 || hasName`).
/// Wrapped in a horizontal scroll view — 9 circles + connectors don't fit a
/// phone width at a legible size the way School Info's 6 did.
class LeavePolicyStepIndicator extends StatelessWidget {
  final int currentStep;
  final bool Function(int index) canJumpTo;
  final ValueChanged<int> onStepTap;

  const LeavePolicyStepIndicator({
    super.key,
    required this.currentStep,
    required this.canJumpTo,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final steps = leaveWizardSteps;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepCircle(
              label: steps[i].label,
              icon: steps[i].icon,
              isActive: i == currentStep,
              isDone: i < currentStep,
              onTap: (canJumpTo(i) && i != currentStep) ? () => onStepTap(i) : null,
            ),
            if (i < steps.length - 1)
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
        width: 50,
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
