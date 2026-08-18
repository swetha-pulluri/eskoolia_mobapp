import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../dashboard/presentation/widgets/module_card.dart';
import '../../../dashboard/presentation/widgets/section_label.dart';
import '../../domain/entities/parent_module_entity.dart';

/// "Quick Access" grid — [ParentQuickAccess.all], extracted into its own
/// widget (matching [ParentModuleGrid]'s precedent) instead of living
/// inline on [ParentHomePage]. 4-column compact app-launcher grid, same
/// tile size/shape as the "All Modules" grid below it.
class ParentQuickAccessGrid extends StatelessWidget {
  const ParentQuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title: 'QUICK ACCESS', count: ParentQuickAccess.all.length),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 0,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              for (final module in ParentQuickAccess.all) ModuleCardGrid(module: module, onTap: () => context.go(module.path)),
            ],
          ),
        ),
      ],
    );
  }
}
