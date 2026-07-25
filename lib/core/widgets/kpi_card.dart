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
                      // Trend badge — `Flexible` (not a bare `Container`) so
                      // it shrinks/ellipsizes under real width pressure
                      // (narrow phones, larger text-scale settings) instead
                      // of forcing a horizontal `RenderFlex` overflow —
                      // confirmed reproducible via widget test at 360px
                      // width + 1.3x text scale before this fix.
                      if (trend != null) ...[
                        Flexible(
                          child: Container(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

/// Lays out a set of [KpiCard]s in a fixed-column grid where each tile's
/// WIDTH is constrained but its HEIGHT is intrinsic (content-driven).
///
/// Replaces a naive `GridView.count(childAspectRatio: ...)`, which forces
/// every tile to a fixed height derived only from width/aspect-ratio math —
/// that fixed height doesn't account for `KpiCard`'s actual content height
/// (sparkline + label + value + trend/footnote row, ~180px with all
/// optional sections populated), causing a `RenderFlex overflowed on the
/// bottom` on standard/narrow phone widths and at larger text-scale
/// settings. A `Wrap` of width-constrained-but-height-intrinsic tiles has
/// no such fixed-height ceiling to overflow.
class KpiCardGrid extends StatelessWidget {
  final List<Widget> cards;
  final double spacing;
  final int crossAxisCount;

  const KpiCardGrid({
    super.key,
    required this.cards,
    this.spacing = 16,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (crossAxisCount - 1);
        final cardWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
        );
      },
    );
  }
}
