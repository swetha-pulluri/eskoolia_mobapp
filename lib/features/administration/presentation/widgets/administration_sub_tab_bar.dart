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
