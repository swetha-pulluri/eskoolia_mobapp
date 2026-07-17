import '../config/env_config.dart';

/// API Constants
class ApiConstants {
  ApiConstants._();

  // Base URL - Configured based on platform and environment
  // For Android physical devices, update the LAN IP in env_config.dart
  static String get baseUrl => EnvConfig.apiBaseUrl;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String loginEndpoint = '/api/v1/auth/login/';
  static const String logoutEndpoint = '/api/v1/auth/logout/';
  static const String refreshTokenEndpoint = '/api/v1/auth/token/refresh/';
  static const String meEndpoint = '/api/v1/auth/me/';

  // Dashboard Endpoints
  static const String attentionCountEndpoint = '/api/dashboard/attention-count/';
  // NOTE: Backend has NO /api/user/recents/ endpoint - use localStorage only

  // Other Endpoints (for future use)
  static const String studentsEndpoint = '/api/students/';
  static const String attendanceEndpoint = '/api/attendance/';
  static const String feesEndpoint = '/api/fees/';
  static const String academicsEndpoint = '/api/academics/';
  static const String examsEndpoint = '/api/exams/';
  static const String transportEndpoint = '/api/transport/';
  static const String libraryEndpoint = '/api/library/';
  static const String inventoryEndpoint = '/api/inventory/';
  static const String utilitiesEndpoint = '/api/utilities/';
}
