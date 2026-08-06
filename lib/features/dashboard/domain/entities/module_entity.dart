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

  const SubModuleEntity({
    required this.label,
    required this.path,
    this.icon,
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
    ),
    ModuleEntity(
      id: 'roles',
      name: 'Roles & Permissions',
      path: '/roles-permissions',
      icon: Icons.shield_outlined,
      bgColor: AppColors.rolesBg,
      iconColor: AppColors.rolesIc,
    ),
    ModuleEntity(
      id: 'admin',
      name: 'Administration',
      path: '/administration/communication-hub',
      icon: Icons.work_outline,
      bgColor: AppColors.administrationBg,
      iconColor: AppColors.administrationIc,
    ),
    ModuleEntity(
      id: 'admissions',
      name: 'Admissions',
      path: '/admissions/command-center',
      icon: Icons.person_add_outlined,
      bgColor: AppColors.admissionsBg,
      iconColor: AppColors.admissionsIc,
    ),
    ModuleEntity(
      id: 'students',
      name: 'Students',
      path: '/students',
      icon: Icons.people_outline,
      bgColor: AppColors.studentsBg,
      iconColor: AppColors.studentsIc,
    ),
    ModuleEntity(
      id: 'attendance',
      name: 'Attendance',
      path: '/attendance/student',
      icon: Icons.check_circle_outline,
      bgColor: AppColors.attendanceBg,
      iconColor: AppColors.attendanceIc,
    ),
    ModuleEntity(
      id: 'academics',
      name: 'Academics',
      path: '/academics/core-setup',
      icon: Icons.school_outlined,
      bgColor: AppColors.academicsBg,
      iconColor: AppColors.academicsIc,
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
