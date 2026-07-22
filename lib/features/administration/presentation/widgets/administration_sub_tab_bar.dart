import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Secondary tab bar shared by every Administration main-tab page — matches
/// the web's hand-rolled "Primary tab bar" inside each page (underline
/// style, same visual language as `ModuleSubNav`).
class AdministrationSubTabBar extends StatelessWidget {
  final List<({IconData icon, String label})> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const AdministrationSubTabBar({super.key, required this.tabs, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(tabs.length, (i) {
            final isActive = i == activeIndex;
            final tab = tabs[i];
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: isActive ? AppColors.primaryPurple : Colors.transparent, width: 2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 13, color: isActive ? AppColors.primaryPurple : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.primaryPurple : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Secondary "pill" tab bar — matches Documents Studio's own extra sub-level
/// on web (`SUB_TABS`: Design Template / Generate & Print), a rounded
/// filled-pill style distinct from the plain underline `AdministrationSubTabBar`.
class AdministrationPillTabBar extends StatelessWidget {
  final List<({IconData icon, String label})> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const AdministrationPillTabBar({super.key, required this.tabs, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final isActive = i == activeIndex;
            final tab = tabs[i];
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryPurple : Colors.transparent,
                  border: Border.all(color: isActive ? AppColors.primaryPurple : AppColors.borderPrimary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 12, color: isActive ? Colors.white : AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
