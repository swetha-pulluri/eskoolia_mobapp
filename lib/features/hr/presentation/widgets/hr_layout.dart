import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// HR Layout Wrapper — thin Scaffold wrapper for the Human Resource module.
/// The sub-nav tab strip (web's `ModuleSubNav.tsx` for the "hr" module) is
/// rendered once, globally, by `GlobalAppShell`'s shared `ModuleSubNav`
/// widget (data-driven off `ModuleEntity.subModules`), so this wrapper no
/// longer renders its own per-module copy.
class HrLayout extends StatelessWidget {
  final Widget child;

  const HrLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: child,
    );
  }
}
