import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Icon-led stat card matching the web Audit Log `KpiCard`
/// (icon box on the left, label/value/sub stacked on the right, no sparkline).
class IconStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const IconStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.kpiLabel.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTextStyles.boardCount.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!, style: AppTextStyles.kpiFootnote, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
