import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mirrors `CREATE_STEPS` (Details/Upload/Review) and `EDIT_STEPS`
/// (Details/Review — no Upload step, since a document's file can't be
/// replaced in-place) in `DocumentsPanel.tsx`.
const List<({String label, IconData icon})> documentCreateSteps = [
  (label: 'Details', icon: Icons.badge_outlined),
  (label: 'Upload', icon: Icons.upload_outlined),
  (label: 'Review', icon: Icons.fact_check_outlined),
];

const List<({String label, IconData icon})> documentEditSteps = [
  (label: 'Details', icon: Icons.badge_outlined),
  (label: 'Review', icon: Icons.fact_check_outlined),
];

/// The circular step-icon row — parameterized by [steps] since create (3
/// steps) and edit (2 steps) use a different step set, unlike every other
/// Settings wizard's fixed step count.
class DocumentStepIndicator extends StatelessWidget {
  final List<({String label, IconData icon})> steps;
  final int currentStep;
  final bool Function(int index) canJumpTo;
  final ValueChanged<int> onStepTap;

  const DocumentStepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.canJumpTo,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        width: 64,
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
