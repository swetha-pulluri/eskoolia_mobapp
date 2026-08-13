import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class _StepDef {
  final String label;
  final IconData icon;
  const _StepDef(this.label, this.icon);
}

/// The wizard's 5 fixed steps — mirrors `SmtpWizard`'s `WIZARD_STEPS`
/// (BadgeCheck→verified, KeyRound→key, Mail→mail, Send→send,
/// ClipboardCheck→fact_check). Note: unlike Leave Policy/Holiday Calendar,
/// this wizard has no `WizardHelpButton` — confirmed absent from the web
/// source, so none is added here either.
const List<_StepDef> _steps = [
  _StepDef('Basics', Icons.verified_outlined),
  _StepDef('Authentication', Icons.key_outlined),
  _StepDef('Sender Identity', Icons.mail_outline),
  _StepDef('Delivery', Icons.send_outlined),
  _StepDef('Test & Review', Icons.fact_check_outlined),
];

/// The circular step-icon row — 32px circles, matching this web wizard's
/// actual size (same as School Info's/Leave Policy's own equivalents).
class SmtpStepIndicator extends StatelessWidget {
  final int currentStep;
  final bool Function(int index) canJumpTo;
  final ValueChanged<int> onStepTap;

  const SmtpStepIndicator({
    super.key,
    required this.currentStep,
    required this.canJumpTo,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 3, right: 3),
                child: Container(
                  height: 2,
                  color: i < currentStep ? AppColors.purpleSoft : AppColors.borderPrimary,
                ),
              ),
            ),
        ],
      ],
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
        width: 46,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle, border: border),
              child: Icon(isDone ? Icons.check_circle : icon, size: isDone ? 16 : 15, color: foreground),
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
