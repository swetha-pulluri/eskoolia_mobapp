import 'package:flutter/material.dart';
import 'fees_module_sub_nav.dart';

/// Fees Layout Wrapper — top chrome for the Fees module: just
/// [FeesModuleSubNav] (matching web's `ModuleSubNav.tsx` for the "fees"
/// module). The global app-wide header (logo, module strip, search,
/// notifications, avatar — web's `TopBarNew`) is mounted once above every
/// route by `GlobalAppShell` (see `main.dart`), so this wrapper no longer
/// duplicates a second back-arrow/title row of its own.
class FeesLayout extends StatelessWidget {
  final Widget child;
  final FeesModuleTab activeTab;

  const FeesLayout({super.key, required this.child, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Column(
        children: [
          FeesModuleSubNav(active: activeTab),
          Expanded(child: child),
        ],
      ),
    );
  }
}
