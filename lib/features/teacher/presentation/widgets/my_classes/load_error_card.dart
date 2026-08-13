import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

/// Shared icon + title + message + Retry card for My Classes' three error
/// surfaces (page-level, roster-level, profile-level) — mirrors web's
/// repeated "Could not load X" pattern exactly, kept local to this feature
/// rather than promoted to `core/widgets`.
class LoadErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const LoadErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.iconSize = 32,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: iconSize, color: AppColors.error),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandPurple,
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              backgroundColor: AppColors.purpleSoft,
            ),
          ),
        ],
      ),
    );
  }
}
