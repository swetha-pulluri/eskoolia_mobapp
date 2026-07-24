import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mirrors frontend `components/nav/ModuleSubNav.tsx` for the Academics
/// module specifically (`MODULES.find(m => m.id === 'academics').sub` in
/// `lib/routes.ts`): a module-label chip (icon + "Academics") followed by
/// underline tabs, each with its own icon — "Timetable"/"Planning Studio"/
/// "Reports" carry a "Soon" badge and are non-interactive, exactly matching
/// `COMING_SOON_PATHS` in the reference.
enum AcademicsModuleTab { foundation, staffAssignment, timetable, planningStudio, reports }

class AcademicsModuleSubNav extends StatelessWidget {
  final AcademicsModuleTab active;

  const AcademicsModuleSubNav({super.key, required this.active});

  static const _tabs = [
    (AcademicsModuleTab.foundation, 'Foundation', Icons.grid_view_outlined, '/academics/core-setup', false),
    (AcademicsModuleTab.staffAssignment, 'Staff Assignment', Icons.people_outline, '/academics/staff-workspace', false),
    (AcademicsModuleTab.timetable, 'Timetable', Icons.calendar_month_outlined, '/academics/timetable', true),
    (AcademicsModuleTab.planningStudio, 'Planning Studio', Icons.menu_book_outlined, '/academics/planning-studio', true),
    (AcademicsModuleTab.reports, 'Reports', Icons.bar_chart_outlined, '/academics/academic-reports', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECECF2))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 8, right: 12),
              margin: const EdgeInsets.only(right: 7),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFECECF2))),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.school_outlined, size: 11, color: Color(0xFF5B4FCF)),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Academics',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5A607A)),
                  ),
                ],
              ),
            ),
            for (final tab in _tabs) _tabButton(context, tab.$1, tab.$2, tab.$3, tab.$4, tab.$5),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(BuildContext context, AcademicsModuleTab tab, String label, IconData icon, String path, bool comingSoon) {
    final isActive = tab == active;
    return InkWell(
      onTap: (isActive || comingSoon) ? null : () => context.go(path),
      child: Container(
        height: 46,
        padding: const EdgeInsets.fromLTRB(14, 1, 14, 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? const Color(0xFF6D4AFF) : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? const Color(0xFF6D4AFF) : const Color(0xFF5A607A)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF6D4AFF) : const Color(0xFF5A607A),
              ),
            ),
            if (comingSoon) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFF6D28D9), borderRadius: BorderRadius.circular(999)),
                child: const Text('Soon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
