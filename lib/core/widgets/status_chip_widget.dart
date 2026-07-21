import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// Status chip widget matching web frontend
/// Shows a colored dot + label
/// 
/// Usage:
/// ```dart
/// StatusChip(
///   label: 'Active',
///   color: AppColors.successGreen,
/// )
/// ```
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.chipLabel(color: color),
          ),
        ],
      ),
    );
  }
}

/// Board/Plan chip (no dot, just label with background)
class BoardChip extends StatelessWidget {
  final String label;
  final Color color;

  const BoardChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.chipLabel(color: color),
      ),
    );
  }
}
