import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_assets.dart';
import '../../config/router/app_router.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/dashboard/domain/entities/module_entity.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';

const _navBg = Color(0xFFFFFFFF);
const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk2 = Color(0xFF5A607A);
const _navInk3 = Color(0xFF9197AE);
const _navSearchBg = Color(0xFFF4F4F8);
const _navPurple = Color(0xFF6D4AFF);

/// Global application shell — Flutter port of frontend's
/// `(dashboard)/layout.tsx` + `components/nav/TopBar.tsx`
/// (`TopBarNew`): the persistent header (logo, module strip, search,
/// notifications, avatar/logout) that wraps every authenticated route.
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

    return Column(
      children: [
        const _GlobalTopBar(),
        Expanded(child: child),
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
    final isHome = currentSegment.isEmpty || currentSegment == 'home' || currentSegment == 'dashboard';
    final visibleModules = ref.watch(visibleModulesProvider);

    return Material(
      // `_GlobalTopBar` is mounted above every route's own `Scaffold` (via
      // `MaterialApp.router`'s `builder:`), so it has no `Material` ancestor
      // of its own — without this, every `InkWell` below (back arrow, logo,
      // module pills, search/notification icons, avatar menu) throws "No
      // Material widget found" the moment this bar first builds.
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _navBorder))),
            child: Row(
              children: [
                if (!isHome) ...[
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
                        'eskoolia',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _navInk1, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final m in visibleModules) _ModulePill(module: m, isActive: _isModuleActive(m, currentSegment)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _iconButton(icon: Icons.search, onTap: () => _openSearch(ref)),
                const SizedBox(width: 2),
                _iconButton(icon: Icons.notifications_outlined, onTap: () {}),
                const SizedBox(width: 6),
                const _AvatarMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isModuleActive(ModuleEntity m, String currentSegment) {
    if (currentSegment.isEmpty) return false;
    final moduleSegments = m.path.split('/').where((s) => s.isNotEmpty).toList();
    final moduleSegment = moduleSegments.isNotEmpty ? moduleSegments.first : '';
    if (moduleSegment == currentSegment) return true;
    if (m.id == 'dashboard' && currentSegment == 'home') return true;
    return false;
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: _navInk2),
      ),
    );
  }

  void _openSearch(WidgetRef ref) {
    // `showDialog` needs a BuildContext with a real `Navigator`/`Overlay`
    // ancestor — this widget's own context doesn't have one (see class doc
    // on `GlobalAppShell`), so route through go_router's own root
    // `navigatorKey` instead, which *is* inside that Navigator's subtree.
    final navContext = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
    if (navContext == null) return;
    showDialog<void>(
      context: navContext,
      builder: (context) => const _SearchDialog(),
    );
  }
}

class _ModulePill extends ConsumerWidget {
  final ModuleEntity module;
  final bool isActive;

  const _ModulePill({required this.module, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (module.comingSoon) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${module.name} — Coming Soon'), duration: const Duration(seconds: 2)),
          );
          return;
        }
        ref.read(appRouterProvider).go(module.path);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(module.icon, size: 13, color: isActive ? _navInk1 : _navInk2),
                const SizedBox(width: 6),
                Text(
                  module.name,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: isActive ? _navInk1 : _navInk2),
                ),
              ],
            ),
            if (isActive)
              Positioned(
                left: 0,
                right: 0,
                bottom: -9,
                child: Container(height: 2, decoration: BoxDecoration(color: _navPurple, borderRadius: BorderRadius.circular(2))),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarMenu extends ConsumerWidget {
  const _AvatarMenu();

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

/// Minimal local search over the module strip — Flutter counterpart of
/// web's `CommandPalette.tsx`, which itself only filters the same static
/// module/sub-route index (no live API), so a lightweight local-filter
/// dialog is faithful to what the frontend actually does today.
///
/// Shown via `showDialog(context: <go_router's root navigatorKey context>)`
/// (see `_GlobalTopBar._openSearch`), so — unlike `_GlobalTopBar` itself —
/// this dialog's own `context` below *is* a proper descendant of the real
/// `Navigator`/`InheritedGoRouter`, and `context.go()`/`Navigator.of(context)`
/// work normally from here without any special handling.
class _SearchDialog extends ConsumerStatefulWidget {
  const _SearchDialog();

  @override
  ConsumerState<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<_SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(visibleModulesProvider);
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty ? modules : modules.where((m) => m.name.toLowerCase().contains(q)).toList();

    return Dialog(
      backgroundColor: _navBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 420),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search modules…',
                  filled: true,
                  fillColor: _navSearchBg,
                  prefixIcon: const Icon(Icons.search, size: 18, color: _navInk3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: results.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No results', style: TextStyle(color: _navInk3, fontSize: 12.5))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final m = results[i];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(color: m.bgColor, borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Icon(m.icon, size: 14, color: m.iconColor),
                            ),
                            title: Text(m.name, style: const TextStyle(fontSize: 13, color: _navInk1)),
                            subtitle: Text(m.path, style: const TextStyle(fontSize: 11, color: _navInk3)),
                            onTap: () {
                              Navigator.of(context).pop();
                              if (m.comingSoon) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${m.name} — Coming Soon')),
                                );
                                return;
                              }
                              ref.read(appRouterProvider).go(m.path);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
