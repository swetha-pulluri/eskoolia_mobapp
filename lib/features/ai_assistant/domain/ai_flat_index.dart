import 'package:flutter/material.dart';
import 'models/flat_index_entry.dart';

/// Flutter equivalent of frontend lib/routes.ts's `MODULES`/`FLAT_INDEX` —
/// same module grouping, labels, and `bg`/`ic` color pairs (copied exactly
/// from routes.ts), but only the module/sub-route pairs that have a real
/// registered GoRoute in lib/config/router/app_router.dart. Lucide icons
/// are swapped for the closest Material equivalent (this app has no lucide
/// port; every other sub-nav in this codebase already does the same
/// substitution). Modules web has commented out or left un-built in
/// Flutter (Examination, Reports, HR, Library, Transport, Inventory,
/// Behaviour, Accounts, Utilities, Settings, School Tenancy's superuser-only
/// gate aside) are omitted entirely so a search result never dead-ends.
final List<FlatIndexEntry> aiFlatIndex = [
  const FlatIndexEntry(modId: 'home', label: 'Home', path: '/home', icon: Icons.home_outlined, bg: Color(0xFFEEF2FF), ic: Color(0xFF4F46E5)),
  const FlatIndexEntry(modId: 'dashboard', label: 'Dashboard', path: '/dashboard', icon: Icons.dashboard_outlined, bg: Color(0xFFEEF2FF), ic: Color(0xFF4F46E5)),

  // ── School Tenancy ──────────────────────────────────────────────────────
  const FlatIndexEntry(modId: 'super_admin', label: 'School Tenancy', path: '/super-admin/dashboard', icon: Icons.business_outlined, bg: Color(0xFFEDE9FE), ic: Color(0xFF6D28D9)),
  const FlatIndexEntry(modId: 'super_admin', label: 'Schools', path: '/super-admin/schools', icon: Icons.apartment_outlined, bg: Color(0xFFEDE9FE), ic: Color(0xFF6D28D9)),
  const FlatIndexEntry(modId: 'super_admin', label: 'Billing', path: '/super-admin/billing', icon: Icons.credit_card_outlined, bg: Color(0xFFEDE9FE), ic: Color(0xFF6D28D9)),
  const FlatIndexEntry(modId: 'super_admin', label: 'Audit Log', path: '/super-admin/audit', icon: Icons.description_outlined, bg: Color(0xFFEDE9FE), ic: Color(0xFF6D28D9)),
  const FlatIndexEntry(modId: 'super_admin', label: 'Policies', path: '/super-admin/policies', icon: Icons.settings_outlined, bg: Color(0xFFEDE9FE), ic: Color(0xFF6D28D9)),

  // ── Roles & Permissions ─────────────────────────────────────────────────
  const FlatIndexEntry(modId: 'roles', label: 'Roles & Permissions', path: '/roles-permissions', icon: Icons.shield_outlined, bg: Color(0xFFF5F3FF), ic: Color(0xFF6D28D9)),
  const FlatIndexEntry(modId: 'roles', label: 'Roles', path: '/roles-permissions', icon: Icons.shield_outlined, bg: Color(0xFFF5F3FF), ic: Color(0xFF6D28D9)),
  const FlatIndexEntry(modId: 'roles', label: 'Login Permission', path: '/login-permission', icon: Icons.login, bg: Color(0xFFF5F3FF), ic: Color(0xFF6D28D9)),

  // ── Administration ──────────────────────────────────────────────────────
  const FlatIndexEntry(modId: 'admin', label: 'Administration', path: '/administration/communication-hub', icon: Icons.work_outline, bg: Color(0xFFFDF4FF), ic: Color(0xFFA21CAF)),
  const FlatIndexEntry(modId: 'admin', label: 'Communication Hub', path: '/administration/communication-hub', icon: Icons.support_agent_outlined, bg: Color(0xFFFDF4FF), ic: Color(0xFFA21CAF)),
  const FlatIndexEntry(modId: 'admin', label: 'Postal Management', path: '/administration/postal', icon: Icons.mail_outline, bg: Color(0xFFFDF4FF), ic: Color(0xFFA21CAF)),
  const FlatIndexEntry(modId: 'admin', label: 'Documents Studio', path: '/administration/documents', icon: Icons.badge_outlined, bg: Color(0xFFFDF4FF), ic: Color(0xFFA21CAF)),
  const FlatIndexEntry(modId: 'admin', label: 'System Config', path: '/administration/system-config', icon: Icons.settings_outlined, bg: Color(0xFFFDF4FF), ic: Color(0xFFA21CAF)),

  // ── Admissions ───────────────────────────────────────────────────────────
  const FlatIndexEntry(modId: 'admissions', label: 'Admissions', path: '/admissions/command-center', icon: Icons.person_add_outlined, bg: Color(0xFFECFDF5), ic: Color(0xFF047857)),
  const FlatIndexEntry(modId: 'admissions', label: 'Command Center', path: '/admissions/command-center', icon: Icons.dashboard_outlined, bg: Color(0xFFECFDF5), ic: Color(0xFF047857)),
  const FlatIndexEntry(modId: 'admissions', label: 'Analytics', path: '/admissions/analytics', icon: Icons.bar_chart_outlined, bg: Color(0xFFECFDF5), ic: Color(0xFF047857)),
  const FlatIndexEntry(modId: 'admissions', label: 'Marketing', path: '/admissions/marketing', icon: Icons.campaign_outlined, bg: Color(0xFFECFDF5), ic: Color(0xFF047857)),

  // ── Students ─────────────────────────────────────────────────────────────
  const FlatIndexEntry(modId: 'students', label: 'Students', path: '/students', icon: Icons.people_outline, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Student Enroll & List', path: '/students', icon: Icons.people_outline, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Enroll Student', path: '/students/enroll', icon: Icons.person_add_alt_outlined, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Student Categories', path: '/students/categories', icon: Icons.category_outlined, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Student Group', path: '/students/groups', icon: Icons.groups_outlined, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Disabled Students', path: '/students/disabled', icon: Icons.block_outlined, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Deleted Students', path: '/students/deleted', icon: Icons.delete_outline, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Unassigned Students', path: '/students/unassigned', icon: Icons.person_off_outlined, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Multi Subject Assignment', path: '/students/multi-subject-assignment', icon: Icons.school_outlined, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),
  const FlatIndexEntry(modId: 'students', label: 'Student Promote', path: '/students/promote', icon: Icons.star_outline, bg: Color(0xFFFEF3F2), ic: Color(0xFFB42318)),

  // ── Attendance ───────────────────────────────────────────────────────────
  const FlatIndexEntry(modId: 'attendance', label: 'Attendance', path: '/attendance/student', icon: Icons.check_circle_outline, bg: Color(0xFFFFFBEB), ic: Color(0xFFB45309)),
  const FlatIndexEntry(modId: 'attendance', label: 'Student Attendance', path: '/attendance/student', icon: Icons.check_circle_outline, bg: Color(0xFFFFFBEB), ic: Color(0xFFB45309)),

  // ── Academics ────────────────────────────────────────────────────────────
  const FlatIndexEntry(modId: 'academics', label: 'Academics', path: '/academics/core-setup', icon: Icons.school_outlined, bg: Color(0xFFF0FDF4), ic: Color(0xFF15803D)),
  const FlatIndexEntry(modId: 'academics', label: 'Foundation', path: '/academics/core-setup', icon: Icons.dashboard_outlined, bg: Color(0xFFF0FDF4), ic: Color(0xFF15803D)),
  const FlatIndexEntry(modId: 'academics', label: 'Staff Assignment', path: '/academics/staff-workspace', icon: Icons.groups_outlined, bg: Color(0xFFF0FDF4), ic: Color(0xFF15803D)),

  // ── Fees ─────────────────────────────────────────────────────────────────
  const FlatIndexEntry(modId: 'fees', label: 'Fees', path: '/fees/payments', icon: Icons.payments_outlined, bg: Color(0xFFECFEFF), ic: Color(0xFF0E7490)),
  const FlatIndexEntry(modId: 'fees', label: 'Home', path: '/fees/payments', icon: Icons.dashboard_outlined, bg: Color(0xFFECFEFF), ic: Color(0xFF0E7490)),
  const FlatIndexEntry(modId: 'fees', label: 'Fee Configuration', path: '/fees/configuration', icon: Icons.settings_outlined, bg: Color(0xFFECFEFF), ic: Color(0xFF0E7490)),
  const FlatIndexEntry(modId: 'fees', label: 'Fee Assignment', path: '/fees/fee-assignment', icon: Icons.assignment_outlined, bg: Color(0xFFECFEFF), ic: Color(0xFF0E7490)),
  const FlatIndexEntry(modId: 'fees', label: 'Collection', path: '/fees/collection', icon: Icons.credit_card_outlined, bg: Color(0xFFECFEFF), ic: Color(0xFF0E7490)),
  const FlatIndexEntry(modId: 'fees', label: 'Dues & Reminders', path: '/fees/dues-reminders', icon: Icons.error_outline, bg: Color(0xFFECFEFF), ic: Color(0xFF0E7490)),
  const FlatIndexEntry(modId: 'fees', label: 'Year-End', path: '/fees/year-end', icon: Icons.calendar_month_outlined, bg: Color(0xFFECFEFF), ic: Color(0xFF0E7490)),
];
