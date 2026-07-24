import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mirrors frontend `components/nav/ModuleSubNav.tsx` for the Students
/// module specifically (`MODULES.find(m => m.id === 'students').sub` in
/// `lib/routes.ts`): a module-label chip (icon + "Students", not shown for
/// `cleanTabs` modules — Students isn't one) followed by 4 underline tabs,
/// each with its own icon, exactly matching the reference's colors/sizes.
///
/// Scope note: only wired onto the Student Enroll & List screen for now (the
/// explicitly requested screen) — built as a standalone reusable widget so
/// the Multi Subject Assignment/Student Group/Student Promote screens can
/// adopt the same strip later without rebuilding it.
enum StudentModuleTab { enrollList, multiSubjectAssignment, studentGroup, studentPromote }

class StudentModuleSubNav extends StatelessWidget {
  final StudentModuleTab active;

  const StudentModuleSubNav({super.key, required this.active});

  static const _tabs = [
    (StudentModuleTab.enrollList, 'Student Enroll & List', Icons.people_outline, '/students'),
    (StudentModuleTab.multiSubjectAssignment, 'Multi Subject Assignment', Icons.school_outlined, '/students/multi-subject-assignment'),
    (StudentModuleTab.studentGroup, 'Student Group', Icons.how_to_reg_outlined, '/students/groups'),
    (StudentModuleTab.studentPromote, 'Student Promote', Icons.star_outline, '/students/promote'),
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
            // Module label chip — mirrors the non-cleanTabs branch exactly:
            // 20×20 rounded icon swatch (bg #FEF3F2 / icon #B42318, the
            // Students module's own colors) + "Students" 12px/600.
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
                    decoration: BoxDecoration(color: const Color(0xFFFEF3F2), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.people_outline, size: 11, color: Color(0xFFB42318)),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Students',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5A607A)),
                  ),
                ],
              ),
            ),
            for (final tab in _tabs) _tabButton(context, tab.$1, tab.$2, tab.$3, tab.$4),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(BuildContext context, StudentModuleTab tab, String label, IconData icon, String path) {
    final isActive = tab == active;
    return InkWell(
      onTap: isActive ? null : () => context.go(path),
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
          ],
        ),
      ),
    );
  }
}
