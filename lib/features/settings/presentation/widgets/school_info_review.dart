import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A grouped card of `ReviewRow`s on the wizard's final Review step — mirrors
/// `SchoolInfoPanel.tsx`'s `ReviewSection` component.
class SchoolInfoReviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final Widget child;

  const SchoolInfoReviewSection({
    super.key,
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSecondary),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: AppColors.bgSecondary,
              border: Border(bottom: BorderSide(color: AppColors.borderPrimary)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.purpleTint,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(icon, size: 13, color: AppColors.purpleAccent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purpleAccent)),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right, size: 14, color: AppColors.purpleAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A single label/value row inside a [SchoolInfoReviewSection].
class SchoolInfoReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const SchoolInfoReviewRow({super.key, required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.borderPrimary)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
