import 'package:flutter/material.dart';
import '../../domain/models/fees_summary.dart';
import '../utils/fees_format.dart';

class _KpiSpec {
  final String label;
  final String value;
  final String sub;
  final Color border;
  const _KpiSpec({required this.label, required this.value, required this.sub, required this.border});
}

/// The 4 KPI cards atop Fees Home — mirrors FeesPaymentsPanel.tsx's
/// `dynamicKPIs` (card style, uppercase label, 26px value, coloured
/// left border). Web lays these out as a 4-column CSS grid; adapted here to
/// a 2-column auto-height grid (same responsive convention already used by
/// `admissions_analytics_page.dart`'s `_autoHeightGrid`) since a phone
/// viewport can't fit 4 columns without squeezing the numbers unreadable.
class FeesKpiCards extends StatelessWidget {
  final FeesSummary? summary;

  const FeesKpiCards({super.key, this.summary});

  String _amt(String Function(FeesSummary) pick) =>
      summary == null ? 'Rs. 0' : 'Rs. ${feesFormatAmountFromString(pick(summary!))}';

  @override
  Widget build(BuildContext context) {
    final kpis = [
      _KpiSpec(label: 'TOTAL ASSIGNED', value: _amt((s) => s.totalAssigned), sub: 'Net total assigned', border: const Color(0xFF3B82F6)),
      _KpiSpec(label: 'TOTAL COLLECTED', value: _amt((s) => s.totalPaid), sub: 'Total payments posted', border: const Color(0xFF16A34A)),
      _KpiSpec(label: 'OUTSTANDING DUES', value: _amt((s) => s.totalDue), sub: 'Amount pending collection', border: const Color(0xFFF59E0B)),
      _KpiSpec(label: 'TOTAL DISCOUNT', value: _amt((s) => s.totalDiscount), sub: 'Discounts & concessions', border: const Color(0xFF8B5CF6)),
    ];
    return _autoHeightGrid(spacing: 16, children: kpis.map(_card).toList());
  }

  Widget _card(_KpiSpec kpi) {
    // A `Border` can't mix per-side colors with a `borderRadius` (Flutter
    // throws "borderRadius can only be given on borders with uniform
    // colors") — so the coloured left accent is a clipped strip inside a
    // uniformly-bordered, rounded outer container instead of a 4-colour
    // `Border`.
    final radius = BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFECECF2)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: kpi.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kpi.label,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: Color(0xFF9197AE)),
                    ),
                    const SizedBox(height: 10),
                    // `FittedBox` + `maxLines: 1` instead of letting the
                    // amount wrap — an unbroken number like "1,79,000" has
                    // no space to wrap at, so a plain `Text` was
                    // force-breaking mid-digit ("1,79,00" / "0" on its own
                    // line) once the card got too narrow for 26px text.
                    // Scaling the whole line down to fit keeps it on one
                    // line always, which also shrinks the card's height
                    // back down instead of spending an extra wrapped line.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        kpi.value,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFF0F1222)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(kpi.sub, style: const TextStyle(fontSize: 13, color: Color(0xFF9197AE))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
