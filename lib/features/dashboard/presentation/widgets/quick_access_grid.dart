import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/module_entity.dart';
import '../providers/dashboard_provider.dart';
import 'module_card.dart';
import 'section_label.dart';

class QuickAccessGrid extends ConsumerWidget {
  final VoidCallback? onManagePins;

  const QuickAccessGrid({
    super.key,
    this.onManagePins,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsAsync = ref.watch(pinsProvider);

    return pinsAsync.when(
      data: (pins) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(
              title: 'QUICK ACCESS',
              pinnedCount: pins.length,
              actionText: 'Manage',
              onAction: onManagePins,
            ),
            
            if (pins.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No pinned pages yet — tap Manage → to add some',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              // One card per row (full width) — each `ModuleCard` sizes to
              // its own content height (icon + label, ~52px) rather than a
              // `GridView`'s fixed `childAspectRatio`, so there's no aspect
              // ratio to recompute now that the card is full-width instead
              // of half-width.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (final pin in pins) ...[
                      Builder(builder: (context) {
                        final module = Modules.findById(pin.moduleId);
                        if (module == null) return const SizedBox.shrink();
                        return ModuleCard(
                          module: module,
                          label: pin.label,
                          showRemoveButton: true,
                          onRemove: () async {
                            await ref.read(pinsProvider.notifier).removePin(pin.path);
                          },
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
                        );
                      }),
                      if (pin != pins.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error loading pins: $error'),
      ),
    );
  }
}
