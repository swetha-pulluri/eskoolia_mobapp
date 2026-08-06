import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// School Tenancy Layout Wrapper — thin Scaffold wrapper for the School
/// Tenancy module. The sub-nav tab strip (web's `ModuleSubNav.tsx` for the
/// "super_admin" module) is rendered once, globally, by `GlobalAppShell`'s
/// shared `ModuleSubNav` widget (data-driven off `ModuleEntity.subModules`),
/// so this wrapper no longer renders its own per-module copy.
class SchoolTenancyLayout extends StatelessWidget {
  final Widget child;

  const SchoolTenancyLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: child,
    );
  }
}
