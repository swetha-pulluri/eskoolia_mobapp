import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

/// Shared body for the Homework/Communication/Notes tabs — web renders
/// these as static "Coming in Sprint N" placeholders today (no backend
/// data behind them at all), so this mirrors that exactly rather than
/// building a fake feature.
class PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtext;

  const PlaceholderTab({super.key, required this.icon, required this.label, required this.subtext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.purpleSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: AppColors.brandPurple),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink1)),
            const SizedBox(height: 4),
            Text(subtext, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }
}
