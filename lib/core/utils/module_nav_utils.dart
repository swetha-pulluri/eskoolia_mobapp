import '../../features/dashboard/domain/entities/module_entity.dart';

/// Pure route-derived active-state helpers, porting the exact rules the web
/// frontend uses in `components/nav/ModulePill.tsx` and
/// `components/nav/ModuleSubNav.tsx`. Deliberately plain functions (not
/// Riverpod providers) — active state is a computation over
/// `currentRoutePathProvider`'s value + `Modules.all`, not state of its own.

bool _matchesFirstSegment(String path, String currentPath) {
  final segments = path.split('/').where((s) => s.isNotEmpty);
  final seg = segments.isEmpty ? null : segments.first;
  return seg != null && currentPath.startsWith('/$seg');
}

/// Ports `ModulePill.tsx`'s active rule: the module is active when the
/// current path starts with the module path's first segment, plus the
/// dashboard/home special case. Also checks each submodule's own first
/// segment — most submodules share their parent's path prefix (e.g.
/// `/hr/attendance` under `hr`'s `/hr/setup`), but a few don't (Roles &
/// Permissions' "Login Permission" lives at `/login-permission`, entirely
/// outside `/roles-permissions`) — without this, the parent module's
/// underline would incorrectly disappear while on that submodule's page.
bool isModuleActive(ModuleEntity module, String currentPath) {
  if (_matchesFirstSegment(module.path, currentPath)) return true;
  if (module.subModules.any((s) => _matchesFirstSegment(s.path, currentPath))) return true;
  if (module.id == 'dashboard' && (currentPath == '/dashboard' || currentPath == '/home')) {
    return true;
  }
  return false;
}

/// Ports `ModuleSubNav.tsx`'s `reduce()`: among a module's sub-items, picks
/// the one whose path exactly matches or prefix-matches the current path,
/// preferring the longest match so a parent route never wins over a more
/// specific child route.
SubModuleEntity? activeSubModule(ModuleEntity module, String currentPath) {
  SubModuleEntity? best;
  for (final sub in module.subModules) {
    final isExact = currentPath == sub.path;
    final isPrefix = currentPath.startsWith('${sub.path}/');
    if (!isExact && !isPrefix) continue;
    if (best == null || sub.path.length > best.path.length) {
      best = sub;
    }
  }
  return best;
}

/// Ports `findOwnerModule` in `ModuleSubNav.tsx`: decides which module's
/// sub-tab strip should render for the current path — exact module-path
/// match first, then an exact sub-path match, then the module whose path is
/// the longest prefix of the current path.
ModuleEntity? findOwnerModule(String currentPath, List<ModuleEntity> modules) {
  for (final m in modules) {
    if (m.path == currentPath) return m;
  }
  for (final m in modules) {
    if (m.subModules.any((s) => s.path == currentPath)) return m;
  }
  ModuleEntity? best;
  for (final m in modules) {
    if (currentPath.startsWith(m.path)) {
      if (best == null || m.path.length > best.path.length) {
        best = m;
      }
    }
  }
  return best;
}
