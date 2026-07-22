/// Storage Keys for SharedPreferences and SecureStorage
class StorageKeys {
  StorageKeys._();

  // Secure Storage Keys (for sensitive data)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // Shared Preferences Keys
  static const String userPrefs = 'eskoolia_prefs';
  static const String pinnedModules = 'pinned_modules';
  static const String moduleVisibility = 'eskoolia_module_prefs_v1';
  static const String recentModules = 'recent_modules_local';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String isFirstLaunch = 'is_first_launch';
}
