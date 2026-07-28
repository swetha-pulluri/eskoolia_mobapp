import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// School Tenancy Layout Wrapper
/// Provides top navigation bar for all 5 School Tenancy pages.
///
/// The global app-wide header (logo, module strip, search, notifications,
/// avatar — web's `TopBarNew`) is mounted once above every route by
/// `GlobalAppShell` (see `main.dart`), so this wrapper only renders the
/// module's own tab strip, not a second back-arrow/title row.
class SchoolTenancyLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const SchoolTenancyLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          // Horizontal navigation tabs
          Container(
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.borderPrimary, width: 1),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavTab(
                  context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  path: '/super-admin/dashboard',
                ),
                const SizedBox(width: 8),
                _buildNavTab(
                  context,
                  icon: Icons.school_outlined,
                  label: 'Schools',
                  path: '/super-admin/schools',
                ),
                const SizedBox(width: 8),
                _buildNavTab(
                  context,
                  icon: Icons.payment_outlined,
                  label: 'Billing',
                  path: '/super-admin/billing',
                ),
                const SizedBox(width: 8),
                _buildNavTab(
                  context,
                  icon: Icons.list_alt_outlined,
                  label: 'Audit Log',
                  path: '/super-admin/audit',
                ),
                const SizedBox(width: 8),
                _buildNavTab(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Policies',
                  path: '/super-admin/policies',
                ),
              ],
            ),
          ),
          // Page content
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNavTab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
  }) {
    final isSelected = currentPath == path;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          context.go(path);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purpleTint : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

