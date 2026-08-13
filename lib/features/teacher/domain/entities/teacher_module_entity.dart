import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/domain/entities/module_entity.dart';

/// Teacher Portal's own top-nav module catalog — mirrors web's
/// `frontend/lib/teacher-routes.ts` (`TEACHER_MODULES`) exactly (same ids,
/// names, paths, icons, colors). Reuses the same `ModuleEntity`/
/// `SubModuleEntity` classes as the Admin catalog (`Modules.all`) — a
/// separate, parallel static list, not a filtered/merged view of it, since
/// Teacher and Admin have entirely different modules.
///
/// Only Home has a real Flutter page so far (this task's scope, per
/// explicit product decision) — the other 6 are real, built pages on web
/// but not yet ported here, so they're `comingSoon: true` at the module
/// level (tapping shows the same "Coming Soon" flyout disclosure Admin's
/// Examination/Reports already use). Their `subModules` are still the real
/// web sub-lists (for whenever they do get built) even though a
/// module-level `comingSoon` currently makes them inert.
class TeacherModules {
  TeacherModules._();

  static final List<ModuleEntity> all = [
    const ModuleEntity(
      id: 'teacher-home',
      name: 'Home',
      path: '/teacher/home',
      icon: Icons.dashboard_outlined,
      bgColor: Color(0xFFEEF2FF),
      iconColor: Color(0xFF4F46E5),
    ),
    const ModuleEntity(
      id: 'teacher-classes',
      name: 'My Classes',
      path: '/teacher/classes',
      icon: Icons.people_outline,
      bgColor: Color(0xFFFEF3F2),
      iconColor: Color(0xFFB42318),
      subModules: [
        SubModuleEntity(label: 'Class Overview', path: '/teacher/classes', icon: Icons.people_outline),
        SubModuleEntity(label: 'Student Profiles', path: '/teacher/classes/students', icon: Icons.person_outline),
      ],
    ),
    const ModuleEntity(
      id: 'teacher-timetable',
      name: 'Timetable',
      path: '/teacher/timetable',
      icon: Icons.calendar_month_outlined,
      bgColor: Color(0xFFECFDF5),
      iconColor: Color(0xFF047857),
      subModules: [
        SubModuleEntity(label: 'Weekly View', path: '/teacher/timetable', icon: Icons.calendar_month_outlined),
      ],
    ),
    const ModuleEntity(
      id: 'teacher-attendance',
      name: 'Attendance',
      path: '/teacher/attendance',
      icon: Icons.check_box_outlined,
      bgColor: Color(0xFFFFFBEB),
      iconColor: Color(0xFFB45309),
    ),
    const ModuleEntity(
      id: 'teacher-homework',
      name: 'Homework',
      path: '/teacher/homework',
      icon: Icons.menu_book_outlined,
      bgColor: Color(0xFFF0FDF4),
      iconColor: Color(0xFF15803D),
      comingSoon: true,
      subModules: [
        SubModuleEntity(label: 'Assignments', path: '/teacher/homework', icon: Icons.menu_book_outlined),
        SubModuleEntity(label: 'Submissions', path: '/teacher/homework/submissions', icon: Icons.assignment_outlined),
      ],
    ),
    const ModuleEntity(
      id: 'teacher-lessons',
      name: 'Lessons',
      path: '/teacher/lessons',
      icon: Icons.description_outlined,
      bgColor: Color(0xFFFDF4FF),
      iconColor: Color(0xFFA21CAF),
      comingSoon: true,
      subModules: [
        SubModuleEntity(label: 'Lesson Plans', path: '/teacher/lessons', icon: Icons.description_outlined),
      ],
    ),
    const ModuleEntity(
      id: 'teacher-messages',
      name: 'Messages',
      path: '/teacher/messages',
      icon: Icons.message_outlined,
      bgColor: Color(0xFFF0F9FF),
      iconColor: Color(0xFF0369A1),
      comingSoon: true,
      subModules: [
        SubModuleEntity(label: 'Parent Messages', path: '/teacher/messages', icon: Icons.message_outlined),
      ],
    ),
    const ModuleEntity(
      id: 'teacher-profile',
      name: 'My Profile',
      path: '/teacher/profile',
      icon: Icons.person_outline,
      bgColor: Color(0xFFF5F3FF),
      iconColor: Color(0xFF6D28D9),
      // No permission guard — every teacher can always see their own
      // profile, self-scoped server-side via /api/v1/hr/staff/me/. Real,
      // built page on web too (no comingSoon), positioned last among the
      // genuine web modules to match TEACHER_MODULES' real order.
    ),
    // Reuses the exact same Admin Fees pages/providers/repositories (see
    // app_router.dart's Teacher Portal — Fees section) — there is no
    // teacher-scoped Fees backend/web page, and no per-teacher data scoping
    // exists in apps.fees, so a teacher sees the same whole-school financial
    // data and actions an Admin does. Labels/icons/sub-tab order mirror the
    // Admin `fees` catalog entry exactly (module_entity.dart) for visual
    // consistency between the two shells. Positioned last — after every
    // genuine web module including the real My Profile above — since it's
    // a Flutter-only addition with no real web nav position to match.
    ModuleEntity(
      id: 'teacher-fees',
      name: 'Fees',
      path: '/teacher/fees/payments',
      icon: Icons.payment_outlined,
      bgColor: AppColors.feesBg,
      iconColor: AppColors.feesIc,
      subModules: const [
        SubModuleEntity(label: 'Home', path: '/teacher/fees/payments', icon: Icons.grid_view_outlined),
        SubModuleEntity(label: 'Fee Configuration', path: '/teacher/fees/configuration', icon: Icons.settings_outlined),
        SubModuleEntity(label: 'Fee Assignment', path: '/teacher/fees/fee-assignment', icon: Icons.assignment_outlined),
        SubModuleEntity(label: 'Collection', path: '/teacher/fees/collection', icon: Icons.credit_card_outlined),
        SubModuleEntity(label: 'Dues & Reminders', path: '/teacher/fees/dues-reminders', icon: Icons.error_outline),
        SubModuleEntity(label: 'Year-End', path: '/teacher/fees/year-end', icon: Icons.calendar_month_outlined),
      ],
    ),
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
