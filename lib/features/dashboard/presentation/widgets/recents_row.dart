import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/module_entity.dart';
import '../../domain/entities/recent_item_entity.dart';
import '../providers/dashboard_provider.dart';
import 'section_label.dart';

class RecentsRow extends ConsumerWidget {
  const RecentsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentsAsync = ref.watch(recentModulesProvider);

    return recentsAsync.when(
      data: (recents) {
        // Filter to only valid module paths
        final validRecents = recents
            .where((recent) {
              return Modules.findByPath(recent.path) != null;
            })
            .take(8)
            .toList();

        // Always show section, even if empty (matching web behavior)

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: PremiumCard(
            radius: 20,
            color: Colors.white,
            borderWidth: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(icon: Icons.schedule, title: 'Recently Visited'),

                if (validRecents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No recent activity yet',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.ink2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  // Two-per-row tiles (icon + title + relative time) instead
                  // of one full-width row per item — matches the Stitch
                  // mockup's "Tenancy | Settings" side-by-side recents style.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (var i = 0; i < validRecents.length; i += 2) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTile(
                                  context,
                                  ref,
                                  validRecents[i],
                                ),
                              ),
                              if (i + 1 < validRecents.length) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTile(
                                    context,
                                    ref,
                                    validRecents[i + 1],
                                  ),
                                ),
                              ] else
                                const Spacer(),
                            ],
                          ),
                          if (i + 2 < validRecents.length)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildTile(
    BuildContext context,
    WidgetRef ref,
    RecentItemEntity recent,
  ) {
    final module = Modules.findByPath(recent.path);
    if (module == null) return const SizedBox.shrink();
    return _RecentRow(
      module: module,
      relativeTime: app_date_utils.DateUtils.getRelativeTime(recent.visitedAt),
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
  }
}

class _RecentRow extends StatelessWidget {
  final ModuleEntity module;
  final String relativeTime;
  final VoidCallback onTap;

  const _RecentRow({
    required this.module,
    required this.relativeTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // No card/box/border — sits directly on the "Recently Visited"
    // section's own card background, matching the module grid tiles'
    // plain icon-and-text look (was its own bordered white card per
    // item).
    return TapScale(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: module.bgColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: module.iconAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(module.iconAsset!, fit: BoxFit.contain),
                    )
                  : Icon(module.icon, size: 16, color: module.iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    module.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: module.iconColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    relativeTime,
                    style: const TextStyle(fontSize: 9.5, color: AppColors.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
