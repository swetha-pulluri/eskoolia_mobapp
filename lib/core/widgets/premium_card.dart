import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Shared "premium" card shell for the Home screen: white surface,
/// generous rounded corners, a barely-there border, and a soft, wide
/// ambient shadow instead of a hard drop shadow — the look used across the
/// Greeting/Attention/Today's Pulse/Quick Access/Recently Visited/All
/// Modules cards for a consistent, modern School-ERP feel.
///
/// Purely decorative — carries no gesture handling of its own, so callers
/// keep whatever `Material`/`InkWell`/`GestureDetector`/`TapScale` they
/// already use for taps and press feedback; this only supplies the
/// background/border/radius/shadow.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;

  /// Border thickness — bumped above Flutter's 1.0 default so a card's
  /// accent border reads as a clear, thick "highlight" edge rather than a
  /// barely-there hairline.
  final double borderWidth;

  /// Overrides [color] with a gradient fill — used by the Greeting card's
  /// purple-to-magenta wash. When set, [color] is ignored.
  final Gradient? gradient;

  const PremiumCard({
    super.key,
    required this.child,
    this.margin,
    this.radius = 18,
    this.color,
    this.borderColor,
    this.borderWidth = 2,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.bg1) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border.withValues(alpha: 0.6), width: borderWidth),
        boxShadow: [
          BoxShadow(color: AppColors.ink1.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}
