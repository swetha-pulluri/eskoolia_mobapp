/// Application Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'eSkoolia';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String userRoleKey = 'user_role';
  static const String schoolNameKey = 'school_name';
  static const String tenantIdKey = 'tenant_id';
  static const String portalTypeKey = 'portal_type';
  static const String mustChangePasswordKey = 'must_change_password';

  // Selected school (subdomain the user identified before login). Stored via
  // `SharedPrefs`, not `SecureStorageService` — this is a device-level
  // "which school portal am I pointed at" preference, not per-session auth
  // data, so it must survive logout's `SecureStorageService.clearAll()`
  // exactly like `lastUsername`/`rememberDevice` already do.
  static const String selectedSchoolSubdomainKey = 'selected_school_subdomain';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;

  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Pins
  static const int maxPins = 12;

  // Recents
  static const int maxRecents = 8;

  // Time Formats
  static const String dateFormat = 'EEEE, MMMM d, yyyy';
  static const String timeFormat = 'HH:mm';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}
