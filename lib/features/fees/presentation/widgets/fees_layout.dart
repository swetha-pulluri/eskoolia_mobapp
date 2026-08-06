import 'package:flutter/material.dart';

/// Fees Layout Wrapper — thin Scaffold wrapper for the Fees module. The
/// sub-nav tab strip (web's `ModuleSubNav.tsx` for the "fees" module) is now
/// rendered once, globally, by `GlobalAppShell`'s shared `ModuleSubNav`
/// widget (data-driven off `ModuleEntity.subModules`), so this wrapper no
/// longer renders its own per-module copy.
class FeesLayout extends StatelessWidget {
  final Widget child;

  const FeesLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: child,
    );
  }
}
