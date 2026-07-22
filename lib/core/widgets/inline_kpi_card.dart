import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'sparkline_painter.dart';

/// KPI card where the value and trend sit on the same baseline row,
/// matching the web `KpiCard` used on the Schools and Billing pages
/// (as opposed to the Dashboard's stacked value/trend layout).
class InlineKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final double valueFontSize;
  final String? trend;
  final Color? trendColor;
  final String? footnote;
  final List<double>? sparklineData;
  final Color? sparklineColor;

  const InlineKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.valueFontSize = 28,
    this.trend,
    this.trendColor,
    this.footnote,
    this.sparklineData,
    this.sparklineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.kpiLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (sparklineData != null) ...[
                const SizedBox(width: 6),
                Opacity(
                  opacity: 0.7,
                  child: SizedBox(
                    width: 48,
                    height: 18,
                    child: CustomPaint(
                      painter: SparklinePainter(
                        data: sparklineData!,
                        color: sparklineColor ?? AppColors.successGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.kpiValue.copyWith(
                    fontSize: valueFontSize,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trendColor ?? AppColors.successGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (footnote != null) ...[
            const SizedBox(height: 10),
            Text(
              footnote!,
              style: AppTextStyles.kpiFootnote,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
