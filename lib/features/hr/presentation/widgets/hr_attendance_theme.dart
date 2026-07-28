import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Exact status metadata from the real, deployed `HrStaffAttendancePage`
/// (`app/(dashboard)/hr/attendance/page.tsx` on `origin/demo`) —
/// `STATUS_META`, matching the real `StaffAttendance.STATUS_CHOICES`
/// exactly (P/A/L/F/H).
class AttendanceStatusMeta {
  final String code;
  final String label;
  final Color color;
  final Color bg;
  const AttendanceStatusMeta(this.code, this.label, this.color, this.bg);
}

const kAttendanceStatuses = <AttendanceStatusMeta>[
  AttendanceStatusMeta('P', 'Present', Color(0xFF0A8C5A), Color(0xFFE4F6ED)),
  AttendanceStatusMeta('A', 'Absent', Color(0xFFC2264E), Color(0xFFFCE8EE)),
  AttendanceStatusMeta('L', 'Leave', Color(0xFF2563EB), Color(0xFFEFF6FF)),
  AttendanceStatusMeta('F', 'Half Day', Color(0xFFB4721B), Color(0xFFFDF1DC)),
  AttendanceStatusMeta('H', 'Holiday', Color(0xFF6B6B7B), Color(0xFFF1F1F5)),
];

AttendanceStatusMeta attendanceMetaFor(String code) => kAttendanceStatuses.firstWhere((m) => m.code == code, orElse: () => kAttendanceStatuses.first);

/// Matches web's `ringColor(pct)` exactly.
Color attendanceRingColor(double pct) {
  if (pct == 0) return const Color(0xFFD8D8E4);
  if (pct >= 90) return const Color(0xFF0A8C5A);
  if (pct >= 75) return const Color(0xFF4729F4);
  if (pct >= 50) return const Color(0xFFB4721B);
  return const Color(0xFFC2264E);
}

/// Matches web's `AttendanceRing` — donut showing a percentage.
class AttendanceRing extends StatelessWidget {
  final double pct;
  final double size;
  final double strokeWidth;

  const AttendanceRing({super.key, required this.pct, this.size = 38, this.strokeWidth = 3.5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size(size, size), painter: _RingPainter(pct: pct, strokeWidth: strokeWidth)),
        Text(pct == 0 ? '—' : '${pct.round()}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF0B0B14))),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final double strokeWidth;
  _RingPainter({required this.pct, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final bgPaint = Paint()
      ..color = const Color(0xFFF0F0F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);
    if (pct <= 0) return;
    final fgPaint = Paint()
      ..color = attendanceRingColor(pct)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweep = (pct.clamp(0, 100) / 100) * 2 * math.pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct;
}

/// Matches web's `KpiCard` in `HrAttendanceKPIs.tsx`, including the
/// optional `trend` text shown beside the value (e.g. "+0%"/"Same as
/// yesterday" — literal hardcoded placeholders on web too, not computed).
class AttendanceKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final String badge;
  final Color badgeBg;
  final Color badgeColor;
  final String? trend;
  final Color trendColor;

  const AttendanceKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    this.trend,
    this.trendColor = const Color(0xFF16A34A),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(label.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF64748B)))),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
              child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF111827), height: 1)),
            if (trend != null) Text(trend!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: trendColor)),
          ]),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }
}
