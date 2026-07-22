import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Progress bar widget matching web frontend
/// Height: 7px, rounded corners, colored fill
/// 
/// Usage:
/// ```dart
/// ProgressBar(
///   value: 0.5, // 50%
///   color: AppColors.boardCBSE,
/// )
/// ```
class ProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 7.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
