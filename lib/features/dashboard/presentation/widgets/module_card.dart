import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/module_entity.dart';

class ModuleCard extends StatelessWidget {
  final ModuleEntity module;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showRemoveButton;
  final bool isGrid;
  final String? label; // Optional label for pin items

  const ModuleCard({
    super.key,
    required this.module,
    this.onTap,
    this.onRemove,
    this.showRemoveButton = false,
    this.isGrid = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (module.comingSoon) {
          context.showSnackBar('${module.name} - Coming Soon: Under development');
        } else if (onTap != null) {
          onTap!();
        }
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Stack(
          children: [
            Padding(
              padding: isGrid 
                  ? const EdgeInsets.all(12) 
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    width: isGrid ? 36 : 36,
                    height: isGrid ? 36 : 36,
                    decoration: BoxDecoration(
                      color: module.bgColor,
                      borderRadius: BorderRadius.circular(isGrid ? 10 : 9),
                    ),
                    child: Icon(
                      module.icon,
                      size: 17,
                      color: module.iconColor,
                    ),
                  ),
                  
                  if (!isGrid) ...[
                    const SizedBox(width: 10),
                    
                    // Module Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label ?? module.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.ink1,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (label != null)
                            Text(
                              module.name,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.ink3,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (isGrid) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        module.name,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.ink1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Remove Button (for pinned items)
            if (showRemoveButton && onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Module Card for Grid Layout (Compact)
class ModuleCardGrid extends StatelessWidget {
  final ModuleEntity module;
  final VoidCallback? onTap;

  const ModuleCardGrid({
    super.key,
    required this.module,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (module.comingSoon) {
          context.showSnackBar('${module.name} - Coming Soon: Under development');
        } else if (onTap != null) {
          onTap!();
        }
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: module.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  module.icon,
                  size: 18,
                  color: module.iconColor,
                ),
              ),
              const SizedBox(height: 6),
              
              // Module Name
              Text(
                module.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.ink1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
