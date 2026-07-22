import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../login_permission/domain/models/login_permission_user.dart';

class LoginPermissionTabs extends StatelessWidget {
  final PortalTab activeTab;
  final Function(PortalTab) onTabChanged;
  final Map<PortalTab, int> tabCounts;

  const LoginPermissionTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.tabCounts,
  });

  IconData _getTabIcon(PortalTab tab) {
    switch (tab) {
      case PortalTab.teacher:
        return Icons.school_rounded;
      case PortalTab.principal:
        return Icons.workspace_premium_rounded;
      case PortalTab.student:
        return Icons.menu_book_rounded;
      case PortalTab.parent:
        return Icons.people_rounded;
      case PortalTab.driver:
        return Icons.local_shipping_rounded;
      case PortalTab.staff:
        return Icons.admin_panel_settings_rounded;
    }
  }

  Color _getActiveColor(PortalTab tab) {
    switch (tab) {
      case PortalTab.teacher:
        return AppColors.dashboardPurple;
      case PortalTab.principal:
        return const Color(0xFF4338CA);
      case PortalTab.student:
        return const Color(0xFF0369A1);
      case PortalTab.parent:
        return const Color(0xFFBE123C);
      case PortalTab.driver:
        return const Color(0xFFC2410C);
      case PortalTab.staff:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: PortalTab.values.map((tab) {
            final isActive = tab == activeTab;
            final count = tabCounts[tab] ?? 0;
            final activeColor = _getActiveColor(tab);

            return GestureDetector(
              onTap: () => onTabChanged(tab),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                margin: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? activeColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTabIcon(tab),
                      size: 16,
                      color: isActive ? activeColor : AppColors.inkTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive ? activeColor : AppColors.inkTertiary,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? activeColor.withValues(alpha: 0.15)
                              : AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? activeColor
                                : AppColors.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
