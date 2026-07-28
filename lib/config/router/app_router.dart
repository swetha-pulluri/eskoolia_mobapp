import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/school_overview_page.dart';
import '../../features/roles/presentation/pages/roles_permissions_page.dart';
import '../../features/login_permission/presentation/pages/login_permission_page.dart';
import '../../features/student/domain/models/student_data.dart';
import '../../features/student/presentation/pages/student_categories_page.dart';
import '../../features/student/presentation/pages/student_deleted_page.dart';
import '../../features/student/presentation/pages/student_disabled_page.dart';
import '../../features/student/presentation/pages/student_enroll_page.dart';
import '../../features/student/presentation/pages/student_groups_page.dart';
import '../../features/student/presentation/pages/student_list_page.dart';
import '../../features/student/presentation/pages/student_promotion_page.dart';
import '../../features/student/presentation/pages/student_subject_assignment_page.dart';
import '../../features/student/presentation/pages/student_unassigned_page.dart';
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
import '../../features/academics/presentation/pages/academics_foundation_page.dart';
import '../../features/academics/presentation/pages/staff_assignment/staff_assignment_page.dart';
import '../../features/fees/presentation/pages/fees_home_page.dart';
import '../../features/fees/presentation/pages/fee_configuration_page.dart';
import '../../features/fees/presentation/pages/fee_assignment_page.dart';
import '../../features/fees/presentation/pages/fee_collection_page.dart';
import '../../features/fees/presentation/pages/fee_dues_reminders_page.dart';
import '../../features/fees/presentation/pages/fee_year_end_page.dart';
import '../../features/hr/presentation/pages/hr_setup_page.dart';
import '../../features/hr/presentation/pages/staff_attendance_page.dart';
import '../../features/hr/presentation/pages/staff_directory_page.dart';
import '../../features/hr/presentation/pages/staff_form_page.dart';
import '../../features/hr/presentation/pages/staff_onboard_page.dart';

/// App Router Configuration
/// Manages navigation and route guards
///
/// Note: /home = Admin Home Screen (landing page with Quick Access, Recently
///       Visited, All Modules) — this is the post-login landing page.
///       /dashboard = the KPI overview page (Swetha's SchoolOverviewPage).
///       /super-admin/* = School Tenancy routes (matching web frontend structure)
/// The current matched route location, kept in sync from [redirect] below
/// (which already runs on every navigation). This lets app-wide chrome that
/// lives *outside* the routed `Navigator` — e.g. [GlobalAppShell], mounted
/// via `MaterialApp.router`'s `builder:` — know which module/tab is active
/// for highlighting, without needing `GoRouterState.of(context)` (which
/// isn't reachable from that far up the tree).
final currentRoutePathProvider = StateProvider<String>((ref) => '/home');

final appRouterProvider = Provider<GoRouter>((ref) {
  // Built exactly once per app lifetime — do NOT `ref.watch(authNotifierProvider)`
  // here. Watching it would rebuild this whole provider (and therefore
  // construct a brand-new GoRouter/Navigator) on every auth-state change,
  // which is the classic Riverpod+go_router pitfall that causes "Duplicate
  // GlobalKey detected in widget tree" and cascading Navigator assertions
  // when a rebuild lands mid-navigation. `refreshListenable` lets go_router
  // re-evaluate `redirect` reactively without recreating the router itself.
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Keep the app-wide "current route" mirror up to date on every
      // navigation, redirect or not.
      Future.microtask(() {
        if (ref.read(currentRoutePathProvider) != state.matchedLocation) {
          ref.read(currentRoutePathProvider.notifier).state = state.matchedLocation;
        }
      });

      final currentAuthState = ref.read(authNotifierProvider);
      final isAuthenticated = currentAuthState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isLoggingIn = state.matchedLocation == '/login';
      debugPrint('[AppRouter] redirect check: matchedLocation=${state.matchedLocation}, authState=$currentAuthState, isAuthenticated=$isAuthenticated');

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        debugPrint('[AppRouter] redirect -> /login');
        return '/login';
      }

      // If authenticated and on login page, redirect to home
      if (isAuthenticated && isLoggingIn) {
        debugPrint('[AppRouter] redirect -> /home');
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

      // Academics Routes (matching web frontend structure)
      GoRoute(
        path: '/academics/core-setup',
        name: 'academics-core-setup',
        builder: (context, state) => const AcademicsFoundationPage(),
      ),
      GoRoute(
        path: '/academics/staff-workspace',
        name: 'academics-staff-workspace',
        builder: (context, state) => const StaffAssignmentPage(),
      ),

      // Fees Routes (matching web frontend structure) — all 6 sub-nav tabs
      // (Home, Configuration, Fee Assignment, Collection, Dues & Reminders,
      // Year-End) are built; see fees_layout.dart / fees_module_sub_nav.dart
      // for the shared module chrome.
      GoRoute(
        path: '/fees/payments',
        name: 'fees-payments',
        builder: (context, state) => const FeesHomePage(),
      ),
      GoRoute(
        path: '/fees/configuration',
        name: 'fees-configuration',
        builder: (context, state) => const FeeConfigurationPage(),
      ),
      GoRoute(
        path: '/fees/fee-assignment',
        name: 'fees-fee-assignment',
        builder: (context, state) => const FeeAssignmentPage(),
      ),
      GoRoute(
        path: '/fees/collection',
        name: 'fees-collection',
        builder: (context, state) => const FeesCollectionPage(),
      ),
      GoRoute(
        path: '/fees/dues-reminders',
        name: 'fees-dues-reminders',
        builder: (context, state) => const FeesDuesRemindersPage(),
      ),
      GoRoute(
        path: '/fees/year-end',
        name: 'fees-year-end',
        builder: (context, state) => const FeesYearEndPage(),
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

      // Students sub-modules (matching web frontend structure)
      GoRoute(
        path: '/students/categories',
        name: 'students-categories',
        builder: (context, state) => const StudentCategoriesPage(),
      ),
      GoRoute(
        path: '/students/groups',
        name: 'students-groups',
        builder: (context, state) => const StudentGroupsPage(),
      ),
      GoRoute(
        path: '/students/disabled',
        name: 'students-disabled',
        builder: (context, state) => const StudentDisabledPage(),
      ),
      GoRoute(
        path: '/students/deleted',
        name: 'students-deleted',
        builder: (context, state) => const StudentDeletedPage(),
      ),
      GoRoute(
        path: '/students/unassigned',
        name: 'students-unassigned',
        builder: (context, state) => const StudentUnassignedPage(),
      ),
      GoRoute(
        path: '/students/multi-subject-assignment',
        name: 'students-multi-subject-assignment',
        builder: (context, state) => const StudentSubjectAssignmentPage(),
      ),
      GoRoute(
        path: '/students/promote',
        name: 'students-promote',
        builder: (context, state) => const StudentPromotionPage(),
      ),

      // Human Resource Routes — UI matches the real, dormant `HrPanels.tsx`
      // components on the current `main` branch; API integration matches
      // the ACTUAL currently-running backend (verified read-only), not the
      // richer unmerged `demo` branch schema.
      GoRoute(
        path: '/hr/setup',
        name: 'hr-setup',
        builder: (context, state) => const HrSetupPage(),
      ),
      GoRoute(
        path: '/hr/directory',
        name: 'hr-staff-directory',
        builder: (context, state) => const StaffDirectoryPage(),
      ),
      GoRoute(
        path: '/hr/staff',
        name: 'hr-staff-form',
        builder: (context, state) {
          final editParam = state.uri.queryParameters['edit'];
          final tabParam = state.uri.queryParameters['tab'];
          return StaffFormPage(
            editId: editParam != null ? int.tryParse(editParam) : null,
            initialTab: tabParam != null ? int.tryParse(tabParam) ?? 0 : 0,
          );
        },
      ),
      GoRoute(
        path: '/hr/attendance',
        name: 'hr-staff-attendance',
        builder: (context, state) => const StaffAttendancePage(),
      ),
      GoRoute(
        path: '/hr/onboard',
        name: 'hr-staff-onboard',
        builder: (context, state) {
          final editParam = state.uri.queryParameters['edit'];
          final draftParam = state.uri.queryParameters['draft'];
          final departmentParam = state.uri.queryParameters['department'];
          final stepParam = state.uri.queryParameters['step'];
          return StaffOnboardPage(
            editId: editParam != null ? int.tryParse(editParam) : null,
            resumeDraftId: draftParam != null ? int.tryParse(draftParam) : null,
            initialDepartmentId: departmentParam != null ? int.tryParse(departmentParam) : null,
            initialStep: stepParam != null ? int.tryParse(stepParam) : null,
          );
        },
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

/// Bridges `authNotifierProvider`'s changes into a [Listenable] go_router can
/// subscribe to via `refreshListenable`, so `redirect` re-evaluates on every
/// auth-state change without the GoRouter instance itself being torn down
/// and rebuilt (see the comment on `appRouterProvider` above).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      notifyListeners();
    });
  }
}
