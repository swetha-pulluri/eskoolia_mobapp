import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate available width after accounting for horizontal padding
                  const horizontalPadding = 24.0;
                  const crossAxisSpacing = 10.0;
                  const crossAxisCount = 2;
                  // Aspect ratio 3.1 provides proper height for icon + title + subtitle + padding
                  // Calculation: Card needs ~52px height (8px padding top + 36px content + 8px padding bottom)
                  // With card width ~165px: 165/3.1 = 53.2px height (safe margin)
                  const aspectRatio = 3.1;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisSpacing: 10,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: pins.length,
                      itemBuilder: (context, index) {
                        final pin = pins[index];
                        // Match module by ID, not path (pins use sub-module paths)
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
                            // TODO: Navigate to module page
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navigate to: ${module.name}')),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
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
