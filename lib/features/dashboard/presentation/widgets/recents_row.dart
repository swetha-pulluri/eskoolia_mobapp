import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../domain/entities/module_entity.dart';
import '../providers/dashboard_provider.dart';
import 'module_card.dart';
import 'section_label.dart';

class RecentsRow extends ConsumerWidget {
  const RecentsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentsAsync = ref.watch(recentModulesProvider);

    return recentsAsync.when(
      data: (recents) {
        // Filter to only valid module paths
        final validRecents = recents.where((recent) {
          return Modules.findByPath(recent.path) != null;
        }).take(8).toList();

        // Always show section, even if empty (matching web behavior)

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(
              icon: Icons.schedule,
              title: 'RECENTLY VISITED',
            ),
            
            if (validRecents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No recent activity yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              // One card per row (full width) — see `QuickAccessGrid`'s
              // identical change for why a `Column` replaces the
              // `GridView`'s fixed `childAspectRatio` here.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (final recent in validRecents) ...[
                      Builder(builder: (context) {
                        final module = Modules.findByPath(recent.path);
                        if (module == null) return const SizedBox.shrink();
                        return Stack(
                          children: [
                            ModuleCard(
                              module: module,
                              onTap: () {
                                if (module.comingSoon) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${module.name} - Coming Soon')),
                                  );
                                } else {
                                  recordModuleVisit(ref, module.path);
                                  context.go(module.path);
                                }
                              },
                            ),
                            // Time badge
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: Text(
                                  app_date_utils.DateUtils.getRelativeTime(recent.visitedAt),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (recent != validRecents.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
