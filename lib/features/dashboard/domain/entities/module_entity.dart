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

  /// Optional custom PNG (from `assets/icons/`) shown instead of [icon] on
  /// module-level tiles (Quick Access/All Modules grids, Recently Visited,
  /// the sub-nav module header) when present. Null for modules with no
  /// custom artwork yet, which keep rendering their Material [icon] as
  /// before.
  final String? iconAsset;

  const ModuleEntity({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.comingSoon = false,
    this.subModules = const [],
    this.iconAsset,
  });
}

/// Sub-module Entity
class SubModuleEntity {
  final String label;
  final String path;
  final IconData? icon;

  /// Optional custom PNG (from `assets/icons/`), overriding the owning
  /// module's own [ModuleEntity.iconAsset] specifically for tiles that
  /// represent this exact sub-page (e.g. a pinned Quick Access tile) —
  /// used when a sub-page has its own distinct artwork instead of sharing
  /// its parent module's icon.
  final String? iconAsset;

  /// True when this sub-item mirrors a real web `routes.ts` entry that has
  /// no registered Flutter [GoRoute] yet — tapping it shows an inline
  /// "Coming Soon" state instead of navigating (matches web's own
  /// `COMING_SOON_PATHS` behavior in `ModulePill.tsx`/`ModuleSubNav.tsx`).
  final bool comingSoon;

  const SubModuleEntity({
    required this.label,
    required this.path,
    this.icon,
    this.iconAsset,
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
      iconAsset: 'assets/icons/dashboard_3d.png',
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
      iconAsset: 'assets/icons/school_tenancy_3d.png',
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
      iconAsset: 'assets/icons/roles_permissions_3d.png',
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
      iconAsset: 'assets/icons/administration_3d.png',
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
      iconAsset: 'assets/icons/admissions_3d.png',
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
      iconAsset: 'assets/icons/students_3d.png',
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
      iconAsset: 'assets/icons/attendance_3d.png',
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
      iconAsset: 'assets/icons/academics_3d.png',
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
      iconAsset: 'assets/icons/examination_3d.png',
      comingSoon: true,
      // "Marks Register" is one of the 4 real default pins
      // (pin_item_entity.dart's DefaultPins.all) — modeled here (with its
      // own iconAsset) so its Quick Access tile shows its own artwork
      // instead of falling back to this module's icon.
      subModules: [
        SubModuleEntity(
          label: 'Marks Register',
          path: '/exams/marks-register',
          icon: Icons.grade_outlined,
          iconAsset: 'assets/icons/marks-register.png',
        ),
      ],
    ),
    ModuleEntity(
      id: 'reports',
      name: 'Reports',
      path: '/reports',
      icon: Icons.bar_chart_outlined,
      bgColor: AppColors.reportsBg,
      iconColor: AppColors.reportsIc,
      iconAsset: 'assets/icons/reports_3d.png',
      comingSoon: true,
    ),
    ModuleEntity(
      id: 'fees',
      name: 'Fees',
      path: '/fees/payments',
      icon: Icons.payment_outlined,
      bgColor: AppColors.feesBg,
      iconColor: AppColors.feesIc,
      iconAsset: 'assets/icons/fees_3d.png',
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
      iconAsset: 'assets/icons/hr_3d.png',
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
      // All 8 Settings sub-modules are now built. School Info ports
      // frontend/components/settings/SchoolInfoPanel.tsx, backed by the
      // singleton endpoint /api/v1/settings/school-info/ (+ /logo/). Leave
      // Policy ports frontend/components/settings/LeavePolicyPanel.tsx,
      // backed by /api/v1/settings/leave-policy/ + the leave-carry-forward
      // and audit-log sub-resources. Holiday Calendar ports
      // frontend/components/settings/HolidaysPanel.tsx, backed by the
      // shared /api/v1/core/holidays/ endpoint plus the Settings-only
      // /api/v1/settings/staff-holiday-calendar/ and
      // staff-holiday-exclusions/ sub-resources. SMTP Settings ports
      // frontend/components/settings/SmtpSettingsPanel.tsx, backed by
      // /api/v1/settings/smtp/ + its activate/ and test_send/ sub-actions.
      // Audit Log ports frontend/components/settings/AuditLogPanel.tsx, the
      // full filterable/paginated browse view over the same
      // /api/v1/settings/audit-log/ endpoint the other panels above already
      // use narrowly (via ?module=&object_id=) for their own inline
      // "view history" widgets. Attendance Rules ports frontend/components/
      // settings/AttendanceRulesPanel.tsx, a real CRUD list (unlike SMTP/
      // School Info's singletons) backed by
      // /api/v1/settings/attendance-policies/ + its make_default/ action.
      // Documents ports frontend/components/settings/DocumentsPanel.tsx,
      // backed by /api/v1/settings/documents/ (multipart create, JSON-only
      // title/category edit, soft delete) — category is a fixed 4-value
      // enum on both sides, not a manageable list. Document Branding ports
      // frontend/components/settings/DocumentBrandingPanel.tsx, another
      // singleton form (Header/Declarations tabs + a live preview pane)
      // backed by /api/v1/settings/document-branding/ + its
      // upload-letterhead/, header-image/, and preview/ sub-actions — the
      // letterhead/rendered image itself has no URL field on the
      // serializer, unlike School Info's logo, so it's only ever fetched
      // via those two binary PNG endpoints.
      path: '/settings/school-info',
      icon: Icons.settings_outlined,
      bgColor: AppColors.settingsBg,
      iconColor: AppColors.settingsIc,
      iconAsset: 'assets/icons/settings_3d.png',
      comingSoon: false,
      subModules: [
        SubModuleEntity(label: 'School Info', path: '/settings/school-info', icon: Icons.business_outlined),
        SubModuleEntity(label: 'Leave Policy', path: '/settings/leave-policy', icon: Icons.assignment_outlined),
        SubModuleEntity(label: 'Holiday Calendar', path: '/settings/holidays', icon: Icons.calendar_month_outlined),
        SubModuleEntity(label: 'SMTP Settings', path: '/settings/smtp', icon: Icons.mail_outline),
        SubModuleEntity(label: 'Audit Log', path: '/settings/audit-log', icon: Icons.shield_outlined),
        SubModuleEntity(label: 'Attendance Rules', path: '/settings/attendance-rules', icon: Icons.check_circle_outline),
        SubModuleEntity(label: 'Documents', path: '/settings/documents', icon: Icons.description_outlined),
        SubModuleEntity(label: 'Document Branding', path: '/settings/document-branding', icon: Icons.palette_outlined),
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
