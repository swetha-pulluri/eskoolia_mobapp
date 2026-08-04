import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Filter pill widget matching web frontend
/// Rounded button with count badge (mono font)
/// 
/// Usage:
/// ```dart
/// FilterPill(
///   label: 'Active',
///   count: 42,
///   isSelected: true,
///   onTap: () {},
/// )
/// ```
class FilterPill extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback? onTap;

  const FilterPill({
    super.key,
    required this.label,
    this.count,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryPurple : AppColors.bgPrimary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryPurple
                  : AppColors.borderPrimary,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // `Flexible`+ellipsis — `mainAxisSize: min` only affects how
              // this Row reports its own size upward; it does NOT let the
              // Row exceed a tight max-width handed down by an ancestor
              // (e.g. a fixed-width grid cell). Confirmed reproducible via
              // a widget test (a real ~4px overflow at 320dp), so long
              // labels now truncate instead of overflowing.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTextStyles.chipLabelMono.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
