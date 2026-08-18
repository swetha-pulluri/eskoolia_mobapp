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
  // Reuses web's own localStorage key string for traceability (separate
  // storage systems/platforms, zero collision risk).
  static const String widgetPrefs = 'eskoolia_widget_prefs_v2';
  // Teacher "Week Ahead" planner entries — local-only, matching web's own
  // localStorage-backed planner (no real backend calendar endpoint exists
  // even on web — see week_planner_entry.dart's doc comment).
  static const String teacherWeekPlanner = 'eskoolia_teacher_week_planner_v1';
  // Parent Portal — which child the ChildSwitcher currently has selected.
  // Mirrors web's own `parent_selected_child_id` localStorage key (see
  // `ParentChildContext.tsx`) so the choice survives app restarts.
  static const String parentSelectedChildId = 'parent_selected_child_id';
}
