import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SectionLabel extends StatelessWidget {
  final IconData? icon;
  final String title;
  final int? count;
  final int? pinnedCount;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionLabel({
    super.key,
    this.icon,
    required this.title,
    this.count,
    this.pinnedCount,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Icon and Title
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: AppColors.ink3,
            ),
            const SizedBox(width: 6),
          ],
          if (pinnedCount != null) ...[
            const Icon(
              Icons.star,
              size: 14,
              color: AppColors.ink3,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ink2,
              letterSpacing: 0.6,
            ),
          ),
          
          const Spacer(),
          
          // Count or Pinned Count
          if (count != null) ...[
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink3,
                letterSpacing: 0.6,
              ),
            ),
          ],
          if (pinnedCount != null) ...[
            Text(
              '$pinnedCount PINNED',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink3,
                letterSpacing: 0.6,
              ),
            ),
          ],
          
          // Action Button
          if (actionText != null && onAction != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onAction,
              child: Text(
                '$actionText →',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.ink3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
