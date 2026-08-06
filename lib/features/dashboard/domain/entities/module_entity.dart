import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Module Entity - Represents a module/feature in the app
class ModuleEntity {
  final String id;
  final String name;
  final String path;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool comingSoon;
  final List<SubModuleEntity> subModules;

  const ModuleEntity({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.comingSoon = false,
    this.subModules = const [],
  });
}

/// Sub-module Entity
class SubModuleEntity {
  final String label;
  final String path;
  final IconData? icon;

  /// True when this sub-item mirrors a real web `routes.ts` entry that has
  /// no registered Flutter [GoRoute] yet — tapping it shows an inline
  /// "Coming Soon" state instead of navigating (matches web's own
  /// `COMING_SOON_PATHS` behavior in `ModulePill.tsx`/`ModuleSubNav.tsx`).
  final bool comingSoon;

  const SubModuleEntity({
    required this.label,
    required this.path,
    this.icon,
    this.comingSoon = false,
  });
}

/// All Modules - matching web routes.ts
class Modules {
  Modules._();

  static final List<ModuleEntity> all = [
    ModuleEntity(
      id: 'dashboard',
      name: 'Dashboard',
      path: '/dashboard',
      icon: Icons.dashboard_outlined,
      bgColor: AppColors.dashboardBg,
      iconColor: AppColors.dashboardIc,
      // SchoolOverviewPage is implemented and routed at /dashboard —
      // this flag was stale from before that page existed.
    ),
    ModuleEntity(
      id: 'super_admin',
      name: 'School Tenancy',
      path: '/super-admin/dashboard',
      icon: Icons.business_outlined,
      bgColor: AppColors.superAdminBg,
      iconColor: AppColors.superAdminIc,
      subModules: [
        SubModuleEntity(label: 'Dashboard', path: '/super-admin/dashboard', icon: Icons.dashboard_outlined),
        SubModuleEntity(label: 'Schools', path: '/super-admin/schools', icon: Icons.apartment_outlined),
        SubModuleEntity(label: 'Billing', path: '/super-admin/billing', icon: Icons.credit_card_outlined),
        SubModuleEntity(label: 'Audit Log', path: '/super-admin/audit', icon: Icons.description_outlined),
        SubModuleEntity(label: 'Policies', path: '/super-admin/policies', icon: Icons.settings_outlined),
      ],
    ),
    ModuleEntity(
      id: 'roles',
      name: 'Roles & Permissions',
      path: '/roles-permissions',
      icon: Icons.shield_outlined,
      bgColor: AppColors.rolesBg,
      iconColor: AppColors.rolesIc,
      // Web's "Assign Permissions" is a tab inside the same page
      // (/roles-permissions), not a separate route, so it isn't listed as
      // its own dropdown entry here (see app_router.dart's note on
      // RolesPermissionsPage._MainTab).
      subModules: [
        SubModuleEntity(label: 'Roles', path: '/roles-permissions', icon: Icons.shield_outlined),
        SubModuleEntity(label: 'Login Permission', path: '/login-permission', icon: Icons.login_outlined),
      ],
    ),
    ModuleEntity(
      id: 'admin',
      name: 'Administration',
      path: '/administration/communication-hub',
      icon: Icons.work_outline,
      bgColor: AppColors.administrationBg,
      iconColor: AppColors.administrationIc,
      subModules: [
        SubModuleEntity(label: 'Communication Hub', path: '/administration/communication-hub', icon: Icons.support_agent_outlined),
        SubModuleEntity(label: 'Postal Management', path: '/administration/postal', icon: Icons.mail_outline),
        SubModuleEntity(label: 'Documents Studio', path: '/administration/documents', icon: Icons.badge_outlined),
        SubModuleEntity(label: 'System Config', path: '/administration/system-config', icon: Icons.settings_outlined),
      ],
    ),
    ModuleEntity(
      id: 'admissions',
      name: 'Admissions',
      path: '/admissions/command-center',
      icon: Icons.person_add_outlined,
      bgColor: AppColors.admissionsBg,
      iconColor: AppColors.admissionsIc,
      subModules: [
        SubModuleEntity(label: 'Command Center', path: '/admissions/command-center', icon: Icons.dashboard_outlined),
        SubModuleEntity(label: 'Analytics', path: '/admissions/analytics', icon: Icons.bar_chart_outlined),
        SubModuleEntity(label: 'Marketing', path: '/admissions/marketing', icon: Icons.campaign_outlined),
      ],
    ),
    ModuleEntity(
      id: 'students',
      name: 'Students',
      path: '/students',
      icon: Icons.people_outline,
      bgColor: AppColors.studentsBg,
      iconColor: AppColors.studentsIc,
      subModules: [
        SubModuleEntity(label: 'Student Enroll & List', path: '/students', icon: Icons.people_outline),
        SubModuleEntity(label: 'Multi Subject Assignment', path: '/students/multi-subject-assignment', icon: Icons.school_outlined),
        SubModuleEntity(label: 'Student Group', path: '/students/groups', icon: Icons.groups_outlined),
        SubModuleEntity(label: 'Student Promote', path: '/students/promote', icon: Icons.star_outline),
      ],
    ),
    ModuleEntity(
      id: 'attendance',
      name: 'Attendance',
      path: '/attendance/student',
      icon: Icons.check_circle_outline,
      bgColor: AppColors.attendanceBg,
      iconColor: AppColors.attendanceIc,
      subModules: [
        SubModuleEntity(label: 'Student Attendance', path: '/attendance/student', icon: Icons.check_circle_outline),
      ],
    ),
    ModuleEntity(
      id: 'academics',
      name: 'Academics',
      path: '/academics/core-setup',
      icon: Icons.school_outlined,
      bgColor: AppColors.academicsBg,
      iconColor: AppColors.academicsIc,
      subModules: [
        SubModuleEntity(label: 'Foundation', path: '/academics/core-setup', icon: Icons.grid_view_outlined),
        SubModuleEntity(label: 'Staff Assignment', path: '/academics/staff-workspace', icon: Icons.people_outline),
        SubModuleEntity(label: 'Timetable', path: '/academics/timetable', icon: Icons.calendar_month_outlined, comingSoon: true),
        SubModuleEntity(label: 'Planning Studio', path: '/academics/planning-studio', icon: Icons.menu_book_outlined, comingSoon: true),
        SubModuleEntity(label: 'Reports', path: '/academics/academic-reports', icon: Icons.bar_chart_outlined, comingSoon: true),
      ],
    ),
    ModuleEntity(
      id: 'exam',
      name: 'Examination',
      path: '/exams/setup',
      icon: Icons.assignment_outlined,
      bgColor: AppColors.examBg,
      iconColor: AppColors.examIc,
      comingSoon: true,
    ),
    ModuleEntity(
      id: 'reports',
      name: 'Reports',
      path: '/reports',
      icon: Icons.bar_chart_outlined,
      bgColor: AppColors.reportsBg,
      iconColor: AppColors.reportsIc,
      comingSoon: true,
    ),
    ModuleEntity(
      id: 'fees',
      name: 'Fees',
      path: '/fees/payments',
      icon: Icons.payment_outlined,
      bgColor: AppColors.feesBg,
      iconColor: AppColors.feesIc,
      comingSoon: false,
      subModules: [
        SubModuleEntity(label: 'Home', path: '/fees/payments', icon: Icons.grid_view_outlined),
        SubModuleEntity(label: 'Fee Configuration', path: '/fees/configuration', icon: Icons.settings_outlined),
        SubModuleEntity(label: 'Fee Assignment', path: '/fees/fee-assignment', icon: Icons.assignment_outlined),
        SubModuleEntity(label: 'Collection', path: '/fees/collection', icon: Icons.credit_card_outlined),
        SubModuleEntity(label: 'Dues & Reminders', path: '/fees/dues-reminders', icon: Icons.error_outline),
        SubModuleEntity(label: 'Year-End', path: '/fees/year-end', icon: Icons.calendar_month_outlined),
      ],
    ),
    ModuleEntity(
      id: 'hr',
      name: 'Human Resource',
      // Only the Setup submodule (Departments/Designations wizard) is built
      // so far, matching the real web's `/hr/setup` default route.
      path: '/hr/setup',
      icon: Icons.badge_outlined,
      bgColor: AppColors.hrBg,
      iconColor: AppColors.hrIc,
      comingSoon: false,
      subModules: [
        SubModuleEntity(label: 'Setup', path: '/hr/setup', icon: Icons.business_outlined),
        SubModuleEntity(label: 'Staff list & Onboarding', path: '/hr/directory', icon: Icons.people_outline),
        SubModuleEntity(label: 'Leave', path: '/hr/leave', icon: Icons.calendar_month_outlined, comingSoon: true),
        SubModuleEntity(label: 'Attendance', path: '/hr/attendance', icon: Icons.check_circle_outline),
        SubModuleEntity(label: 'Offboarding', path: '/hr/offboarding', icon: Icons.logout_outlined, comingSoon: true),
      ],
    ),
    ModuleEntity(
      id: 'settings',
      name: 'Settings',
      // Only the School Info section is built so far — web's own Settings
      // Section has no dedicated School Info page either (see
      // school_info_entity.dart doc comment), so there's no wider surface
      // to match yet.
      path: '/settings/school-info',
      icon: Icons.settings_outlined,
      bgColor: AppColors.settingsBg,
      iconColor: AppColors.settingsIc,
      comingSoon: false,
      subModules: [
        SubModuleEntity(label: 'School Info', path: '/settings/school-info', icon: Icons.business_outlined),
        SubModuleEntity(label: 'Leave Policy', path: '/settings/leave-policy', icon: Icons.assignment_outlined, comingSoon: true),
        SubModuleEntity(label: 'Holiday Calendar', path: '/settings/holidays', icon: Icons.calendar_month_outlined, comingSoon: true),
        SubModuleEntity(label: 'SMTP Settings', path: '/settings/smtp', icon: Icons.mail_outline, comingSoon: true),
        SubModuleEntity(label: 'Audit Log', path: '/settings/audit-log', icon: Icons.shield_outlined, comingSoon: true),
        SubModuleEntity(label: 'Attendance Rules', path: '/settings/attendance-rules', icon: Icons.check_circle_outline, comingSoon: true),
        SubModuleEntity(label: 'Documents', path: '/settings/documents', icon: Icons.description_outlined, comingSoon: true),
        SubModuleEntity(label: 'Document Branding', path: '/settings/document-branding', icon: Icons.palette_outlined, comingSoon: true),
      ],
    ),
    // Finance, Library, Transport, Inventory, Utilities are commented out in web - REMOVED to match web's 12 modules
  ];

  static ModuleEntity? findById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  static ModuleEntity? findByPath(String path) {
    try {
      return all.firstWhere((m) => m.path == path);
    } catch (e) {
      return null;
    }
  }
}
