import 'package:flutter/material.dart';

/// Custom painter for drawing sparklines (mini line charts)
/// Matches web sparkline implementation: 118x32px SVG polyline
/// 
/// Usage:
/// ```dart
/// CustomPaint(
///   size: Size(118, 32),
///   painter: SparklinePainter(
///     data: [10, 20, 15, 30, 25, 35, 30],
///     color: AppColors.successGreen,
///   ),
/// )
/// ```
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;

  SparklinePainter({
    required this.data,
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Find min and max values
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    // If all values are the same, draw a horizontal line
    if (range == 0) {
      final y = size.height / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
      return;
    }

    // Calculate points
    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      // Invert Y axis (0 at top, height at bottom)
      // Add padding at top and bottom
      final padding = 2.0;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * (size.height - padding * 2)) - padding;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
