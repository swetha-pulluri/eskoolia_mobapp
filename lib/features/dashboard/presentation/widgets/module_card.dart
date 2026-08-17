import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/module_entity.dart';

/// Compact icon-over-title(-over-subtitle) grid tile — used by both the
/// "All Modules" grid (no subtitle) and the "Quick Access" grid (subtitle
/// = the module's category name). Sized small and dense on purpose: this
/// is a mobile app-launcher grid, not a desktop-style card. Always a white
/// card with a subtle border tinted to the module's own accent color
/// (`module.iconColor`) — never a solid colored fill — and the module name
/// itself is colored to match, so each tile reads as visually "owned" by
/// its module without needing a bold background.
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
          color: Colors.white,
          // Subtle colored edge instead of a solid fill — tinted to this
          // module's own accent color so each tile still reads as visually
          // "its own module" even on a plain white card.
          borderColor: module.iconColor.withValues(alpha: 0.55),
          child: Stack(
            // Icon-over-title(-over-subtitle) block sits top-center of the
            // tile, matching the Stitch reference — not vertically centered
            // in the tile's own middle.
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Container — sized up so the new 3D artwork reads
                    // clearly; the title/subtitle below shrink to match, so
                    // the tile's overall content height stays about the same.
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: module.bgColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: (iconAssetOverride ?? module.iconAsset) != null
                          ? Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(iconAssetOverride ?? module.iconAsset!, fit: BoxFit.contain),
                            )
                          : Icon(
                              module.icon,
                              size: 18,
                              color: module.iconColor,
                            ),
                    ),
                    const SizedBox(height: 5),

                    // Module "heading" (its name) is colored with the
                    // module's own accent instead of plain ink, so it reads
                    // as a suitable, on-brand color per module rather than
                    // one flat text color everywhere.
                    Text(
                      title ?? module.name,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: module.iconColor, height: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 8.5, color: AppColors.ink3, height: 1.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
