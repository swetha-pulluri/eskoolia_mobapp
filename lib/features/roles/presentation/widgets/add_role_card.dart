import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Add New Role Card Widget
/// Dashed border card to add a new role
/// Source: frontend/components/access-control/RoleManagementPanel.tsx - "Add New Role" card
class AddRoleCard extends StatefulWidget {
  final VoidCallback? onTap;

  const AddRoleCard({super.key, this.onTap});

  @override
  State<AddRoleCard> createState() => _AddRoleCardState();
}

class _AddRoleCardState extends State<AddRoleCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isHovering = true),
      onTapUp: (_) => setState(() => _isHovering = false),
      onTapCancel: () => setState(() => _isHovering = false),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: _isHovering
              ? AppColors.dashedBorderHover
              : AppColors.dashedBorder,
          strokeWidth: 1.5,
          dashLength: 4,
          gapLength: 4,
          borderRadius: 10,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Dashed plus icon
              CustomPaint(
                painter: DashedBorderPainter(
                  color: _isHovering
                      ? AppColors.dashedBorderHover
                      : AppColors.dashedBorder,
                  strokeWidth: 1.5,
                  dashLength: 4,
                  gapLength: 4,
                  borderRadius: 8,
                ),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 18,
                        color: _isHovering
                            ? AppColors.dashedBorderHover
                            : AppColors.labelTextMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Label
              Text(
                'Add New Role',
                style: TextStyle(
                  fontSize: 12,
                  color: _isHovering
                      ? AppColors.dashedBorderHover
                      : AppColors.labelTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    // Create dashed path
    final dashPath = _createDashedPath(rect, dashLength, gapLength);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(RRect rect, double dashLength, double gapLength) {
    final path = Path();
    final perimeter = rect.width * 2 + rect.height * 2;
    double distance = 0;

    while (distance < perimeter) {
      // Calculate position on perimeter
      final point = _getPointOnPerimeter(rect, distance);
      final nextPoint = _getPointOnPerimeter(rect, distance + dashLength);

      path.moveTo(point.dx, point.dy);
      path.lineTo(nextPoint.dx, nextPoint.dy);

      distance += dashLength + gapLength;
    }

    return path;
  }

  Offset _getPointOnPerimeter(RRect rect, double distance) {
    final width = rect.width;
    final height = rect.height;
    final perimeter = width * 2 + height * 2;
    final normalizedDistance = distance % perimeter;

    if (normalizedDistance <= width) {
      // Top edge
      return Offset(normalizedDistance, 0);
    } else if (normalizedDistance <= width + height) {
      // Right edge
      return Offset(width, normalizedDistance - width);
    } else if (normalizedDistance <= width * 2 + height) {
      // Bottom edge
      return Offset(width - (normalizedDistance - width - height), height);
    } else {
      // Left edge
      return Offset(0, height - (normalizedDistance - width * 2 - height));
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
