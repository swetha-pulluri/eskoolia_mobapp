/// API Constants for Eskoolia Backend
/// Reference: backend/apps/users/urls.py and views.py
class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  // Base URL - Change based on environment
  static const String baseUrl = 'http://localhost:8000';

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
}
