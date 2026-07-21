import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/school_tenancy/presentation/pages/dashboard_tab.dart';
import '../../features/school_tenancy/presentation/pages/schools_tab.dart';
import '../../features/school_tenancy/presentation/pages/billing_tab.dart';
import '../../features/school_tenancy/presentation/pages/audit_tab.dart';
import '../../features/school_tenancy/presentation/pages/policies_tab.dart';
import '../../features/administration/presentation/pages/communication_hub_tab.dart';
import '../../features/administration/presentation/pages/postal_management_tab.dart';
import '../../features/administration/presentation/pages/documents_studio_tab.dart';
import '../../features/administration/presentation/pages/system_config_tab.dart';

/// App Router Configuration
/// Note: /home = Admin Home Screen (landing page with Quick Access, Recently Visited, All Modules)
///       /dashboard = Dashboard KPI page (not yet implemented in Flutter, but exists in web)
///       /super-admin/* = Super Admin routes (separate pages, matching web frontend structure)
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const AdminHomePage(),
      ),
      
      // Super Admin Routes (matching web frontend structure)
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

      // TODO: Add other routes as needed
      // Example:
      // GoRoute(
      //   path: '/students/list',
      //   name: 'students-list',
      //   builder: (context, state) => const StudentsListPage(),
      // ),
    ],
    
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
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
}
