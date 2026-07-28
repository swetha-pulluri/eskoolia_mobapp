import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Attendance Layout Wrapper — top navigation bar for the Attendance
/// module, matching web's `components/nav/ModuleSubNav.tsx` for the
/// "attendance" module (`lib/routes.ts`: bg `#FFFBEB`, icon color `#B45309`)
/// exactly, following the same structure already established (and verified
/// pixel-for-pixel against the frontend) by `FeesLayout`/`FeesModuleSubNav`
/// and `AcademicsModuleSubNav`/`StudentModuleSubNav`.
///
/// The global app-wide header (logo, module strip, search, notifications,
/// avatar — web's `TopBarNew`) is mounted once above every route by
/// `GlobalAppShell` (see `main.dart`), so this widget only renders the
/// sub-nav row: a 20x20 `border-radius:6` icon chip (bg `#FFFBEB`, icon
/// `#B45309`) + 12px/w600 `#5A607A` "Attendance" label, separated by a
/// `#ECECF2` vertical rule from the tab strip. The tab strip's *active*
/// state always uses the shared brand purple `#6D4AFF` (matching every
/// other module's `ModuleSubNav`, not the module's own accent color), and
/// tab font-weight is always 600 regardless of active state — only color
/// and the 2px underline change. Web's Attendance nav currently has exactly
/// one sub-item, "Student Attendance", so this renders a single tab
/// (`ModuleSubNav` still renders for a 1-item `sub` array — it only hides
/// itself when `sub.length === 0`).
class AttendanceLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AttendanceLayout({super.key, required this.child, required this.currentPath});

  static const Color _moduleAccent = Color(0xFFB45309);
  static const Color _moduleChipBg = Color(0xFFFFFBEB);
  static const Color _activePurple = Color(0xFF6D4AFF);
  static const Color _inkSecondary = Color(0xFF5A607A);
  static const Color _hairline = Color(0xFFECECF2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _hairline)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 8, right: 12),
                  margin: const EdgeInsets.only(right: 7),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: _hairline)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _moduleChipBg, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.check_circle_outline, size: 11, color: _moduleAccent),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Attendance',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _inkSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildNavTab(context, icon: Icons.check_circle_outline, label: 'Student Attendance', path: '/attendance/student'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNavTab(BuildContext context, {required IconData icon, required String label, required String path}) {
    final isSelected = currentPath == path;
    return InkWell(
      onTap: isSelected ? null : () => context.go(path),
      child: Container(
        height: 46,
        padding: const EdgeInsets.fromLTRB(14, 1, 14, 0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? _activePurple : Colors.transparent, width: 2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? _activePurple : _inkSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? _activePurple : _inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
