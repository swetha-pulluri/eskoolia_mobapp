import 'package:flutter/material.dart';
import '../../domain/entities/module_entity.dart';
import '../widgets/module_grid.dart';

/// Bottom-nav "All Modules" tab — a dedicated full-page version of the "All
/// Modules" grid already embedded on Home ([ModuleGrid]), so every module
/// is reachable directly from the nav bar instead of only by scrolling
/// Home to the bottom. Same data source, tap behavior, and "Coming Soon"
/// handling as the Home section — this page just gives it its own screen.
///
/// Reused verbatim for Teacher's own "All Modules" tab too (`/teacher/modules`
/// in app_router.dart) by passing [modules]/[trackRecents] — every existing
/// Admin call site (`ModulesPage()`, no args) keeps its exact original
/// behavior since both params default to Admin's own module list/tracking.
class ModulesPage extends StatelessWidget {
  final List<ModuleEntity>? modules;
  final bool trackRecents;
  final bool useBareTiles;
  final String title;

  const ModulesPage({
    super.key,
    this.modules,
    this.trackRecents = true,
    this.useBareTiles = false,
    this.title = 'All Modules',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // `top: false` — this page's body sits below the persistent top bar
      // (`GlobalAppShell`'s own `Column`), which already consumes the
      // status-bar inset in its own `SafeArea`. Since that top bar and this
      // routed page are siblings (not nested), a plain `SafeArea` here
      // would double that same top inset again, pushing "ALL MODULES" down
      // by an extra status-bar's worth of empty space for no reason.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ModuleGrid(
            modules: modules,
            trackRecents: trackRecents,
            useBareTiles: useBareTiles,
            title: title,
          ),
        ),
      ),
    );
  }
}
