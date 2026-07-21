import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'sparkline_painter.dart';

/// KPI Card matching web frontend structure
/// 
/// Structure:
/// - Sparkline (118x32px)
/// - Label (10.5px uppercase)
/// - Value (50px serif)
/// - Trend badge (optional)
/// - Footnote (optional)
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? trend;
  final Color? trendColor;
  final String? footnote;
  final List<double>? sparklineData;
  final Color? sparklineColor;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendColor,
    this.footnote,
    this.sparklineData,
    this.sparklineColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sparkline
                if (sparklineData != null && sparklineData!.isNotEmpty) ...[
                  SizedBox(
                    width: 118,
                    height: 32,
                    child: CustomPaint(
                      painter: SparklinePainter(
                        data: sparklineData!,
                        color: sparklineColor ?? AppColors.successGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Label
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.kpiLabel,
                ),
                const SizedBox(height: 8),

                // Value
                Text(
                  value,
                  style: AppTextStyles.kpiValue,
                ),

                // Trend & Footnote row
                if (trend != null || footnote != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Trend badge
                      if (trend != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (trendColor ?? AppColors.successGreen)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trend!,
                            style: AppTextStyles.kpiTrend(
                              color: trendColor ?? AppColors.successGreen,
                            ),
                          ),
                        ),
                        if (footnote != null) const SizedBox(width: 8),
                      ],

                      // Footnote
                      if (footnote != null)
                        Expanded(
                          child: Text(
                            footnote!,
                            style: AppTextStyles.kpiFootnote,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
