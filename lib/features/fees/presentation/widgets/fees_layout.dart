import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'fees_module_sub_nav.dart';

/// Fees Layout Wrapper — top chrome for the Fees module: a back-to-Home
/// breadcrumb row plus [FeesModuleSubNav], matching the same shell
/// convention already used by Attendance/Academics (`AttendanceLayout`,
/// `AcademicsModuleSubNav`'s host pages) for a module whose sub-nav is a
/// `ModuleSubNav.tsx` (`routes.ts`) entry rather than a page-owned header.
class FeesLayout extends StatelessWidget {
  final Widget child;
  final FeesModuleTab activeTab;

  const FeesLayout({super.key, required this.child, required this.activeTab});

  static const Color _accent = Color(0xFF0E7490);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
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
                      border: Border(bottom: BorderSide(color: Color(0xFFECECF2), width: 1)),
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
                        const Icon(Icons.payment_outlined, size: 20, color: _accent),
                        const SizedBox(width: 8),
                        const Text(
                          'Fees',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F1222)),
                        ),
                      ],
                    ),
                  ),
                  FeesModuleSubNav(active: activeTab),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
