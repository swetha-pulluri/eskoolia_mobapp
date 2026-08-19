import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../dashboard/domain/entities/module_entity.dart';

/// Purpose-built Teacher 3D icon set in `assets/icons/teacher/` — covers
/// every real Teacher module except Home (excluded from Quick Access/All
/// Modules grids entirely) and Fees. `fees.png` was present in an earlier
/// download but is no longer in the folder — per "keep its current icon"
/// when no replacement exists, Fees is left unmapped here so it falls back
/// to [ModuleEntity.icon] (its Material glyph) instead of pointing at a file
/// that no longer exists. Note: the file for Messages is named `chat.png`,
/// not `messages.png` — used since it's the only file present for that
/// module and clearly matches its concept. Homework and Lessons instead use
/// `assets/icons/bag.png` and `assets/icons/openbook.png` — top-level icons
/// folder, not the `teacher/` subfolder — per explicit user direction.
String? quickAccessIconAssetFor(String moduleId) {
  switch (moduleId) {
    case 'teacher-classes':
      return 'assets/icons/teacher/class.png';
    case 'teacher-timetable':
      return 'assets/icons/teacher/timetable.png';
    case 'teacher-attendance':
      return 'assets/icons/teacher/attendance (2).png';
    case 'teacher-homework':
      return 'assets/icons/bag.png';
    case 'teacher-lessons':
      return 'assets/icons/openbook.png';
    case 'teacher-messages':
      return 'assets/icons/teacher/chat.png';
    case 'teacher-profile':
      return 'assets/icons/teacher/profile.png';
    default:
      return null;
  }
}

/// Teacher Home's Quick Access tile — deliberately NOT [ModuleCardGrid]
/// (`dashboard/presentation/widgets/module_card.dart`): that widget's
/// bordered `PremiumCard` wrapper is shared with Admin's own Quick Access
/// grid (`quick_access_grid.dart`) and Teacher's own "All Modules" section,
/// so changing it would change screens explicitly out of scope for this
/// request. This is a bare icon-over-name tile, no card/border/background —
/// just [module]'s existing icon (or `iconAsset` image, same fallback
/// [ModuleCardGrid] already uses) and its existing name, same `onTap`
/// behavior (comingSoon → snackbar, otherwise the caller's navigation).
class TeacherQuickAccessTile extends StatelessWidget {
  final ModuleEntity module;
  final VoidCallback? onTap;

  /// Overrides [module]'s own icon for this tile only — same override
  /// pattern [ModuleCardGrid] already has, used here so a real image asset
  /// can be applied within Quick Access specifically without touching
  /// [TeacherModules.all] itself (that shared entity also feeds the
  /// top-bar module-pill strip and the "All Modules" grid, both explicitly
  /// out of scope for this change).
  final String? iconAssetOverride;

  const TeacherQuickAccessTile({super.key, required this.module, this.onTap, this.iconAssetOverride});

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
        child: Column(
          // `start`, not `center`: the grid cell's height is a fixed pixel
          // value (`mainAxisExtent`) that's slightly taller than this
          // content needs, as a safety buffer against clipping. Centering
          // split that buffer above AND below the content, which put visible
          // empty space between the section heading and the first icon row.
          // Top-aligning keeps the icon flush under the heading and pushes
          // all the buffer to the bottom of each cell instead, where it
          // just reads as normal row spacing.
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: module.bgColor,
                borderRadius: BorderRadius.circular(14),
                // Single subtle, color-tinted shadow — just enough depth to
                // read as "soft 3D" without stacking gradients/highlights.
                boxShadow: [
                  BoxShadow(
                    color: module.iconColor.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: (iconAssetOverride ?? module.iconAsset) != null
                  ? Padding(
                      padding: const EdgeInsets.all(7),
                      child: Image.asset(iconAssetOverride ?? module.iconAsset!, fit: BoxFit.contain),
                    )
                  : Icon(module.icon, size: 22, color: module.iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              module.name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F1222), height: 1.15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Content-driven 3-column module grid — replaces a fixed-row-height
/// `GridView` (`childAspectRatio` or `mainAxisExtent`) for Quick Access/All
/// Modules. Three rounds of tuning a uniform row-height value each failed on
/// a different device width: too short clipped the icon+label on a narrow
/// phone, too tall left a visible empty gap under the section heading on a
/// wide one — because a fixed row height can never match content whose real
/// height doesn't change with screen width. A [Wrap] sized only by a fixed
/// tile *width* (for the 3-column layout) sidesteps that entirely: each
/// tile's height is just whatever [TeacherQuickAccessTile] actually needs.
class TeacherModuleWrapGrid extends StatelessWidget {
  final List<ModuleEntity> modules;
  final String? Function(String moduleId) iconAssetFor;
  final void Function(ModuleEntity module) onModuleTap;

  const TeacherModuleWrapGrid({super.key, required this.modules, required this.iconAssetFor, required this.onModuleTap});

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            for (final module in modules)
              SizedBox(
                width: tileWidth,
                child: TeacherQuickAccessTile(
                  module: module,
                  iconAssetOverride: iconAssetFor(module.id),
                  onTap: () => onModuleTap(module),
                ),
              ),
          ],
        );
      },
    );
  }
}
