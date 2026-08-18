import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';

const _navBg = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFECECF2);
const _navPurple = Color(0xFF6D4AFF);
const _navInk3 = Color(0xFF9197AE);

class _ParentBottomNavTab {
  final String path;
  final String segment;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _ParentBottomNavTab({required this.path, required this.segment, required this.icon, required this.activeIcon, required this.label});
}

const _tabs = [
  _ParentBottomNavTab(path: '/parent/home', segment: 'home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
  _ParentBottomNavTab(path: '/parent/modules', segment: 'modules', icon: Icons.apps_outlined, activeIcon: Icons.apps_rounded, label: 'All Modules'),
  _ParentBottomNavTab(path: '/parent/profile', segment: 'profile', icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
];

/// Parent Portal's persistent bottom tab bar — a 1:1 structural port of
/// Admin's own `_GlobalBottomNav` (`global_app_shell.dart`), per explicit
/// request to give Parent the same top/bottom nav shape Admin has, in place
/// of Teacher's desktop-style header pills this portal previously copied.
/// Highlights by the current route's SECOND path segment (Parent routes are
/// always `/parent/<segment>`, unlike Admin's un-prefixed `/<segment>`).
class ParentBottomNav extends ConsumerWidget {
  const ParentBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentRoutePathProvider);
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    final currentSegment = segments.length >= 2 && segments[0] == 'parent' ? segments[1] : 'home';

    return Material(
      // Same reasoning as `_GlobalBottomNav` — this bar sits outside any
      // real `Navigator`/`Scaffold`, so it needs its own `Material` ancestor
      // for the tab `InkWell`s to paint ink splashes without throwing.
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(color: _navBg, border: Border(top: BorderSide(color: _navBorder))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (final tab in _tabs)
                  Expanded(
                    child: _TabButton(
                      tab: tab,
                      isActive: currentSegment == tab.segment,
                      onTap: () => ref.read(appRouterProvider).go(tab.path),
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

class _TabButton extends StatelessWidget {
  final _ParentBottomNavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.tab, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _navPurple : _navInk3;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isActive ? tab.activeIcon : tab.icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
