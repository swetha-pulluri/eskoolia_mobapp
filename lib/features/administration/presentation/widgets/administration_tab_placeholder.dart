import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Placeholder body shown inside a main Administration tab until its
/// sub-tabs (e.g. Visitor Book, Complaints, Phone Calls) are implemented.
class AdministrationTabPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> subTabLabels;

  const AdministrationTabPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subTabLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sub-tabs (${subTabLabels.join(', ')}) coming soon',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
