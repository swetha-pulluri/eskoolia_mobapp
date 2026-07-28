import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Admissions Layout Wrapper — top navigation bar for the 3 Admissions
/// sections (Command Center, Analytics, Marketing), matching web's
/// `routes.ts` sub-nav entry for the "admissions" module:
///   Command Center → LayoutGrid icon
///   Analytics       → BarChart2 icon
///   Marketing       → Send icon
///
/// The global app-wide header (logo, module strip, search, notifications,
/// avatar — web's `TopBarNew`) is mounted once above every route by
/// `GlobalAppShell` (see `main.dart`), so this wrapper only renders the
/// module's own tab strip (web's `ModuleSubNav`), not a second
/// back-arrow/title row.
class AdmissionsLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AdmissionsLayout({super.key, required this.child, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Container(
              height: 46,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderPrimary, width: 1)),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildNavTab(context, icon: Icons.grid_view_outlined, label: 'Command Center', path: '/admissions/command-center'),
                  _buildNavTab(context, icon: Icons.bar_chart_outlined, label: 'Analytics', path: '/admissions/analytics'),
                  _buildNavTab(context, icon: Icons.send_outlined, label: 'Marketing', path: '/admissions/marketing'),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNavTab(BuildContext context, {required IconData icon, required String label, required String path}) {
    final isSelected = currentPath == path;
    return GestureDetector(
      onTap: () {
        if (!isSelected) context.go(path);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent, width: 2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
