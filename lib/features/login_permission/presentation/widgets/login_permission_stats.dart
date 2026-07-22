import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../login_permission/domain/models/login_permission_user.dart';

class LoginPermissionStats extends StatelessWidget {
  final LoginPermissionCounts counts;
  final PortalTab activeTab;

  const LoginPermissionStats({
    super.key,
    required this.counts,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = counts.total > 0
        ? ((counts.active / counts.total) * 100).round()
        : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: 2 columns on narrow, 4 columns on wide
        final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // A fixed mainAxisExtent (rather than childAspectRatio, which
          // derives height from width) guarantees enough room for the
          // card's content at every crossAxisCount/width combination —
          // childAspectRatio: 2.5 previously produced cards too short for
          // their content, overflowing the Column by ~8-13px.
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 92,
          ),
          children: [
            _buildStatCard(
              label: 'TOTAL',
              value: counts.total.toString(),
              subtitle: 'In ${activeTab.label}',
              icon: Icons.people_outline_rounded,
              iconColor: AppColors.dashboardPurple,
            ),
            _buildStatCard(
              label: 'ACTIVE ACCESS',
              value: counts.active.toString(),
              subtitle: '$percentage% have access',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF0E9F6E),
            ),
            _buildStatCard(
              label: 'DISABLED',
              value: counts.disabled.toString(),
              subtitle: counts.disabled > 0 ? 'Login blocked' : 'None blocked',
              icon: Icons.cancel_outlined,
              iconColor: const Color(0xFFE0463A),
            ),
            _buildStatCard(
              label: 'NEVER LOGGED IN',
              value: counts.neverLoggedIn.toString(),
              subtitle: 'Awaiting first login',
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFFA65D08),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                    color: AppColors.inkTertiary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: iconColor),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.inkPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.inkTertiary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
