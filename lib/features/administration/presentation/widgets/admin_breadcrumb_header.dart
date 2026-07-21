import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Page-level breadcrumb header used by Complaints, Phone Call Log and
/// the Postal panels on web: `<h1>{title}</h1>` + a
/// `Dashboard / Admin Section / {title}` breadcrumb trail. Visitor Book
/// and Admin Setup do NOT have this header on web — omit it there.
class AdminBreadcrumbHeader extends StatelessWidget {
  final String title;

  const AdminBreadcrumbHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 6,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(
            'Dashboard / Admin Section / $title',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
