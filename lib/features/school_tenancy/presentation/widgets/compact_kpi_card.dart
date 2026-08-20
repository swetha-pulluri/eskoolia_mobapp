import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sparkline_painter.dart';

/// School-Tenancy-local, more compact drop-in replacement for the shared
/// `core/widgets/kpi_card.dart`'s `KpiCard`/`KpiCardGrid` — same fields, same
/// visual language (bordered white card, sparkline, uppercase label, big
/// serif value, trend badge, footnote), just smaller. Built as its own
/// widget (not an edit to the shared one) specifically so this doesn't
/// affect the other modules that also use `KpiCard` (HR, Admissions,
/// Student, Attendance, Dashboard) — this module explicitly asked for its
/// own KPI cards to take up noticeably less vertical space, which those
/// other modules never requested.
class CompactKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? trend;
  final Color? trendColor;
  final String? footnote;
  final List<double>? sparklineData;
  final Color? sparklineColor;
  final VoidCallback? onTap;
  final IconData? icon;

  const CompactKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendColor,
    this.footnote,
    this.sparklineData,
    this.sparklineColor,
    this.onTap,
    this.icon,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sparklineData != null && sparklineData!.isNotEmpty) ...[
                  SizedBox(
                    width: 90,
                    height: 22,
                    child: CustomPaint(
                      painter: SparklinePainter(
                        data: sparklineData!,
                        color: sparklineColor ?? AppColors.successGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Label (+ optional icon) — `maxLines: 2` (not 1 + ellipsis)
                // so a longer uppercase/tracked label like "TOTAL SCHOOLS"
                // wraps to a full second line instead of truncating to
                // "TOTAL SCHOO…" on a half-width phone card.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 12, color: sparklineColor ?? AppColors.textTertiary),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.textTertiary,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Value — same serif family as the shared `KpiCard`, at a
                // smaller size (32 vs. 50) so the card's height doesn't
                // dwarf everything else on the page.
                Text(
                  value,
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -1.0,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),

                if (trend != null || footnote != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (trend != null) ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (trendColor ?? AppColors.successGreen).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              trend!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: trendColor ?? AppColors.successGreen,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (footnote != null) const SizedBox(width: 6),
                      ],
                      if (footnote != null)
                        Expanded(
                          child: Text(
                            footnote!,
                            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
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

/// Same width-constrained/height-intrinsic grid as the shared `KpiCardGrid`,
/// just wrapping `CompactKpiCard`s.
class CompactKpiCardGrid extends StatelessWidget {
  final List<Widget> cards;
  final double spacing;
  final int crossAxisCount;

  const CompactKpiCardGrid({
    super.key,
    required this.cards,
    this.spacing = 12,
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
