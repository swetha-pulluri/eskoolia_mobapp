import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_assets.dart';
import '../../config/router/app_router.dart';
import '../../features/ai_assistant/presentation/widgets/search_command_palette.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/dashboard/domain/entities/module_entity.dart';
import '../../features/notes/presentation/widgets/note_trigger_button.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/notifications/presentation/widgets/notification_panel.dart';
import '../../features/parent/domain/entities/parent_module_entity.dart';
import '../../features/parent/presentation/widgets/parent_bottom_nav.dart';
import '../../features/parent/presentation/widgets/parent_top_bar.dart';
import '../../features/teacher/domain/entities/teacher_module_entity.dart';
import '../../features/teacher/presentation/widgets/teacher_top_bar.dart';
import '../../features/widgets_panel/presentation/providers/widget_prefs_provider.dart';
import '../providers/module_flyout_provider.dart';
import 'module_pill_with_flyout.dart';
import 'module_sub_nav.dart';

const _navBg = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk2 = Color(0xFF5A607A);
const _navInk3 = Color(0xFF9197AE);
const _navPurple = Color(0xFF6D4AFF);

/// Which top-level nav tab (if any) [path] belongs to — drives both the
/// bottom nav's active highlight and the top bar's back-button visibility
/// (main tabs are reached directly from the bottom nav, so they never need
/// a "back" affordance).
const _mainTabSegments = {'', 'home', 'modules', 'widgets', 'profile'};

/// Global application shell — mobile-native redesign of frontend's
/// `(dashboard)/layout.tsx` + `components/nav/TopBar.tsx`: a persistent top
/// bar (logo/name, search, notifications, sticky notes) plus a persistent
/// bottom tab bar (Home / Modules / Widgets / Profile) that together wrap
/// every authenticated Admin route. Teacher Portal keeps its own separate
/// desktop-style top bar/module catalog (`TeacherTopBar`/`TeacherModules`,
/// module pills + no bottom nav). Parent Portal instead reuses Admin's own
/// top+bottom nav *shape* (`ParentTopBar`/`ParentBottomNav`, sourced from
/// `ParentNavModules`) per explicit product decision, rather than Teacher's
/// pills — same shared flyout-overlay Stack below either way.
///
/// Mounted once via `MaterialApp.router`'s `builder:` in `main.dart`. This
/// means every widget in this file is a *sibling* of the actual routed
/// content (`child`/`routedChild`), not a descendant of it — the routed
/// `Navigator`/`InheritedGoRouter`/`Overlay` all live *inside* `child`'s own
/// subtree, built by go_router's `RouterDelegate`. Concretely: no widget
/// here can use `context.go()`/`context.push()`/`context.pop()`/
/// `Navigator.of(context)`/`showDialog(context: ...)` with its *own*
/// BuildContext — those all look for an ancestor that doesn't exist from
/// this position in the tree, and throw ("No GoRouter found in context" /
/// "No Navigator found"). Every navigation/dialog/menu call below instead
/// goes through the [appRouterProvider] `GoRouter` instance directly (its
/// `go`/`pop`/`canPop` methods need no BuildContext), or through that
/// router's own root `navigatorKey` when an actual `Navigator`/`Overlay`
/// context is required (dialogs, popup menus, imperative `MaterialPageRoute`
/// pushes).
class GlobalAppShell extends ConsumerWidget {
  final Widget child;

  const GlobalAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.maybeWhen(authenticated: (_) => true, orElse: () => false);

    // Pre-login (splash/login screen) has no shell in the reference
    // frontend either — `(dashboard)/layout.tsx` only wraps the
    // authenticated route group.
    if (!isAuthenticated) return child;

    // Student still lands on a disclosed "not implemented yet" page (see
    // portal_routes.dart) rather than the Admin Dashboard — it has no
    // access to the admin module nav, so it must not wrap it either.
    // Teacher gets its own real shell below (`TeacherTopBar`+
    // `TeacherModules`, desktop-style pills, no bottom nav). Parent gets
    // Admin's own top+bottom nav shape instead (`ParentTopBar`+
    // `ParentBottomNav`, sourced from `ParentNavModules`) — same
    // flyout-overlay Stack either way. Everything else (`'admin'`, the
    // `currentPortalRoleProvider` fallback) falls through to the existing
    // Admin chrome further down.
    final role = ref.watch(currentPortalRoleProvider);
    if (role == 'student') return child;

    final isTeacher = role == 'teacher';
    final isParent = role == 'parent';
    final flyoutTarget = ref.watch(moduleFlyoutProvider);

    return Stack(
      children: [
        Column(
          children: [
            if (isTeacher)
              const TeacherTopBar()
            else if (isParent)
              const ParentTopBar()
            else
              const _GlobalTopBar(),
            if (isTeacher)
              ModuleSubNav(modules: TeacherModules.all)
            else if (isParent)
              ModuleSubNav(modules: ParentNavModules.all)
            else
              const ModuleSubNav(),
            Expanded(child: child),
<<<<<<< Updated upstream
            // Admin gets Home/All Modules/Widgets/Profile; Teacher gets its
            // own Home/All Modules/Profile bar (no Widgets tab — that
            // preference panel is an Admin-only concept). Both reuse the
            // same generic `_BottomNavButton`, just different tab lists.
            if (isTeacher) const _TeacherBottomNav() else const _GlobalBottomNav(),
=======
            // Teacher is the only portal with no bottom nav — its own
            // `/teacher/*` route tree and desktop-style header pills have no
            // use for these tabs. Admin gets its own tabs; Parent gets its
            // own `ParentBottomNav` (`/parent/home`, `/parent/modules`,
            // `/parent/profile`) instead of Admin's un-prefixed paths.
            if (isParent)
              const ParentBottomNav()
            else if (!isTeacher)
              const _GlobalBottomNav(),
>>>>>>> Stashed changes
          ],
        ),
        if (flyoutTarget != null) ...[
          // `Listener.onPointerDown` (not `GestureDetector.onTap`) so this
          // full-screen dismiss layer never enters the gesture arena against
          // a module pill's own `InkWell` underneath it. A `GestureDetector`
          // here previously competed for the same tap — since this overlay
          // painted on top of the whole module strip whenever a flyout was
          // open (including one opened by an incidental mouse-hover on the
          // way to clicking a different pill), that first tap closed the
          // flyout instead of reaching the pill, and only a second tap
          // actually navigated. `Listener` fires immediately on pointer-down
          // without claiming the gesture, so the flyout closes AND the pill
          // underneath still receives its own tap in the same gesture.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => ref.read(moduleFlyoutProvider.notifier).closeNow(),
              child: const SizedBox.expand(),
            ),
          ),
          Builder(
            builder: (context) {
              final module = isTeacher
                  ? TeacherModules.findById(flyoutTarget.moduleId)
                  : isParent
                      ? ParentNavModules.findById(flyoutTarget.moduleId)
                      : Modules.findById(flyoutTarget.moduleId);
              if (module == null) return const SizedBox.shrink();
              return ModuleFlyoutPanel(module: module, top: flyoutTarget.top, left: flyoutTarget.left);
            },
          ),
        ],
      ],
    );
  }
}

class _GlobalTopBar extends ConsumerWidget {
  const _GlobalTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentRoutePathProvider);
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    final currentSegment = segments.isNotEmpty ? segments.first : '';
    // Bottom-nav tabs are reached directly from the bar below, so they
    // never need a "back" affordance — only pushed/deep-linked screens do.
    final isMainTab = _mainTabSegments.contains(currentSegment);
    // Extra headroom on the narrowest real devices (~320px logical width):
    // tighten the outer padding and the trailing cluster's inter-item
    // spacing so there's real margin left, not just an exact fit.
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final trailingGap = isNarrow ? 4.0 : 8.0;

    return Material(
      // `_GlobalTopBar` is mounted above every route's own `Scaffold` (via
      // `MaterialApp.router`'s `builder:`), so it has no `Material` ancestor
      // of its own — without this, every `InkWell` below (back arrow, logo,
      // search/notification/notes icons) throws "No Material widget found"
      // the moment this bar first builds.
      // `type: transparency` keeps the existing `Container` colors as the
      // actual paint, matching how `AiPanel` already solves the same
      // problem for its own out-of-Scaffold widget tree.
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
                        router.go('/home');
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
                  onTap: () => ref.read(appRouterProvider).go('/home'),
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
                const Spacer(),
                const SearchTrigger(),
                SizedBox(width: trailingGap),
                const NotificationBellButton(),
                SizedBox(width: trailingGap),
                const NoteTriggerButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header "Search" button — Flutter port of `TopBar.tsx`'s search
/// pill/icon, opening [showSearchCommandPalette]. Collapses to icon-only
/// below 900px (i.e. on every phone) to stay compact next to the logo.
/// Public (not the file-private `_SearchTrigger` a single-shell design
/// would use) because Teacher Portal's own `TeacherTopBar` reuses this
/// exact widget too.
class SearchTrigger extends ConsumerWidget {
  const SearchTrigger({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showLabel = MediaQuery.sizeOf(context).width >= 900;

    void openPalette() {
      final navContext = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
      if (navContext == null) return;
      showSearchCommandPalette(navContext);
    }

    if (!showLabel) {
      return InkWell(
        onTap: openPalette,
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.search, size: 15, color: _navPurple),
        ),
      );
    }

    return InkWell(
      onTap: openPalette,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(border: Border.all(color: _navBorder), borderRadius: BorderRadius.circular(8), color: const Color(0xFFF3F4FB)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 14, color: _navPurple),
            const SizedBox(width: 6),
            const Text('Search…', style: TextStyle(fontSize: 12, color: _navInk3)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _navBorder), borderRadius: BorderRadius.circular(4)),
              child: const Text('⌘K', style: TextStyle(fontSize: 10, color: _navInk3, fontFamily: 'monospace')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notification bell — opens [showNotificationPanel] and shows an unread
/// badge, matching `NotificationBell.tsx`'s always-visible bell + polled
/// unread count. Needs its own context (routed through go_router's root
/// `navigatorKey`, same reasoning as `AvatarMenu._openMenu` — see
/// `GlobalAppShell`'s class doc) since `_GlobalTopBar` itself sits outside
/// any real `Navigator`/`Overlay`. Public for the same reason as
/// [SearchTrigger] — `TeacherTopBar` reuses it too.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return InkWell(
      onTap: () {
        final navContext = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
        if (navContext == null) return;
        showNotificationPanel(navContext, ref);
      },
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_outlined, size: 18, color: _navPurple),
            if (unreadCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 14),
                  decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Avatar/logout dropdown — Admin's own top bar no longer shows this (its
/// account info + logout live in the Profile bottom-nav tab instead), but
/// Teacher Portal's `TeacherTopBar` still does, so this stays public here.
class AvatarMenu extends ConsumerWidget {
  const AvatarMenu({super.key});

  String _initials(UserEntity user) {
    final f = user.firstName.trim();
    final l = user.lastName.trim();
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    if (user.username.isNotEmpty) return user.username[0].toUpperCase();
    return '?';
  }

  Future<void> _openMenu(BuildContext avatarContext, WidgetRef ref, UserEntity user) async {
    // `PopupMenuButton` (the usual way to do this) internally calls
    // `Navigator.of(context)` using *this* widget's own context, which has
    // no Navigator ancestor here (see class doc on `GlobalAppShell`) — so
    // build the menu manually with `showMenu()`, anchored via go_router's
    // root navigator context instead.
    final navContext = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
    if (navContext == null) return;
    final box = avatarContext.findRenderObject() as RenderBox?;
    if (box == null) return;

    // `localToGlobal` with no `ancestor` resolves to true screen
    // coordinates (there is exactly one `RenderView` root regardless of
    // where a widget sits relative to the Navigator), which is what
    // `showMenu`'s `position` needs relative to the full-screen overlay.
    final globalPos = box.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(navContext).size;
    final position = RelativeRect.fromLTRB(
      globalPos.dx,
      globalPos.dy + box.size.height + 4,
      screenSize.width - (globalPos.dx + box.size.width),
      0,
    );

    final value = await showMenu<String>(
      context: navContext,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _navBorder)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700, color: _navInk1, fontSize: 13), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user.email, style: const TextStyle(color: _navInk3, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout', style: TextStyle(color: _navInk1, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );

    if (value == 'logout') {
      ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.maybeWhen(authenticated: (u) => u, orElse: () => null);
    if (user == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openMenu(context, ref, user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: _navPurple,
              child: Text(_initials(user), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: _navInk2),
          ],
        ),
      ),
    );
  }
}

class _BottomNavTab {
  final String path;
  final String segment;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _BottomNavTab({required this.path, required this.segment, required this.icon, required this.activeIcon, required this.label});
}

const _bottomNavTabs = [
  _BottomNavTab(path: '/home', segment: 'home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
  _BottomNavTab(path: '/modules', segment: 'modules', icon: Icons.apps_outlined, activeIcon: Icons.apps_rounded, label: 'All Modules'),
  _BottomNavTab(path: '/profile', segment: 'profile', icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
];

/// Persistent bottom tab bar — the Admin app's primary navigation surface
/// on mobile, replacing the desktop-style header module strip/flyout this
/// header used to carry. Highlights whichever tab owns the current route's
/// first path segment (via [currentRoutePathProvider]); every other tap
/// just calls `appRouterProvider`'s `go`, same pattern as the rest of this
/// shell (see class doc on [GlobalAppShell] for why — no Navigator ancestor
/// here to use `context.go` with).
class _GlobalBottomNav extends ConsumerWidget {
  const _GlobalBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentRoutePathProvider);
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    final currentSegment = segments.isNotEmpty ? segments.first : 'home';

    return Material(
      // Same reasoning as `_GlobalTopBar` — this bar sits outside any real
      // `Navigator`/`Scaffold`, so it needs its own `Material` ancestor for
      // the tab `InkWell`s to paint ink splashes without throwing.
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(color: _navBg, border: Border(top: BorderSide(color: _navBorder))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (final tab in _bottomNavTabs)
                  Expanded(
                    child: _BottomNavButton(
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

const _teacherBottomNavTabs = [
  _BottomNavTab(path: '/teacher/home', segment: 'home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
  _BottomNavTab(path: '/teacher/modules', segment: 'modules', icon: Icons.apps_outlined, activeIcon: Icons.apps_rounded, label: 'All Modules'),
  _BottomNavTab(path: '/teacher/profile', segment: 'profile', icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
];

/// Teacher Portal's bottom tab bar — exactly Home / All Modules / Profile,
/// deliberately no Widgets tab (that's an Admin-only home-customization
/// concept). Reuses the same generic [_BottomNavButton] as
/// [_GlobalBottomNav]; only the tab list and the active-segment lookup
/// differ, since every Teacher route is nested under `/teacher/*` (so the
/// tab-owning segment is the route's *second* path segment, not the first —
/// `segments[0]` is always literally `'teacher'`).
class _TeacherBottomNav extends ConsumerWidget {
  const _TeacherBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentRoutePathProvider);
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    final currentSegment = segments.length > 1 ? segments[1] : 'home';

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(color: _navBg, border: Border(top: BorderSide(color: _navBorder))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (final tab in _teacherBottomNavTabs)
                  Expanded(
                    child: _BottomNavButton(
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

class _BottomNavButton extends StatelessWidget {
  final _BottomNavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavButton({required this.tab, required this.isActive, required this.onTap});

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
