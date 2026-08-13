import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class _StepDef {
  final String label;
  final IconData icon;
  const _StepDef(this.label, this.icon);
}

/// The wizard's 6 steps, in order — mirrors `SchoolInfoPanel.tsx`'s
/// `WIZARD_STEPS` (lucide icons mapped to their closest Material outline
/// equivalent: BadgeCheck→verified, MapPin→location_on, Landmark→
/// account_balance, ClipboardCheck→fact_check).
const List<_StepDef> _steps = [
  _StepDef('Identity', Icons.verified_outlined),
  _StepDef('Principal Contact', Icons.person_outline),
  _StepDef('Address', Icons.location_on_outlined),
  _StepDef('Compliance', Icons.account_balance_outlined),
  _StepDef('Branding', Icons.palette_outlined),
  _StepDef('Review', Icons.fact_check_outlined),
];

/// The circular step indicator row atop the wizard card — mirrors
/// `SchoolInfoPanel.tsx`'s step-circle-plus-connector-line markup. Non-active
/// circles are tappable to jump straight to that step.
class SchoolInfoStepIndicator extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTap;

  const SchoolInfoStepIndicator({super.key, required this.currentStep, required this.onStepTap});

  @override
  Widget build(BuildContext context) {
    // Six fixed-width step circles never reliably fit a phone's width once
    // page/card padding is subtracted, especially on narrow devices — wrap
    // in a horizontal scroller so it can never overflow. Connectors get a
    // fixed width (rather than `Expanded`, which a horizontally-scrolling
    // Row can't give a bounded width to) so the whole row has a definite
    // intrinsic size.
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              _StepCircle(
                def: _steps[i],
                isActive: i == currentStep,
                isDone: i < currentStep,
                onTap: i == currentStep ? null : () => onStepTap(i),
              ),
              if (i < _steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 14, left: 4, right: 4),
                  child: Container(
                    width: 22,
                    height: 2,
                    color: i < currentStep ? AppColors.purpleSoft : AppColors.borderPrimary,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final _StepDef def;
  final bool isActive;
  final bool isDone;
  final VoidCallback? onTap;

  const _StepCircle({required this.def, required this.isActive, required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color background =
        isActive ? AppColors.purpleAccent : (isDone ? AppColors.purpleTint : AppColors.bgSecondary);
    final Color foreground =
        isActive ? Colors.white : (isDone ? AppColors.purpleAccent : AppColors.textTertiary);
    final Border? border = isActive
        ? null
        : Border.all(color: isDone ? AppColors.purpleSoft : AppColors.borderSecondary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle, border: border),
              child: Icon(isDone ? Icons.check_circle : def.icon, size: isDone ? 14 : 13, color: foreground),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                def.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
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
