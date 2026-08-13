import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/router/app_router.dart';
import '../../features/dashboard/domain/entities/module_entity.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../utils/module_nav_utils.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk2 = Color(0xFF5A607A);
const _subPurple = Color(0xFF6D4AFF);
const _comingSoonPurple = Color(0xFF6D28D9);

/// Secondary tab strip shown below the header for whichever module "owns"
/// the current route — one shared, data-driven widget replacing 3
/// hand-coded per-module copies (Students/Fees/Academics). Flutter port of
/// `components/nav/ModuleSubNav.tsx`.
class ModuleSubNav extends ConsumerWidget {
  /// Explicit module list to resolve the sub-nav against (e.g. Teacher's
  /// own `TeacherModules.all`). When omitted, falls back to the Admin
  /// `visibleModulesProvider` — preserves the exact original behavior for
  /// every existing Admin call site.
  final List<ModuleEntity>? modules;

  const ModuleSubNav({super.key, this.modules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentRoutePathProvider);
    final List<ModuleEntity> resolvedModules = modules ?? ref.watch(visibleModulesProvider);
    final owner = findOwnerModule(currentPath, resolvedModules);
    if (owner == null || owner.subModules.isEmpty) return const SizedBox.shrink();

    final active = activeSubModule(owner, currentPath);

    // Mounted directly in `GlobalAppShell`'s `Column` as a sibling of
    // `_GlobalTopBar` (not a descendant of it), so — like
    // `ModuleFlyoutPanel` — it has no `Material` ancestor of its own to
    // satisfy `_tab()`'s `InkWell`s. `type: transparency` paints nothing
    // itself, so the `Container` below (white bg + bottom border) remains
    // the only visual source.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 46,
        decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: _navBorder))),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: owner.bgColor, borderRadius: BorderRadius.circular(5)),
              alignment: Alignment.center,
              child: Icon(owner.icon, size: 11, color: owner.iconColor),
            ),
            const SizedBox(width: 8),
            Text(owner.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _navInk2)),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: _navBorder),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [for (final sub in owner.subModules) _tab(ref, sub, sub == active)]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(WidgetRef ref, SubModuleEntity sub, bool isActive) {
    final color = isActive ? _subPurple : _navInk2;
    return InkWell(
      onTap: (isActive || sub.comingSoon) ? null : () => ref.read(appRouterProvider).go(sub.path),
      child: Container(
        height: 46,
        padding: const EdgeInsets.fromLTRB(14, 1, 14, 0),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? _subPurple : Colors.transparent, width: 2))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sub.icon != null) ...[
              Icon(sub.icon, size: 12, color: color),
              const SizedBox(width: 6),
            ],
            Text(sub.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            if (sub.comingSoon) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: _comingSoonPurple, borderRadius: BorderRadius.circular(999)),
                child: const Text('Soon', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
