import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/global_app_shell.dart';
import '../../../notes/presentation/widgets/note_trigger_button.dart';
import 'child_switcher.dart';

const _navBg = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk3 = Color(0xFF9197AE);
const _navPurple = Color(0xFF6D4AFF);

/// Which top-level nav tab (if any) the current path belongs to — same
/// concept as `global_app_shell.dart`'s own `_mainTabSegments`, checked
/// against the SECOND path segment since every Parent route is
/// `/parent/<segment>` (unlike Admin's un-prefixed `/<segment>`).
const _mainTabSegments = {'home', 'modules', 'profile'};

/// Parent Portal's top nav bar — restructured to match Admin's own
/// `_GlobalTopBar` + bottom-tab shape exactly, per explicit request to give
/// Parent the same top/bottom nav Admin has, replacing the desktop-style
/// header module-pills row this portal previously copied from Teacher (web
/// itself has neither a pills row nor a search trigger in its own
/// `(parent-portal)/layout.tsx` — this Flutter shell was already diverging
/// from web either way, so matching Admin's own already-accepted mobile
/// pattern is the more consistent choice than either prior version).
/// [ChildSwitcher] stays — Admin has no equivalent concept to omit, and
/// dropping it would lose real functionality (switching which child's data
/// is shown). The Home-only widget-manager button, the "PARENT" role badge,
/// and the avatar/logout dropdown are all dropped: widget toggling isn't
/// exposed from Parent's nav at all now (per explicit request, matching
/// Admin no longer exposing its own Widgets tab either), and logout now
/// lives on the bottom-nav Profile tab instead, exactly mirroring Admin's
/// own `ProfilePage` (see its doc comment — Admin made this identical move
/// away from a header avatar dropdown already).
class ParentTopBar extends ConsumerWidget {
  const ParentTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentRoutePathProvider);
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    final currentSegment = segments.length >= 2 && segments[0] == 'parent' ? segments[1] : 'home';
    final isMainTab = _mainTabSegments.contains(currentSegment);
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final trailingGap = isNarrow ? 4.0 : 8.0;

    return Material(
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
                        router.go('/parent/home');
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
                  onTap: () => ref.read(appRouterProvider).go('/parent/home'),
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
                      const SizedBox(width: 8),
                      const Text(
                        'Eskoolia',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _navInk1, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                ),
                // `Expanded` + horizontally-scrolling `SingleChildScrollView`
                // (no separate `Spacer` needed) — Admin's own
                // `_GlobalTopBar` trailing cluster is just 3 narrow icon
                // buttons that always fit next to a plain `Spacer`, but
                // Parent's also carries `ChildSwitcher` (avatar + name +
                // class chip, no Admin equivalent), which is wide enough to
                // overflow this Row on a narrow viewport. Deliberately no
                // `reverse: true` here (an earlier version of this fix used
                // it to hug the right edge) — plain forward scrolling is the
                // exact safety net `TeacherTopBar` already uses without
                // issue; the trade-off is the cluster sits left-aligned
                // after the logo instead of flush against the right edge
                // when there's spare room, which is purely cosmetic.
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ChildSwitcher(),
                        SizedBox(width: trailingGap),
                        const SearchTrigger(),
                        SizedBox(width: trailingGap),
                        const NotificationBellButton(),
                        SizedBox(width: trailingGap),
                        const NoteTriggerButton(),
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
