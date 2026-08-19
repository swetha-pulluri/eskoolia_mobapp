import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../teacher/presentation/widgets/teacher_quick_access_tile.dart';
import '../../domain/entities/module_entity.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../providers/dashboard_provider.dart';
import 'module_card.dart';
import 'section_label.dart';

class ModuleGrid extends ConsumerWidget {
  /// Explicit module list to render (e.g. Teacher's own `TeacherModules.all`).
  /// When omitted, falls back to `visibleModulesProvider` — preserves the
  /// exact original behavior for every existing Admin call site.
  final List<ModuleEntity>? modules;

  /// Admin's own "recently visited" tracking (`recordModuleVisit`) is an
  /// Admin-dashboard concept; Teacher call sites pass `false` so a Teacher
  /// session never writes into that same recents list.
  final bool trackRecents;

  /// Renders each tile as [TeacherQuickAccessTile] (bare, borderless — no
  /// card/background) instead of [ModuleCardGrid] (bordered `PremiumCard`).
  /// Only Teacher's `/teacher/modules` page sets this; Admin's own
  /// `/modules` route never does, so its rendering is completely unchanged.
  final bool useBareTiles;

  /// Heading text — defaults to Admin's exact original ('All Modules');
  /// Teacher's `/teacher/modules` route passes 'ALL MODULES' to match the
  /// uppercase section-heading style used everywhere else on Teacher Home.
  final String title;

  const ModuleGrid({
    super.key,
    this.modules,
    this.trackRecents = true,
    this.useBareTiles = false,
    this.title = 'All Modules',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ModuleEntity> visibleModules = modules != null ? modules! : ref.watch(visibleModulesProvider);

    // Title-left/count-right via the standard `SectionLabel`, same as every
    // other section.
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          title: title,
          count: visibleModules.length,
        ),
        // Slightly more than Admin's own gap here — Teacher's bare tiles
        // (no card/border under the icon+label) read as more "bare" than
        // Admin's bordered `ModuleCardGrid`, so they need a touch more
        // breathing room before the grid starts to avoid feeling cramped
        // right under the heading. Admin's own `/modules` page is untouched.
        SizedBox(height: useBareTiles ? 10 : 6),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: useBareTiles ? 16 : 0),
          // Teacher's bare tiles use the same content-driven `Wrap` grid
          // Home's Quick Access/All Modules cards already use — a fixed
          // `childAspectRatio` cell (as Admin's bordered `ModuleCardGrid`
          // below still uses) left large empty gaps under the heading and
          // between rows here on a wide phone, the exact bug already fixed
          // there. Admin's own card path is untouched.
          child: useBareTiles
              ? TeacherModuleWrapGrid(
                  modules: visibleModules,
                  iconAssetFor: quickAccessIconAssetFor,
                  onModuleTap: (module) {
                    if (module.comingSoon) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${module.name} - Coming Soon')),
                      );
                    } else {
                      if (trackRecents) recordModuleVisit(ref, module.path);
                      context.go(module.path);
                    }
                  },
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    // Still 4 columns (not 3 — a wider column leaves each
                    // icon surrounded by more blank cell space than this
                    // grid's own spacing value suggests), but a small gap
                    // and a taller cell now, so a two-line module name has
                    // real room instead of crowding the tile next to it.
                    crossAxisCount: 4,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: visibleModules.length,
                  itemBuilder: (context, index) {
                    final module = visibleModules[index];

                    void handleTap() {
                      if (module.comingSoon) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${module.name} - Coming Soon')),
                        );
                      } else {
                        // `trackRecents` was previously declared but never
                        // actually checked here — `recordModuleVisit` ran
                        // unconditionally, contradicting this class's own
                        // doc comment. Fixed while touching this exact
                        // closure.
                        if (trackRecents) recordModuleVisit(ref, module.path);
                        context.go(module.path);
                      }
                    }

                    return ModuleCardGrid(module: module, onTap: handleTap);
                  },
                ),
        ),
      ],
    );

    // Teacher's bare tiles keep sitting directly on the page background (no
    // card) — Admin's bordered grid gets its own card, matching every other
    // Home section (Greeting/Today's Pulse/Quick Access all wrap their
    // content the same way) instead of floating loose on the page.
    if (useBareTiles) return content;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: PremiumCard(
        radius: 20,
        color: Colors.white,
        borderColor: AppColors.border.withValues(alpha: 0.8),
        borderWidth: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }
}
