import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/router/app_router.dart';
import '../../features/dashboard/domain/entities/module_entity.dart';
import '../providers/module_flyout_provider.dart';
import '../utils/platform_capabilities.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk2 = Color(0xFF5A607A);
const _navInk3 = Color(0xFF9197AE);
const _navPurple = Color(0xFF6D4AFF);
const _comingSoonPurple = Color(0xFF6D28D9);
const _comingSoonBg = Color(0xFFEDE9FE);

/// A top-nav module button — Flutter port of the web's `ModulePill.tsx`.
/// Tapping it always navigates to the module's default page (`module.path`,
/// same as web's `<Link href={mod.path}>`); on hover-capable platforms it
/// *also* opens a dropdown flyout listing its submodules after a short
/// delay, independent of the click behavior. The flyout panel itself is
/// rendered separately (see [ModuleFlyoutPanel]) by `GlobalAppShell`,
/// positioned via [moduleFlyoutProvider] — this widget only decides *when*
/// to open/close it and *where* (its own screen position).
class ModulePillWithFlyout extends ConsumerStatefulWidget {
  final ModuleEntity module;
  final bool isActive;

  const ModulePillWithFlyout({super.key, required this.module, required this.isActive});

  @override
  ConsumerState<ModulePillWithFlyout> createState() => _ModulePillWithFlyoutState();
}

class _ModulePillWithFlyoutState extends ConsumerState<ModulePillWithFlyout> {
  final GlobalKey _pillKey = GlobalKey();
  Timer? _openTimer;

  @override
  void dispose() {
    _openTimer?.cancel();
    super.dispose();
  }

  bool get _hasFlyout => widget.module.subModules.isNotEmpty || widget.module.comingSoon;

  ModuleFlyoutTarget? _computeTarget() {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final globalPos = box.localToGlobal(Offset.zero);
    return ModuleFlyoutTarget(
      moduleId: widget.module.id,
      top: globalPos.dy + box.size.height + 4,
      left: globalPos.dx,
    );
  }

  void _onEnter() {
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(milliseconds: 180), () {
      final target = _computeTarget();
      if (target != null) ref.read(moduleFlyoutProvider.notifier).openNow(target);
    });
  }

  void _onExit() {
    _openTimer?.cancel();
    final isThisOpen = ref.read(moduleFlyoutProvider)?.moduleId == widget.module.id;
    if (isThisOpen) ref.read(moduleFlyoutProvider.notifier).scheduleClose();
  }

  // Ports `ModulePill.tsx`'s exact behavior: the pill itself is a real
  // `<Link href={mod.path}>` — clicking it always navigates to the
  // module's default page, independent of the dropdown. The dropdown is
  // opened *only* by hover (`_onEnter`/`_onExit` below); there is no
  // tap-to-open-dropdown on touch platforms, matching the real web (which
  // itself has no touch/mobile fallback for this nav — see
  // `platform_capabilities.dart`'s doc comment).
  void _onTap() {
    if (ref.read(moduleFlyoutProvider)?.moduleId == widget.module.id) {
      ref.read(moduleFlyoutProvider.notifier).closeNow();
    }
    ref.read(appRouterProvider).go(widget.module.path);
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final isActive = widget.isActive;

    Widget pill = InkWell(
      key: _pillKey,
      onTap: _onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        // The active underline lives fully inside this 34px box (bottom
        // edge, not hanging below it) — the header's module strip sizes
        // its horizontally-scrolling viewport to exactly this height, so
        // anything painted outside these bounds (the old `bottom: -9`
        // approach) was silently clipped and never actually visible.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
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
            ),
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: isActive ? _navPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );

    // Only modules with real submodules (or a module-level "Coming Soon"
    // state) get hover handlers at all — matches web's `ModulePill.tsx`,
    // which only wires `onMouseEnter`/`onMouseLeave` when `mod.sub.length
    // > 0` (e.g. Dashboard, with no `sub` array, is a plain link).
    if (!isHoverCapablePlatform || !_hasFlyout) return pill;

    return MouseRegion(onEnter: (_) => _onEnter(), onExit: (_) => _onExit(), child: pill);
  }
}

/// The floating panel itself — rendered once by `GlobalAppShell` at whatever
/// position [moduleFlyoutProvider] currently holds. Visual spec ports
/// `ModulePill.tsx`'s dropdown almost 1:1 (width, shadow, radius, padding,
/// fade-in, header row, sub-row layout, "Coming Soon" states).
class ModuleFlyoutPanel extends ConsumerStatefulWidget {
  final ModuleEntity module;
  final double top;
  final double left;

  const ModuleFlyoutPanel({super.key, required this.module, required this.top, required this.left});

  @override
  ConsumerState<ModuleFlyoutPanel> createState() => _ModuleFlyoutPanelState();
}

class _ModuleFlyoutPanelState extends ConsumerState<ModuleFlyoutPanel> {
  String? _comingSoonSubLabel;
  Timer? _comingSoonTimer;

  @override
  void dispose() {
    _comingSoonTimer?.cancel();
    super.dispose();
  }

  void _onEnterPanel() {
    if (isHoverCapablePlatform) ref.read(moduleFlyoutProvider.notifier).cancelScheduledClose();
  }

  void _onExitPanel() {
    if (isHoverCapablePlatform) ref.read(moduleFlyoutProvider.notifier).scheduleClose();
  }

  void _tapSub(SubModuleEntity sub) {
    if (sub.comingSoon) {
      _comingSoonTimer?.cancel();
      setState(() => _comingSoonSubLabel = sub.label);
      _comingSoonTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _comingSoonSubLabel = null);
      });
      return;
    }
    ref.read(moduleFlyoutProvider.notifier).closeNow();
    ref.read(appRouterProvider).go(sub.path);
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final screenSize = MediaQuery.of(context).size;
    final showComingSoonCard = module.comingSoon || _comingSoonSubLabel != null;
    final panelWidth = showComingSoonCard ? 200.0 : 260.0;
    final maxWidth = 320.0;
    final clampedLeft = widget.left.clamp(8.0, (screenSize.width - panelWidth - 8).clamp(8.0, double.infinity));
    final maxHeight = (screenSize.height - widget.top - 16).clamp(80.0, double.infinity);

    return Positioned(
      top: widget.top,
      left: clampedLeft,
      // This panel is mounted directly in `GlobalAppShell`'s bare `Stack`
      // (a `Positioned` sibling of `_GlobalTopBar`, not a descendant of
      // it) — so it has no `Material` ancestor of its own to satisfy the
      // `InkWell`s in `_subRow`/the "Coming Soon" card below.
      // `type: transparency` paints nothing itself, so the panel's own
      // `Container` (decoration: white bg/border/radius/shadow) remains
      // the only visual source — colors/radius/shadow/animation are
      // unchanged. Mirrors the exact same fix `_GlobalTopBar` already
      // applies to itself in `global_app_shell.dart`, for the identical
      // reason (this shell sits outside any routed `Scaffold`/`Material`).
      child: Material(
        type: MaterialType.transparency,
        child: MouseRegion(
          onEnter: (_) => _onEnterPanel(),
          onExit: (_) => _onExitPanel(),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.scale(scale: 0.98 + 0.02 * v, alignment: Alignment.topLeft, child: child),
            ),
            child: Container(
              constraints: BoxConstraints(minWidth: panelWidth, maxWidth: maxWidth, maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _navBorder),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x2E0E1020), offset: Offset(0, 14), blurRadius: 32, spreadRadius: -10)],
              ),
              child: showComingSoonCard
                  ? _comingSoonCard(_comingSoonSubLabel != null ? 'This feature' : 'This module')
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                            child: Row(
                              children: [
                                Text(
                                  module.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: _navInk3),
                                ),
                                const Spacer(),
                                Text(
                                  '${module.subModules.length} pages',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _navInk3),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: _navBorder),
                          const SizedBox(height: 4),
                          for (final sub in module.subModules) _subRow(sub),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _comingSoonCard(String subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: _comingSoonBg, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Icon(Icons.access_time, size: 14, color: _comingSoonPurple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Coming Soon', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _navInk1)),
                const SizedBox(height: 2),
                Text('$subject is under development', style: const TextStyle(fontSize: 11, color: _navInk3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subRow(SubModuleEntity sub) {
    final module = widget.module;
    return InkWell(
      onTap: () => _tapSub(sub),
      borderRadius: BorderRadius.circular(8),
      hoverColor: const Color(0xFFF3F4FB),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: module.bgColor, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Icon(sub.icon ?? module.icon, size: 13, color: module.iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                sub.label,
                style: const TextStyle(fontSize: 12.5, color: _navInk1),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sub.comingSoon)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: _comingSoonPurple, borderRadius: BorderRadius.circular(999)),
                child: const Text('Soon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
