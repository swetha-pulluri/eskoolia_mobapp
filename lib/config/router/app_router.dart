import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/school_overview_page.dart';
import '../../features/roles/presentation/pages/roles_permissions_page.dart';
import '../../features/login_permission/presentation/pages/login_permission_page.dart';
import '../../features/student/domain/models/student_data.dart';
import '../../features/student/presentation/pages/student_enroll_page.dart';
import '../../features/student/presentation/pages/student_list_page.dart';
import '../../features/school_tenancy/presentation/pages/dashboard_tab.dart';
import '../../features/school_tenancy/presentation/pages/schools_tab.dart';
import '../../features/school_tenancy/presentation/pages/billing_tab.dart';
import '../../features/school_tenancy/presentation/pages/audit_tab.dart';
import '../../features/school_tenancy/presentation/pages/policies_tab.dart';
import '../../features/administration/presentation/pages/communication_hub_tab.dart';
import '../../features/administration/presentation/pages/postal_management_tab.dart';
import '../../features/administration/presentation/pages/documents_studio_tab.dart';
import '../../features/administration/presentation/pages/system_config_tab.dart';
import '../../features/admissions/presentation/pages/admissions_command_center_page.dart';
import '../../features/admissions/presentation/pages/admissions_analytics_page.dart';
import '../../features/admissions/presentation/pages/admissions_marketing_page.dart';
import '../../features/attendance/presentation/pages/attendance_student_page.dart';

/// App Router Configuration
/// Manages navigation and route guards
///
/// Note: /home = Admin Home Screen (landing page with Quick Access, Recently
///       Visited, All Modules) — this is the post-login landing page.
///       /dashboard = the KPI overview page (Swetha's SchoolOverviewPage).
///       /super-admin/* = School Tenancy routes (matching web frontend structure)
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isLoggingIn = state.matchedLocation == '/login';

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and on login page, redirect to home
      if (isAuthenticated && isLoggingIn) {
        return '/home';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // Home Route (Admin Home Screen - Quick Access, Recently Visited, All Modules)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const AdminHomePage(),
      ),

      // Dashboard KPI Overview
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const SchoolOverviewPage(),
      ),

      // School Tenancy Routes (matching web frontend structure)
      GoRoute(
        path: '/super-admin/dashboard',
        name: 'super-admin-dashboard',
        builder: (context, state) => const SuperAdminDashboardPage(),
      ),
      GoRoute(
        path: '/super-admin/schools',
        name: 'super-admin-schools',
        builder: (context, state) => const SuperAdminSchoolsPage(),
      ),
      GoRoute(
        path: '/super-admin/billing',
        name: 'super-admin-billing',
        builder: (context, state) => const SuperAdminBillingPage(),
      ),
      GoRoute(
        path: '/super-admin/audit',
        name: 'super-admin-audit',
        builder: (context, state) => const SuperAdminAuditPage(),
      ),
      GoRoute(
        path: '/super-admin/policies',
        name: 'super-admin-policies',
        builder: (context, state) => const SuperAdminPoliciesPage(),
      ),

      // Roles & Permissions Routes
      GoRoute(
        path: '/roles-permissions',
        name: 'roles-permissions',
        builder: (context, state) => const RolesPermissionsPage(),
      ),

      // Login Permission Route
      GoRoute(
        path: '/login-permission',
        name: 'login-permission',
        builder: (context, state) => const LoginPermissionPage(),
      ),

      // Administration Routes (matching web frontend structure)
      GoRoute(
        path: '/administration/communication-hub',
        name: 'administration-communication-hub',
        builder: (context, state) => const CommunicationHubPage(),
      ),
      GoRoute(
        path: '/administration/postal',
        name: 'administration-postal',
        builder: (context, state) => const PostalManagementPage(),
      ),
      GoRoute(
        path: '/administration/documents',
        name: 'administration-documents',
        builder: (context, state) => const DocumentsStudioPage(),
      ),
      GoRoute(
        path: '/administration/system-config',
        name: 'administration-system-config',
        builder: (context, state) => const SystemConfigPage(),
      ),

      // Admissions Routes (matching web frontend structure)
      GoRoute(
        path: '/admissions/command-center',
        name: 'admissions-command-center',
        builder: (context, state) => const AdmissionsCommandCenterPage(),
      ),
      GoRoute(
        path: '/admissions/analytics',
        name: 'admissions-analytics',
        builder: (context, state) => const AdmissionsAnalyticsPage(),
      ),
      GoRoute(
        path: '/admissions/marketing',
        name: 'admissions-marketing',
        builder: (context, state) => const AdmissionsMarketingPage(),
      ),

      // Attendance Routes (matching web frontend structure)
      GoRoute(
        path: '/attendance/student',
        name: 'attendance-student',
        builder: (context, state) => const AttendanceStudentPage(),
      ),

      // Student List & Enroll Routes
      GoRoute(
        path: '/students',
        name: 'students-list',
        builder: (context, state) => const StudentListPage(),
      ),
      GoRoute(
        path: '/students/enroll',
        name: 'students-enroll',
        builder: (context, state) =>
            StudentEnrollPage(editingStudent: state.extra as StudentData?),
      ),

      // Note: Assign Permissions is not a separate route — it's a tab within
      // RolesPermissionsPage (see _MainTab), matching the frontend's shared
      // layout/breadcrumb across its Roles/Assign Permissions/Login
      // Permission destinations.
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/home');
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
