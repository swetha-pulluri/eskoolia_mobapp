import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// School Tenancy Layout Wrapper
/// Provides top navigation bar for all 5 School Tenancy pages
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
          // Top Navigation Bar
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header with back button and title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderPrimary, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () => context.go('/home'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.business_outlined, size: 20, color: AppColors.primaryPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'School Tenancy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Horizontal navigation tabs (matches web ModuleSubNav)
                  Container(
                    height: 46,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderPrimary, width: 1),
                      ),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _buildNavTab(
                          context,
                          icon: Icons.grid_view_outlined,
                          label: 'Dashboard',
                          path: '/super-admin/dashboard',
                        ),
                        _buildNavTab(
                          context,
                          icon: Icons.corporate_fare,
                          label: 'Schools',
                          path: '/super-admin/schools',
                        ),
                        _buildNavTab(
                          context,
                          icon: Icons.credit_card,
                          label: 'Billing',
                          path: '/super-admin/billing',
                        ),
                        _buildNavTab(
                          context,
                          icon: Icons.description_outlined,
                          label: 'Audit Log',
                          path: '/super-admin/audit',
                        ),
                        _buildNavTab(
                          context,
                          icon: Icons.settings_outlined,
                          label: 'Policies',
                          path: '/super-admin/policies',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryPurple : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

