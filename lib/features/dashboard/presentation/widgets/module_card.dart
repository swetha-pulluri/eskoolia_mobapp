import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/module_entity.dart';
import '../theme/home_dark_theme.dart';

/// Compact icon-over-title(-over-subtitle) grid tile — used by both the
/// "All Modules" grid (no subtitle) and the "Quick Access" grid (subtitle
/// = the module's category name). Sized small and dense on purpose: this
/// is a mobile app-launcher grid, not a desktop-style card.
class ModuleCardGrid extends StatelessWidget {
  final ModuleEntity module;
  final VoidCallback? onTap;
  final String? title;
  final String? subtitle;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  /// Overrides [module]'s own icon — used when this tile represents one
  /// specific sub-page (e.g. a pinned Quick Access entry) that has its own
  /// distinct [SubModuleEntity.iconAsset] instead of sharing its parent
  /// module's icon.
  final String? iconAssetOverride;

  const ModuleCardGrid({
    super.key,
    required this.module,
    this.onTap,
    this.title,
    this.subtitle,
    this.showRemoveButton = false,
    this.onRemove,
    this.iconAssetOverride,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      child: GestureDetector(
        onTap: () {
          if (module.comingSoon) {
            context.showSnackBar('${module.name} - Coming Soon: Under development');
          } else if (onTap != null) {
            onTap!();
          }
        },
        child: PremiumCard(
          margin: EdgeInsets.zero,
          radius: 13,
          color: HomeDarkTheme.cardFill,
          borderColor: HomeDarkTheme.cardBorder,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Container
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: module.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: (iconAssetOverride ?? module.iconAsset) != null
                          ? Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(iconAssetOverride ?? module.iconAsset!, fit: BoxFit.contain),
                            )
                          : module.emoji != null
                              ? Center(child: Text(module.emoji!, style: const TextStyle(fontSize: 15)))
                              : Icon(
                                  module.icon,
                                  size: 15,
                                  color: module.iconColor,
                                ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      title ?? module.name,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: HomeDarkTheme.textPrimary, height: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 9.5, color: HomeDarkTheme.textTertiary, height: 1.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ],
                ),
              ),

              if (showRemoveButton && onRemove != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
