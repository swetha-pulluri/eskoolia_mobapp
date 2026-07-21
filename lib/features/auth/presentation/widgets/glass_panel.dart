import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Glass Panel Widget
/// Exact replica of .glass-panel from frontend/app/globals.css
/// Used for header with glassmorphism effect
/// 
/// CSS:
/// ```css
/// .glass-panel {
///   backdrop-filter: blur(20px);
///   background: rgba(255, 255, 255, 0.7);
///   border: 1px solid rgba(255, 255, 255, 0.4);
/// }
/// ```
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // blur(20px)
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassPanelBackground, // rgba(255,255,255,0.7)
            border: Border.all(
              color: AppColors.glassStroke, // rgba(255,255,255,0.4)
              width: 1,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass Card Widget
/// Exact replica of .glass-card from frontend/app/globals.css
/// Used for main command hub card
/// 
/// CSS:
/// ```css
/// .glass-card {
///   backdrop-filter: blur(40px);
///   background: rgba(255, 255, 255, 0.9);
///   border: 1px solid rgba(255, 255, 255, 0.8);
///   box-shadow: 0 40px 80px -15px rgba(49, 46, 129, 0.12);
/// }
/// ```
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), // blur(40px)
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassCardBackground, // rgba(255,255,255,0.9)
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.8), // rgba(255,255,255,0.8)
              width: 1,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.atriumIndigo.withValues(alpha: 0.12),
                blurRadius: 80,
                offset: const Offset(0, 40),
                spreadRadius: -15,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
