import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/greeting_section.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/recents_row.dart';
import '../widgets/module_grid.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleModules = ref.watch(visibleModulesProvider);
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                const SizedBox(width: 16),
                // eSkoolia Logo
                GestureDetector(
                  onTap: () {
                    // Navigate to home
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.brandPurple,
                              AppColors.purpleDeep,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'e',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.72,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'eskoolia',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.34,
                          color: AppColors.ink1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Horizontal Module Navigation
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: visibleModules.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        final module = visibleModules[index];
                        return GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navigate to: ${module.name}')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: module.bgColor,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Icon(
                                    module.icon,
                                    size: 12,
                                    color: module.iconColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  module.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Right side actions
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 20),
                  color: AppColors.ink3,
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  color: AppColors.ink3,
                  onPressed: () {
                    // TODO: Navigate to settings
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          ref.invalidate(attentionCountProvider);
          ref.invalidate(recentModulesProvider);
          await ref.read(pinsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              const GreetingSection(),
              
              const SizedBox(height: 22),
              
              // Quick Access (Pinned Modules)
              QuickAccessGrid(
                onManagePins: () {
                  // TODO: Show manage pins modal
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Manage Pins feature - Coming soon'),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 22),
              
              // Recently Visited
              const RecentsRow(),
              
              const SizedBox(height: 22),
              
              // All Modules
              const ModuleGrid(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
