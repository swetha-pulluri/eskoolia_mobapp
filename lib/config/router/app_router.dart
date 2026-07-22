import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/dashboard/presentation/pages/school_overview_page.dart';
import '../../features/roles/presentation/pages/roles_permissions_page.dart';
import '../../features/login_permission/presentation/pages/login_permission_page.dart';
import '../../features/student/domain/models/student_data.dart';
import '../../features/student/presentation/pages/student_enroll_page.dart';
import '../../features/student/presentation/pages/student_list_page.dart';

/// App Router Configuration
/// Manages navigation and route guards
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
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

      // Home Route (Placeholder)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Dashboard Routes
      GoRoute(
        path: '/school-overview',
        name: 'school-overview',
        builder: (context, state) => const SchoolOverviewPage(),
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
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
});

/// Home Page Placeholder
/// TODO: Replace with actual dashboard based on portal_type
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('eSkoolia Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Login Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome to eSkoolia Mobile',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/school-overview');
              },
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('School Overview'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/roles-permissions');
              },
              icon: const Icon(Icons.admin_panel_settings_rounded),
              label: const Text('Roles & Permissions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/students');
              },
              icon: const Icon(Icons.groups_rounded),
              label: const Text('Students'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).logout();
                  },
                  child: const Text('Logout'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
