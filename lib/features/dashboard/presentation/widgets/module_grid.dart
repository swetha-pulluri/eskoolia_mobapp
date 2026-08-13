import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import 'module_card.dart';
import 'section_label.dart';

class ModuleGrid extends ConsumerWidget {
  const ModuleGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleModules = ref.watch(visibleModulesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          title: 'All Modules',
          count: visibleModules.length,
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.05,
            ),
            itemCount: visibleModules.length,
            itemBuilder: (context, index) {
              final module = visibleModules[index];
              
              return ModuleCardGrid(
                module: module,
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
            },
          ),
        ),
      ],
    );
  }
}
