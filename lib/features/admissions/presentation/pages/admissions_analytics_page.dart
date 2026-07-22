import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/analytics_data_entity.dart';
import '../providers/admissions_provider.dart';
import '../widgets/admissions_layout.dart';
import '../widgets/analytics_widgets.dart';

const Map<String, String> kPeriodLabels = {
  'month': 'This Month',
  'quarter': 'Last 90 Days',
  'year': 'This Year',
  'all': 'All Time',
};

const Map<String, ({Color color, String icon})> _kSourceConfig = {
  'instagram': (color: Color(0xFFE1306C), icon: '📱'),
  'facebook': (color: Color(0xFF1877F2), icon: '👤'),
  'word of mouth': (color: Color(0xFF10B981), icon: '👥'),
  'phone call': (color: Color(0xFF6366F1), icon: '📞'),
  'google': (color: Color(0xFFEA4335), icon: '🔍'),
  'newspaper': (color: Color(0xFF78716C), icon: '📰'),
};

({Color color, String icon}) _sourceConfig(String name) {
  final key = name.toLowerCase();
  for (final entry in _kSourceConfig.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return (color: const Color(0xFF9CA3AF), icon: '❓');
}

/// Admissions Analytics — converted from `AdmissionsAnalytics.tsx`. KPI
/// cards, conversion funnel, 6-month trend, source/grade breakdowns,
/// counsellor leaderboard, and key insights, all driven by
/// `AdmissionsLocalData.getAnalyticsOverview()` (see that method for the
/// exact backend-aggregation parity notes).
class AdmissionsAnalyticsPage extends ConsumerWidget {
  const AdmissionsAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final asyncData = ref.watch(analyticsOverviewProvider);
    final data = asyncData.maybeWhen(data: (v) => v, orElse: () => const AnalyticsDataEntity());

    final monthlyInquiries = data.monthlyTrend.map((d) => d.inquiries).toList();
    final monthlyEnrolled = data.monthlyTrend.map((d) => d.enrolled).toList();
    final maxSource = data.bySource.isEmpty ? 1 : data.bySource.fold<int>(1, (m, s) => s.count > m ? s.count : m);
    final maxGrade = data.byGrade.isEmpty ? 1 : data.byGrade.fold<int>(1, (m, g) => g.count > m ? g.count : m);

    return AdmissionsLayout(
      currentPath: '/admissions/analytics',
      child: Container(
        color: const Color(0xFFF9FAFB),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(ref, period),
                const SizedBox(height: 14),
                _kpiRow(data, monthlyInquiries, monthlyEnrolled),
                const SizedBox(height: 12),
                _funnelCard(data),
                const SizedBox(height: 12),
                _trendCard(data, monthlyInquiries),
                const SizedBox(height: 12),
                _sourceCard(data, maxSource),
                const SizedBox(height: 12),
                _gradeCard(data, maxGrade),
                const SizedBox(height: 12),
                _leaderboardCard(data),
                if (data.channelBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _channelCard(data),
                ],
                const SizedBox(height: 12),
                ..._insightCards(data),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(WidgetRef ref, String period) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.bar_chart, size: 18, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admissions Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                Text('Conversion insights and pipeline health', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          IconButton(onPressed: () => ref.invalidate(analyticsOverviewProvider), tooltip: 'Refresh', icon: const Icon(Icons.refresh, size: 15, color: Color(0xFF9CA3AF))),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: kPeriodLabels.entries.map((e) {
              final isActive = period == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => ref.read(analyticsPeriodProvider.notifier).state = e.key,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isActive ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4)] : null,
                    ),
                    child: Text(e.value, style: TextStyle(fontSize: 12.5, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _kpiRow(AnalyticsDataEntity data, List<int> monthlyInquiries, List<int> monthlyEnrolled) {
    return _autoHeightGrid(
      spacing: 10,
      children: [
        KpiCard(icon: Icons.people_outline, label: 'Total Inquiries', value: data.total, iconBg: const Color(0xFFDBEAFE), iconColor: const Color(0xFF2563EB), sparkData: monthlyInquiries, sparkColor: const Color(0xFF3B82F6)),
        KpiCard(icon: Icons.call_outlined, label: 'Contact Rate', value: data.contactRatePct.round(), isPercent: true, sub: '${data.contacted} contacted', iconBg: const Color(0xFFCCFBF1), iconColor: const Color(0xFF0D9488), sparkData: monthlyInquiries, sparkColor: const Color(0xFF14B8A6)),
        KpiCard(icon: Icons.show_chart, label: 'Visit Rate', value: data.visitRatePct.round(), isPercent: true, sub: '${data.visited} campus visits', iconBg: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706), sparkData: monthlyInquiries, sparkColor: const Color(0xFFF59E0B)),
        KpiCard(icon: Icons.check_circle_outline, label: 'Enroll Rate', value: data.enrollRatePct.round(), isPercent: true, sub: '${data.enrolled} enrolled', iconBg: const Color(0xFFDCFCE7), iconColor: const Color(0xFF16A34A), sparkData: monthlyEnrolled, sparkColor: const Color(0xFF22C55E)),
      ],
    );
  }

  /// Lays out [children] in a 2-column grid with equal column widths, same as
  /// `GridView.count(crossAxisCount: 2)`, but each row's height is intrinsic
  /// to its content instead of a fixed aspect ratio — avoiding RenderFlex
  /// overflow when a card's content needs more height than the ratio allows.
  Widget _autoHeightGrid({required List<Widget> children, required double spacing}) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      final a = children[i];
      final b = i + 1 < children.length ? children[i + 1] : null;
      rows.add(LayoutBuilder(builder: (context, constraints) {
        final cellWidth = b == null ? constraints.maxWidth : (constraints.maxWidth - spacing) / 2;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: b == null
                ? [SizedBox(width: cellWidth, child: a)]
                : [SizedBox(width: cellWidth, child: a), SizedBox(width: spacing), SizedBox(width: cellWidth, child: b)],
          ),
        );
      }));
    }
    return Column(children: rows);
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
      child: child,
    );
  }

  Widget _cardTitle(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
      ]),
    );
  }

  Widget _funnelCard(AnalyticsDataEntity data) {
    final rate = data.enrollRatePct;
    final bg = rate >= 20 ? const Color(0xFFF0FDF4) : rate >= 10 ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2);
    final fg = rate >= 20 ? const Color(0xFF15803D) : rate >= 10 ? const Color(0xFFB45309) : const Color(0xFFDC2626);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.track_changes, const Color(0xFF6366F1), 'Conversion Funnel'),
          FunnelViz(total: data.total, contacted: data.contacted, visited: data.visited, enrolled: data.enrolled),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text('Overall conversion: ${rate.round()}% of inquiries enroll', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
  }

  Widget _trendCard(AnalyticsDataEntity data, List<int> monthlyInquiries) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.trending_up, const Color(0xFF3B82F6), '6-Month Trend'),
          if (monthlyInquiries.length > 1) ...[
            TrendChart(points: data.monthlyTrend),
            const SizedBox(height: 8),
            Row(children: [
              Row(mainAxisSize: MainAxisSize.min, children: const [
                SizedBox(width: 12, height: 2, child: ColoredBox(color: Color(0xFF60A5FA))),
                SizedBox(width: 6),
                Text('Inquiries', style: TextStyle(fontSize: 11, color: Color(0xFF60A5FA))),
              ]),
              const SizedBox(width: 16),
              Row(mainAxisSize: MainAxisSize.min, children: const [
                SizedBox(width: 12, height: 2, child: ColoredBox(color: Color(0xFF22C55E))),
                SizedBox(width: 6),
                Text('Enrolled', style: TextStyle(fontSize: 11, color: Color(0xFF22C55E))),
              ]),
            ]),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(children: [
                const Icon(Icons.bar_chart, size: 36, color: Color(0xFFD1D5DB)),
                const SizedBox(height: 8),
                const Text('Not enough data yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                const Text('Add 5+ inquiries to see trends', style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _sourceCard(AnalyticsDataEntity data, int maxSource) {
    SourceStat? best;
    if (data.bySource.isNotEmpty) {
      best = data.bySource.reduce((a, b) => b.enrolled > a.enrolled ? b : a);
    }
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.show_chart, const Color(0xFFF59E0B), 'Source Performance'),
          if (data.bySource.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Center(child: Text('No source data yet.', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)))))
          else
            Column(
              children: data.bySource.map((s) {
                final cfg = _sourceConfig(s.sourceName ?? '');
                final convPct = s.count > 0 ? (s.enrolled / s.count * 100).round() : 0;
                final barW = (s.count / maxSource * 100).clamp(4.0, 100.0);
                final pillBg = convPct >= 30 ? const Color(0xFFF0FDF4) : convPct >= 15 ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2);
                final pillFg = convPct >= 30 ? const Color(0xFF16A34A) : convPct >= 15 ? const Color(0xFFD97706) : const Color(0xFFEF4444);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 22, child: Text(cfg.icon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15))),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(s.sourceName ?? 'Direct / Unknown', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
                              Text('${s.count} inq · ${s.enrolled} enrolled', style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                            ]),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(value: barW / 100, minHeight: 6, backgroundColor: const Color(0xFFF3F4F6), color: cfg.color),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(6)),
                        child: Text('$convPct%', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: pillFg)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (best != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
              child: Text.rich(TextSpan(children: [
                const TextSpan(text: '🏆 Best source: '),
                TextSpan(text: best.sourceName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' with ${best.enrolled} enrollments'),
              ]), style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309))),
            ),
        ],
      ),
    );
  }

  Widget _gradeCard(AnalyticsDataEntity data, int maxGrade) {
    const gradeColors = [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF0EA5E9), Color(0xFF14B8A6), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899)];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.school_outlined, const Color(0xFF8B5CF6), 'Grade Demand'),
          if (data.byGrade.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Center(child: Text('No grade data yet.', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)))))
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
              children: List.generate(data.byGrade.length, (i) {
                final g = data.byGrade[i];
                final color = gradeColors[i % gradeColors.length];
                final pctVal = maxGrade > 0 ? (g.count / maxGrade * 100).round() : 0;
                final isHighDemand = pctVal >= 90;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                        child: Text(g.gradeName ?? '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 4),
                      Text('${g.count}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                      SemiGauge(pct: pctVal, color: color),
                      Text(isHighDemand ? 'HIGH DEMAND' : '$pctVal% of top', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: isHighDemand ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF))),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _leaderboardCard(AnalyticsDataEntity data) {
    const avatarColors = [Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899), Color(0xFF8B5CF6)];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.emoji_events_outlined, const Color(0xFFF59E0B), 'Counsellor Leaderboard'),
          if (data.counsellorStats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: Text('No counsellor data yet. Add "Assigned To" when creating inquiries.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
            )
          else
            Column(
              children: List.generate(data.counsellorStats.length, (i) {
                final c = data.counsellorStats[i];
                final initials = c.assigned.trim().split(RegExp(r'\s+')).map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
                final avatarColor = avatarColors[i % avatarColors.length];
                final isTop = i == 0;
                final rankBg = i == 0 ? const Color(0xFFFBBF24) : i == 1 ? const Color(0xFFD1D5DB) : i == 2 ? const Color(0xFFFDBA74) : const Color(0xFFF3F4F6);
                final rankFg = i <= 2 ? Colors.white : const Color(0xFF6B7280);
                final convColor = c.conversionPct >= 30 ? const Color(0xFF22C55E) : c.conversionPct >= 15 ? const Color(0xFFF59E0B) : const Color(0xFFF87171);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTop ? const Color(0xFFFFFBEB) : Colors.white,
                    border: Border.all(color: isTop ? const Color(0xFFFCD34D) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(i == 0 ? '🏆' : '${i + 1}', style: TextStyle(fontSize: i == 0 ? 12 : 11, fontWeight: FontWeight.w700, color: rankFg)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.assigned, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis),
                          Text('${c.total} inquiries', style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    Text('${c.conversionPct.round()}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: convColor)),
                  ]),
                );
              }),
            ),
          const Padding(padding: EdgeInsets.only(top: 4), child: Text('Conversion % = enrolled ÷ assigned inquiries', style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)))),
        ],
      ),
    );
  }

  Widget _channelCard(AnalyticsDataEntity data) {
    const colors = [Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444)];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.call_outlined, const Color(0xFF0EA5E9), 'Contact Channels Used'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(data.channelBreakdown.length, (i) {
              final ch = data.channelBreakdown[i];
              final color = colors[i % colors.length];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.07), border: Border.all(color: color.withValues(alpha: 0.19)), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(ch.channel, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(width: 6),
                  Text('${ch.count}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                ]),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<Widget> _insightCards(AnalyticsDataEntity data) {
    SourceStat? bestSource = data.bySource.isEmpty ? null : data.bySource.reduce((a, b) => b.enrolled > a.enrolled ? b : a);
    GradeStat? topGrade = data.byGrade.isEmpty ? null : data.byGrade.reduce((a, b) => b.count > a.count ? b : a);
    final rate = data.enrollRatePct;
    final healthBorder = rate >= 20 ? const Color(0xFF4ADE80) : rate >= 10 ? const Color(0xFFFBBF24) : const Color(0xFFF87171);
    final healthText = rate >= 20 ? 'Strong at ${rate.round()}% — keep nurturing leads.' : rate >= 10 ? 'Moderate at ${rate.round()}% — follow up faster.' : 'Low at ${rate.round()}% — review your pipeline.';

    final cards = <Widget>[];
    if (bestSource != null) {
      cards.add(_insightTile(const Color(0xFF60A5FA), 'Best Lead Source', 'best-source', child: Text.rich(TextSpan(children: [
        TextSpan(text: bestSource.sourceName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: ' drives the most enrollments (${bestSource.enrolled}).'),
      ]), style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)))));
    }
    cards.add(_insightTile(healthBorder, 'Conversion Health', 'health', child: Text(healthText, style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)))));
    if (topGrade != null) {
      cards.add(_insightTile(const Color(0xFFC084FC), 'Top Grade Demand', 'top-grade', child: Text.rich(TextSpan(children: [
        TextSpan(text: topGrade.gradeName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: ' has the most inquiries (${topGrade.count}).'),
      ]), style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)))));
    }
    return [
      for (var i = 0; i < cards.length; i++) Padding(padding: EdgeInsets.only(bottom: i < cards.length - 1 ? 10 : 0), child: cards[i]),
    ];
  }

  Widget _insightTile(Color borderColor, String title, String key, {required Widget child}) {
    return Container(
      key: ValueKey(key),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border(left: BorderSide(color: borderColor, width: 4)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('💡', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
