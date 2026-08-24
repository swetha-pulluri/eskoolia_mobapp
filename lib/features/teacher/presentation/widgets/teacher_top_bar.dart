import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/global_app_shell.dart';
import '../../../notes/presentation/widgets/note_trigger_button.dart';

const _navBg = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFECECF2);
const _navInk3 = Color(0xFF9197AE);
const _navPurple = Color(0xFF6D4AFF);

/// Teacher Portal's top bar — logo, TEACHER badge, and exactly three
/// trailing icons: Search, Sticky Notes, Notifications. The module-pill
/// navigation strip that used to sit between the badge and those icons was
/// removed per explicit request; top-level module browsing still lives on
/// the bottom nav's "All Modules" tab. No avatar/profile icon here — that's
/// the bottom nav's
/// Profile tab; logout lives on `TeacherProfilePage` accordingly (same
/// precedent Admin's own `_GlobalTopBar` set when its Profile bottom-nav tab
/// replaced its avatar menu — see that class's doc comment on `AvatarMenu`).
/// No Widgets icon either (Admin-only concept). Deliberately no dynamic page
/// title here — per explicit user direction, the bar must not switch to
/// showing whichever module/route is currently open (e.g. "All Mo…" while
/// on the All Modules tab); it stays the same regardless of route. Still
/// shows a back chevron on non-main-tab routes so users can navigate up.
/// [ModuleSubNav] (a separate sibling widget in `GlobalAppShell`, not part
/// of this bar) still provides contextual sub-tabs for whichever module
/// you're inside.
class TeacherTopBar extends ConsumerWidget {
  const TeacherTopBar({super.key});

  static const _mainTabPaths = {'/teacher/home', '/teacher/modules', '/teacher/profile'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentRoutePathProvider);
    final isMainTab = _mainTabPaths.contains(currentPath);
    final isNarrow = MediaQuery.sizeOf(context).width < 380;
    final trailingGap = isNarrow ? 4.0 : 8.0;

    return Material(
      // Same reasoning as `_GlobalTopBar` — mounted outside any routed
      // `Scaffold`/`Material` ancestor.
      type: MaterialType.transparency,
      child: Container(
        color: _navBg,
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _navBorder))),
            child: Row(
              children: [
                if (!isMainTab) ...[
                  InkWell(
                    onTap: () {
                      final router = ref.read(appRouterProvider);
                      if (router.canPop()) {
                        router.pop();
                      } else {
                        // Reached this module/submodule via "All Modules"
                        // (a `go()`, not a `push()`), so `canPop()` is false
                        // with no Home entry underneath to pop to. Falling
                        // back to All Modules instead of Home avoids the
                        // extra Home → All Modules → pick-another-module
                        // round trip.
                        router.go('/teacher/modules');
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_left, size: 18, color: _navInk3),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                InkWell(
                  onTap: () => ref.read(appRouterProvider).go('/teacher/home'),
                  borderRadius: BorderRadius.circular(9),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      AppConstants.eskooliaLogo,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: _navPurple, borderRadius: BorderRadius.circular(9)),
                        alignment: Alignment.center,
                        child: const Text('e', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isNarrow ? 6 : 8),
                _TeacherRoleBadge(isNarrow: isNarrow),
                // Module-pill navigation strip removed here per explicit
                // request — top-level module browsing still lives on the
                // bottom nav's "All Modules" tab, so it isn't lost, just no
                // longer duplicated in the top bar. `Spacer` pushes the
                // trailing icon row (Search/Notes/Notifications) to the far
                // right, same position they held before.
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SearchTrigger(),
                    SizedBox(width: trailingGap),
                    const NoteTriggerButton(),
                    SizedBox(width: trailingGap),
                    const NotificationBellButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exact port of the inline JSX badge in `(teacher-portal)/layout.tsx`:
/// text "Teacher" rendered uppercase, 10px/700/0.08em letter-spacing,
/// purple text on a light-lavender pill, 6px radius, 3/8 padding.
class _TeacherRoleBadge extends StatelessWidget {
  final bool isNarrow;
  const _TeacherRoleBadge({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFEEEAFF), borderRadius: BorderRadius.circular(6)),
      child: const Text(
        'TEACHER',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: _navPurple),
      ),
    );
  }
}
