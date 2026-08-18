import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/module_entity.dart';
import '../providers/dashboard_provider.dart';
import 'module_card.dart';
import 'section_label.dart';

class QuickAccessGrid extends ConsumerWidget {
  final VoidCallback? onManagePins;

  const QuickAccessGrid({super.key, this.onManagePins});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsAsync = ref.watch(pinsProvider);

    return pinsAsync.when(
      data: (pins) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: PremiumCard(
            radius: 20,
            color: Colors.white,
            borderColor: AppColors.border.withValues(alpha: 0.8),
            borderWidth: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(
                  title: 'Quick Access',
                  pinnedCount: pins.length,
                  actionText: 'Manage',
                  onAction: onManagePins,
                ),

                if (pins.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No pinned pages yet — tap Manage → to add some',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.ink2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  // 3-column grid of small tiles (icon + pin label + module
                  // category as subtitle), matching the "All Modules" grid's
                  // layout below it — a compact mobile app-launcher grid, not
                  // a desktop-style card list.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 10,
                            // Larger, un-boxed icon plus a subtitle line needs a
                            // bit more height than the "All Modules" tile.
                            childAspectRatio: 1.15,
                          ),
                      itemCount: pins.length,
                      itemBuilder: (context, index) {
                        final pin = pins[index];
                        final module = Modules.findById(pin.moduleId);
                        if (module == null) return const SizedBox.shrink();
                        // A sub-page (e.g. "Marks Register" under Examination)
                        // may have its own distinct icon instead of sharing its
                        // parent module's — use it when this pin's path matches
                        // one.
                        final subMatch = module.subModules
                            .where((s) => s.path == pin.path)
                            .firstOrNull;
                        return ModuleCardGrid(
                          module: module,
                          title: pin.label,
                          subtitle: module.name,
                          iconAssetOverride: subMatch?.iconAsset,
                          showRemoveButton: true,
                          onRemove: () async {
                            await ref
                                .read(pinsProvider.notifier)
                                .removePin(pin.path);
                          },
                          onTap: () {
                            if (module.comingSoon) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${module.name} - Coming Soon'),
                                ),
                              );
                            } else {
                              recordModuleVisit(ref, module.path);
                              context.go(module.path);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
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
