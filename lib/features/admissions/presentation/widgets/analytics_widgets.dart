import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/analytics_data_entity.dart';

/// Inline sparkline — converted from web's hand-rolled inline SVG
/// `Sparkline` component in `AdmissionsAnalytics.tsx`.
class Sparkline extends StatelessWidget {
  final List<int> data;
  final Color color;
  const Sparkline({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 80, height: 32, child: CustomPaint(painter: _SparklinePainter(data: data, color: color)));
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> data;
  final Color color;
  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const pad = 2.0;
    final w = size.width, h = size.height;
    final maxV = data.fold<int>(1, (m, v) => v > m ? v : m).toDouble();
    final xs = List.generate(data.length, (i) => data.length == 1 ? w / 2 : pad + (i / (data.length - 1)) * (w - pad * 2));
    final ys = data.map((v) => pad + (1 - v / maxV) * (h - pad * 2)).toList();

    final linePath = Path()..moveTo(xs.first, ys.first);
    for (var i = 1; i < xs.length; i++) {
      linePath.lineTo(xs[i], ys[i]);
    }
    final areaPath = Path.from(linePath)
      ..lineTo(xs.last, h - pad)
      ..lineTo(pad, h - pad)
      ..close();

    canvas.drawPath(areaPath, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.data != data || oldDelegate.color != color;
}

/// KPI card with count-up animation — converted from web's `KPICard`.
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final bool isPercent;
  final String? sub;
  final Color iconBg;
  final Color iconColor;
  final List<int> sparkData;
  final Color sparkColor;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconColor,
    required this.sparkData,
    required this.sparkColor,
    this.isPercent = false,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(999)),
                child: const Text('↑ live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, v, _) => Text('${v.round()}${isPercent ? "%" : ""}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ),
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Sparkline(data: sparkData, color: sparkColor),
          if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub!, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))),
        ],
      ),
    );
  }
}

/// Semi-circular gauge — converted from web's `SemiGauge`.
class SemiGauge extends StatelessWidget {
  final int pct;
  final Color color;
  const SemiGauge({super.key, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 80, height: 48, child: CustomPaint(painter: _SemiGaugePainter(pct: pct, color: color)));
  }
}

class _SemiGaugePainter extends CustomPainter {
  final int pct;
  final Color color;
  _SemiGaugePainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const r = 34.0, sw = 7.0;
    final center = Offset(40, 44);
    final rect = Rect.fromCircle(center: center, radius: r);
    final bg = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, bg);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    final sweep = math.pi * (pct.clamp(0, 100) / 100);
    canvas.drawArc(rect, math.pi, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}

/// Conversion funnel with drop-off rates — converted from web's `FunnelViz`.
class FunnelViz extends StatelessWidget {
  final int total;
  final int contacted;
  final int visited;
  final int enrolled;
  const FunnelViz({super.key, required this.total, required this.contacted, required this.visited, required this.enrolled});

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('Inquiry', total, const Color(0xFF3B82F6)),
      ('Contacted', contacted, const Color(0xFF14B8A6)),
      ('Visited', visited, const Color(0xFFF59E0B)),
      ('Enrolled', enrolled, const Color(0xFF22C55E)),
    ];
    return Column(
      children: List.generate(stages.length, (i) {
        final (label, count, color) = stages[i];
        final pctOfTotal = total > 0 ? count / total * 100 : 0.0;
        final barW = math.max(pctOfTotal, 8.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                SizedBox(width: 62, child: Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)))),
                Expanded(
                  child: Container(
                    height: 26,
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (barW / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 36, child: Text('${pctOfTotal.round()}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)))),
              ]),
              if (i < stages.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 78, top: 1, bottom: 1),
                  child: Text(
                    '↓ -${(((stages[i].$2 - stages[i + 1].$2) / math.max(stages[i].$2, 1)) * 100).round()}% drop-off',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFFF87171)),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// 6-month trend area chart — converted from web's `recharts` `AreaChart`
/// (the only real chart-library element in the whole Admissions module).
/// No chart package exists in this project, so this is a small custom
/// `CustomPainter` reproducing the same two series (Inquiries filled area,
/// Enrolled line-only) over a light grid, matching layout and colors.
class TrendChart extends StatelessWidget {
  final List<MonthlyTrendPoint> points;
  const TrendChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(painter: _TrendChartPainter(points: points)),
    );
  }
}

const List<String> _kMonthAbbrev = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatMonthLabel(String iso) {
  final parts = iso.split('-');
  if (parts.length < 2) return iso;
  final m = int.tryParse(parts[1]) ?? 1;
  final yy = parts[0].length >= 2 ? parts[0].substring(2) : parts[0];
  return '${_kMonthAbbrev[(m - 1).clamp(0, 11)]} $yy';
}

class _TrendChartPainter extends CustomPainter {
  final List<MonthlyTrendPoint> points;
  _TrendChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const leftPad = 4.0, rightPad = 4.0, topPad = 8.0, bottomPad = 20.0;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;
    final maxV = points.fold<int>(1, (m, p) => math.max(m, math.max(p.inquiries, p.enrolled))).toDouble();

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final y = topPad + chartH * g / 3;
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
    }

    double xAt(int i) => points.length == 1 ? leftPad + chartW / 2 : leftPad + (i / (points.length - 1)) * chartW;
    double yAt(int v) => topPad + (1 - v / maxV) * chartH;

    // Inquiries filled area
    final inquiriesPath = Path()..moveTo(xAt(0), yAt(points[0].inquiries));
    for (var i = 1; i < points.length; i++) {
      inquiriesPath.lineTo(xAt(i), yAt(points[i].inquiries));
    }
    final areaPath = Path.from(inquiriesPath)
      ..lineTo(xAt(points.length - 1), topPad + chartH)
      ..lineTo(xAt(0), topPad + chartH)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF3B82F6).withValues(alpha: 0.25), const Color(0xFF3B82F6).withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH)),
    );
    canvas.drawPath(inquiriesPath, Paint()..color = const Color(0xFF3B82F6)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Enrolled line only
    final enrolledPath = Path()..moveTo(xAt(0), yAt(points[0].enrolled));
    for (var i = 1; i < points.length; i++) {
      enrolledPath.lineTo(xAt(i), yAt(points[i].enrolled));
    }
    canvas.drawPath(enrolledPath, Paint()..color = const Color(0xFF22C55E)..style = PaintingStyle.stroke..strokeWidth = 2);

    // X axis labels
    for (var i = 0; i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: formatMonthLabel(points[i].month), style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xAt(i) - tp.width / 2, size.height - bottomPad + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => oldDelegate.points != points;
}
