import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Attendance Layout Wrapper — top navigation bar for the Attendance
/// module, matching web's `ModuleSubNav` for the "attendance" module
/// (`routes.ts`: bg `#FFFBEB`, icon color `#B45309`). Web's Attendance
/// nav currently has exactly one sub-item, "Student Attendance", so this
/// renders a single tab (`ModuleSubNav` still renders for a 1-item sub
/// array — it only hides itself when `sub.length === 0`).
class AttendanceLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AttendanceLayout({super.key, required this.child, required this.currentPath});

  static const Color _accent = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderPrimary, width: 1)),
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
                        const Icon(Icons.how_to_reg_outlined, size: 20, color: _accent),
                        const SizedBox(width: 8),
                        const Text(
                          'Attendance',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 46,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderPrimary, width: 1)),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _buildNavTab(context, icon: Icons.how_to_reg_outlined, label: 'Student Attendance', path: '/attendance/student'),
                      ],
                    ),
                  ),
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
          border: Border(bottom: BorderSide(color: isSelected ? _accent : Colors.transparent, width: 2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? _accent : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
