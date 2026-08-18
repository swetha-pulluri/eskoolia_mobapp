import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../dashboard/presentation/widgets/module_card.dart';
import '../../../dashboard/presentation/widgets/section_label.dart';
import '../../domain/entities/parent_module_entity.dart';

/// "All Modules" grid — [ParentModules.all], the Home screen's own
/// decorative catalog. Shared by [ParentHomePage] (embedded inline) and
/// [ParentModulesPage] (bottom-nav "All Modules" tab, its own full screen),
/// same reuse pattern Admin's `ModuleGrid` already establishes for
/// `ModulesPage`/`AdminHomePage`.
class ParentModuleGrid extends StatelessWidget {
  const ParentModuleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title: 'ALL MODULES', count: ParentModules.all.length),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 0,
            childAspectRatio: 1.0,
            children: [
              for (final module in ParentModules.all) ModuleCardGrid(module: module, onTap: () => context.go(module.path)),
            ],
          ),
        ),
      ],
    );
  }
}
