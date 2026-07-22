import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Threshold-based ring color — converted from web
/// `attendanceHelpers.ts`'s `ringColor()`.
Color ringColor(int pct) {
  if (pct >= 85) return const Color(0xFF4729F4);
  if (pct >= 70) return const Color(0xFFB4721B);
  return const Color(0xFFC2264E);
}

/// Attendance Ring — converted from web
/// `attendance/student/components/AttendanceRing.tsx`.
class AttendanceRing extends StatelessWidget {
  final int pct;
  final double size;
  final double strokeWidth;

  const AttendanceRing({super.key, required this.pct, this.size = 34, this.strokeWidth = 3});

  @override
  Widget build(BuildContext context) {
    final color = pct == 0 ? const Color(0xFFD8D8E4) : ringColor(pct);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _RingPainter(pct: pct, strokeWidth: strokeWidth, color: color)),
          Text(pct == 0 ? '—' : '$pct%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int pct;
  final double strokeWidth;
  final Color color;
  _RingPainter({required this.pct, required this.strokeWidth, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: r);
    final bg = Paint()
      ..color = const Color(0xFFF0F0F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, r, bg);
    if (pct > 0) {
      final fg = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweep = 2 * math.pi * (pct.clamp(0, 100) / 100);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}
