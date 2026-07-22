import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Module sub-navigation bar — mirrors frontend components/nav/ModuleSubNav.tsx
/// for the 'roles' module (frontend/lib/routes.ts): a module label chip
/// ("Roles & Permissions") followed by its sub-tabs (Roles, Assign
/// Permissions, Login Permission). On the frontend this bar sits outside the
/// scrollable page content and never scrolls away, so it is placed in the
/// Scaffold AppBar's `bottom` slot here to match that fixed behavior.
class LoginPermissionModuleSubnav extends StatelessWidget
    implements PreferredSizeWidget {
  const LoginPermissionModuleSubnav({super.key});

  static const double barHeight = 46;

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 8, right: 18),
        child: Row(
          children: [
            _buildModuleLabel(),
            _buildTab(
              icon: Icons.shield_rounded,
              label: 'Roles',
              isActive: false,
              onTap: () => context.go('/roles-permissions'),
            ),
            _buildTab(
              icon: Icons.lock_rounded,
              label: 'Assign Permissions',
              isActive: false,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Assign Permissions - Coming Soon'),
                ),
              ),
            ),
            _buildTab(
              icon: Icons.login_rounded,
              label: 'Login Permission',
              isActive: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleLabel() {
    return Container(
      padding: const EdgeInsets.only(right: 12),
      margin: const EdgeInsets.only(right: 7),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 11,
              color: Color(0xFF6D28D9),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Roles & Permissions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.dashboardPurple : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive
                  ? AppColors.dashboardPurple
                  : AppColors.inkSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.dashboardPurple
                    : AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
