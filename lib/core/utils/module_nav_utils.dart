import '../../features/dashboard/domain/entities/module_entity.dart';

/// Pure route-derived active-state helpers, porting the exact rules the web
/// frontend uses in `components/nav/ModuleSubNav.tsx`. Deliberately plain
/// functions (not Riverpod providers) — active state is a computation over
/// `currentRoutePathProvider`'s value + `Modules.all`, not state of its own.

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
