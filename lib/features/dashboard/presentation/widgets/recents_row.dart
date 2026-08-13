import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/module_entity.dart';
import '../providers/dashboard_provider.dart';
import '../theme/home_dark_theme.dart';
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(icon: Icons.schedule, title: 'Recently Visited'),

            if (validRecents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HomeDarkTheme.cardFill,
                    border: Border.all(color: HomeDarkTheme.cardBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No recent activity yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeDarkTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              // Full-width list rows (icon + title + "category · time"
              // subtitle) instead of the icon-card + floating time badge,
              // matching the Stitch mockup's recents list style.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final recent in validRecents) ...[
                      Builder(
                        builder: (context) {
                          final module = Modules.findByPath(recent.path);
                          if (module == null) return const SizedBox.shrink();
                          return _RecentRow(
                            module: module,
                            relativeTime: app_date_utils
                                .DateUtils.getRelativeTime(recent.visitedAt),
                            onTap: () {
                              if (module.comingSoon) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${module.name} - Coming Soon',
                                    ),
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
                      if (recent != validRecents.last)
                        const SizedBox(height: 6),
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
    return TapScale(
      child: PremiumCard(
        radius: 12,
        color: HomeDarkTheme.cardFill,
        borderColor: HomeDarkTheme.cardBorder,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: module.bgColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: module.iconAsset != null
                        ? Padding(
                            padding: const EdgeInsets.all(6.5),
                            child: Image.asset(module.iconAsset!, fit: BoxFit.contain),
                          )
                        : module.emoji != null
                            ? Center(child: Text(module.emoji!, style: const TextStyle(fontSize: 15)))
                            : Icon(module.icon, size: 15, color: module.iconColor),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          module.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: HomeDarkTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${module.name} · $relativeTime',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: HomeDarkTheme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: HomeDarkTheme.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
