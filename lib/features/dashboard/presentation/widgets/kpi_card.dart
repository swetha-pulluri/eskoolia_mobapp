import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// KPI Card Widget
/// Pixel-perfect recreation of frontend KPI cards
/// Source: frontend/app/(dashboard)/dashboard/page.tsx - KPICard component
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool deltaUp;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaUp,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.onBackground.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + Label row
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Icon(icon, size: 13, color: iconColor)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9197AE), // ink-3
                    letterSpacing: 0.6,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F1222), // ink-1
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // Delta
          Text(
            '${deltaUp ? '↑' : '↓'} $delta',
            style: TextStyle(
              fontSize: 10.5,
              color: deltaUp
                  ? AppColors.deltaPositive
                  : AppColors.deltaNegative,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Skeleton Loading Card for KPI
class KpiCardSkeleton extends StatelessWidget {
  const KpiCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skeleton for icon + label
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 9),
          // Skeleton for value
          Container(
            width: 70,
            height: 21,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          // Skeleton for delta
          Container(
            width: 100,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
