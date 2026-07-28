import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/greeting_section.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/recents_row.dart';
import '../widgets/module_grid.dart';

/// Admin Home Screen
/// This is the main landing page after login, equivalent to web frontend's /home route.
/// Displays: Greeting, Quick Access (pinned modules), Recently Visited, All Modules.
/// NOT the Dashboard module - that's a separate KPI page (/dashboard) not yet implemented.
///
/// This page used to render its own inline app-bar (logo, module strip,
/// notification/settings icons) — that was a one-off duplicate of the app's
/// actual global header, which is now provided once for every route by
/// `GlobalAppShell` (see `main.dart`), so it's been removed here.
class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          ref.invalidate(attentionCountProvider);
          ref.invalidate(recentModulesProvider);
          await ref.read(pinsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              const GreetingSection(),
              
              const SizedBox(height: 22),
              
              // Quick Access (Pinned Modules)
              QuickAccessGrid(
                onManagePins: () {
                  // TODO: Show manage pins modal
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Manage Pins feature - Coming soon'),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 22),
              
              // Recently Visited
              const RecentsRow(),
              
              const SizedBox(height: 22),
              
              // All Modules
              const ModuleGrid(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
