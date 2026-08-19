import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/module_entity.dart';

/// Icon-over-title(-over-subtitle) app-launcher tile — used by both the
/// "All Modules" grid (no subtitle) and the "Quick Access" grid (subtitle
/// = the module's category name). No card, box, border, or tinted
/// background of any kind: the 3D icon artwork sits directly on the
/// page's white background, large and unobstructed, with the module name
/// (colored to match the module's own accent) directly below it — matching
/// the Stitch reference's plain app-launcher look.
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
        // No card/box/border — the 3D icon sits directly on the page's
        // white background, so only the icon-over-title(-over-subtitle)
        // content itself takes up space here. A little horizontal padding
        // keeps the name from crowding the next tile over now that the
        // grid itself has very little (or no) gap between columns.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Large 3D icon artwork, no colored square/box behind it —
                // sized up considerably from the old card-tile version so
                // it reads clearly as the Stitch reference's app-launcher
                // icon rather than a small in-card glyph.
                SizedBox(
                  width: 40,
                  height: 40,
                  child: (iconAssetOverride ?? module.iconAsset) != null
                      ? Image.asset(iconAssetOverride ?? module.iconAsset!, fit: BoxFit.contain)
                      : Icon(
                          module.icon,
                          size: 28,
                          color: module.iconColor,
                        ),
                ),
                const SizedBox(height: 4),

                // Module "heading" (its name) is colored with the
                // module's own accent instead of plain ink, so it reads
                // as a suitable, on-brand color per module rather than
                // one flat text color everywhere.
                Text(
                  title ?? module.name,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: module.iconColor, height: 1.1),
                  // Two lines instead of one — a single truncated line
                  // ("Roles & Pe…") read as cramped; letting longer names
                  // wrap gives them room to actually be legible.
                  maxLines: 2,
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

            if (showRemoveButton && onRemove != null)
              Positioned(
                top: -2,
                right: 4,
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
