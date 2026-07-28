import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'hr_theme.dart';

class _HrTab {
  final String label;
  final String path;
  final bool comingSoon;
  const _HrTab(this.label, this.path, {this.comingSoon = false});
}

/// Matches the real HR sub-nav (`lib/routes.ts` on the `demo` branch) — the
/// same 5 tabs shown in the deployed app, with Leave/Offboarding hardcoded
/// as "Soon" (non-clickable) in `ModuleSubNav.tsx`'s `COMING_SOON_PATHS`.
/// Only Setup has real Flutter content so far; the other 2 real (non-Soon)
/// tabs show a toast rather than navigating to an unbuilt screen.
class HrLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const HrLayout({super.key, required this.child, required this.currentPath});

  static const _tabs = [
    _HrTab('Setup', '/hr/setup'),
    _HrTab('Staff list & Onboarding', '/hr/directory'),
    _HrTab('Leave', '/hr/leave', comingSoon: true),
    _HrTab('Attendance', '/hr/attendance'),
    _HrTab('Offboarding', '/hr/offboarding', comingSoon: true),
  ];

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
                    height: 46,
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderPrimary, width: 1))),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [for (final tab in _tabs) _buildTab(context, tab)],
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

  Widget _buildTab(BuildContext context, _HrTab tab) {
    final isSelected = currentPath == tab.path;
    return GestureDetector(
      onTap: () {
        if (tab.comingSoon) return;
        if (tab.path == currentPath) return;
        if (tab.path == '/hr/setup' || tab.path == '/hr/directory' || tab.path == '/hr/attendance') {
          context.go(tab.path);
        } else {
          showHrToast(context, '${tab.label} is not built yet in the app', type: 'info');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? HrColors.brand : Colors.transparent, width: 2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? HrColors.brand : (tab.comingSoon ? const Color(0xFF9CA3AF) : AppColors.textSecondary),
            ),
          ),
          if (tab.comingSoon) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
              child: const Text('Soon', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
            ),
          ],
        ]),
      ),
    );
  }
}
