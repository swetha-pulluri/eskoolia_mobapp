/// API Constants for Eskoolia Backend
/// Reference: backend/apps/users/urls.py and views.py
class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  // Base URL - Change based on environment
  // For phone testing: Use your computer's local IP address
  // For emulator: Use http://10.0.2.2:8000 (Android) or http://localhost:8000 (iOS)
  static const String baseUrl = 'http://192.168.0.120:8000';

  // API Version
  static const String apiVersion = 'v1';

  // API Base Path
  static const String apiBasePath = '/api/$apiVersion';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String login = '$apiBasePath/auth/login/';
  static const String logout = '$apiBasePath/auth/logout/';
  static const String me = '$apiBasePath/auth/me/';
  static const String refresh = '$apiBasePath/auth/refresh/';
  static const String changePassword = '$apiBasePath/auth/change-password/';

  // School Info Endpoint (public - no auth required)
  static const String schoolInfo = '$apiBasePath/tenancy/school-info/';

  // Access Control — Login Permission Endpoints
  // Reference: backend/apps/access_control/views.py - LoginPermissionViewSet
  static const String accessControlBasePath = '$apiBasePath/access-control';
  static const String loginPermissionBasePath =
      '$accessControlBasePath/login-permission';
  static const String loginPermissionMeta = '$loginPermissionBasePath/meta/';
  static const String loginPermissionUsers = '$loginPermissionBasePath/users/';
  static const String loginPermissionToggle =
      '$loginPermissionBasePath/toggle/';
  static const String loginPermissionResetPassword =
      '$loginPermissionBasePath/reset-password/';
  static const String loginPermissionSetInitialPassword =
      '$loginPermissionBasePath/set-initial-password/';
  static const String loginPermissionBulkAccess =
      '$loginPermissionBasePath/bulk-access/';
  static const String loginPermissionBulkReset =
      '$loginPermissionBasePath/bulk-reset/';

  // Access Control — Roles Endpoints
  // Reference: backend/apps/access_control/views.py - RoleViewSet
  static const String roles = '$accessControlBasePath/roles/';
  static String roleDetail(int id) => '$accessControlBasePath/roles/$id/';
  static String rolePermissionTree(int id) =>
      '$accessControlBasePath/roles/$id/permission-tree/';
  static String roleAssignPermissions(int id) =>
      '$accessControlBasePath/roles/$id/assign-permissions/';
}
