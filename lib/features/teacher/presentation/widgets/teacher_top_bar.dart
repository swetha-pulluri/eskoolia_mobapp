import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/module_nav_utils.dart';
import '../../../../core/widgets/global_app_shell.dart';
import '../../../../core/widgets/module_pill_with_flyout.dart';
import '../../../notes/presentation/widgets/note_trigger_button.dart';
import '../../../widgets_panel/presentation/widgets/widget_manager_button.dart';
import '../../domain/entities/teacher_module_entity.dart';

const _navBg = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navPurple = Color(0xFF6D4AFF);

/// Teacher Portal's own top nav bar — near-identical structure to Admin's
/// `_GlobalTopBar` (same logo/search/notes/widgets/notifications/avatar
/// cluster, same responsive collapse thresholds), but sourced from
/// [TeacherModules] instead of the admin `Modules` catalog, with no
/// back-arrow (Teacher Home has no "back" concept — matches web's
/// `(teacher-portal)/layout.tsx`, which never renders one either), and the
/// extra **"TEACHER"** role badge web adds next to the logo.
class TeacherTopBar extends ConsumerWidget {
  const TeacherTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentRoutePathProvider);
    final isHome = currentPath == '/teacher/home';
    final showWordmark = MediaQuery.sizeOf(context).width >= 400;
    final isNarrow = MediaQuery.sizeOf(context).width < 400;
    final trailingGap = isNarrow ? 3.0 : 6.0;

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
                InkWell(
                  onTap: () => ref.read(appRouterProvider).go('/teacher/home'),
                  borderRadius: BorderRadius.circular(9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
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
                      if (showWordmark) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'eskoolia',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _navInk1, letterSpacing: -0.3),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _TeacherRoleBadge(),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final m in TeacherModules.all) ModulePillWithFlyout(module: m, isActive: isModuleActive(m, currentPath)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isNarrow ? 2 : 4),
                // Wrapped in its own `Expanded` + horizontally-scrolling
                // `SingleChildScrollView` — matches the same fix in
                // `_GlobalTopBar` (`global_app_shell.dart`). At typical
                // widths this renders exactly as before (ample leftover
                // space after the modules `Expanded` above means nothing
                // visibly scrolls); on a very narrow window — well under
                // the ~400dp this bar's own `isNarrow` breakpoint assumes —
                // the combined width of these fixed icon buttons could
                // exceed what's left even with the modules row already
                // shrunk to 0, a real overflow this bar had no safety net
                // against. Scrolling instead of crashing matches the same
                // safety net already used for the modules row.
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SearchTrigger(),
                        SizedBox(width: trailingGap),
                        const NoteTriggerButton(),
                        if (isHome) ...[
                          SizedBox(width: trailingGap),
                          const WidgetManagerButton(),
                        ],
                        SizedBox(width: trailingGap),
                        const NotificationBellButton(),
                        SizedBox(width: trailingGap),
                        const AvatarMenu(),
                      ],
                    ),
                  ),
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
  const _TeacherRoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFEEEAFF), borderRadius: BorderRadius.circular(6)),
      child: const Text(
        'TEACHER',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: _navPurple),
      ),
    );
  }
}
