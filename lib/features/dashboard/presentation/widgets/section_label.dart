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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          // Icon and Title
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: AppColors.brandPurple,
            ),
            const SizedBox(width: 8),
          ],
          if (pinnedCount != null) ...[
            Icon(
              Icons.star_rounded,
              size: 16,
              color: AppColors.brandPurple,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink1,
              letterSpacing: -0.1,
            ),
          ),

          const Spacer(),

          // Count or Pinned Count
          if (count != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(999)),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink2),
              ),
            ),
          ],
          if (pinnedCount != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(999)),
              child: Text(
                '$pinnedCount pinned',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink2),
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
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brandPurple),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
