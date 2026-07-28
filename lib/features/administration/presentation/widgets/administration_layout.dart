import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Administration Layout Wrapper
/// Provides the top navigation bar for the 4 Administration main tabs
/// (Communication Hub, Postal Management, Documents Studio, System Config),
/// matching the web frontend's `ModuleSubNav` styling for the "admin" module.
///
/// The global app-wide header (logo, module strip, search, notifications,
/// avatar — web's `TopBarNew`) is mounted once above every route by
/// `GlobalAppShell` (see `main.dart`), so this wrapper only renders the
/// module's own tab strip, not a second back-arrow/title row.
class AdministrationLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AdministrationLayout({
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
          // Horizontal navigation tabs (matches web ModuleSubNav)
          Container(
            height: 46,
            decoration: const BoxDecoration(
              color: Colors.white,
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
                  icon: Icons.person_search_outlined,
                  label: 'Communication Hub',
                  path: '/administration/communication-hub',
                ),
                _buildNavTab(
                  context,
                  icon: Icons.mail_outline,
                  label: 'Postal Management',
                  path: '/administration/postal',
                ),
                _buildNavTab(
                  context,
                  icon: Icons.badge_outlined,
                  label: 'Documents Studio',
                  path: '/administration/documents',
                ),
                _buildNavTab(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'System Config',
                  path: '/administration/system-config',
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
