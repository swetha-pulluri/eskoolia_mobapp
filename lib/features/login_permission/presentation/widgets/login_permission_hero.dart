import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../login_permission/domain/models/login_permission_user.dart';

class LoginPermissionHero extends StatelessWidget {
  final PortalTab activeTab;

  const LoginPermissionHero({super.key, required this.activeTab});

  Color _getBadgeBackgroundColor() {
    switch (activeTab) {
      case PortalTab.teacher:
        return const Color(0xFFEEEAFF);
      case PortalTab.principal:
        return const Color(0xFFEEF2FF);
      case PortalTab.student:
        return const Color(0xFFE0F2FE);
      case PortalTab.parent:
        return const Color(0xFFFFF1F2);
      case PortalTab.driver:
        return const Color(0xFFFFF7ED);
      case PortalTab.staff:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getBadgeTextColor() {
    switch (activeTab) {
      case PortalTab.teacher:
        return const Color(0xFF6D4AFF);
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Text(
            'ROLES & PERMISSIONS · CREDENTIAL MANAGER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),

          // Title + Badge
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              // Title with "Login" in black and "Credentials" in purple italic
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Login ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'Credentials',
                    style: GoogleFonts.instrumentSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: AppColors.dashboardPurple,
                      height: 1.2,
                    ),
                  ),
                ],
              ),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getBadgeBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activeTab.badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _getBadgeTextColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            activeTab.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
