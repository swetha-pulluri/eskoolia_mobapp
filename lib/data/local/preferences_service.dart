import 'package:shared_preferences/shared_preferences.dart';

/// Preferences Service
/// Manages non-sensitive app preferences
class PreferencesService {
  static const String _rememberDeviceKey = 'remember_device';
  static const String _lastUsernameKey = 'last_username';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Remember Device

  Future<void> setRememberDevice(bool remember) async {
    await _prefs.setBool(_rememberDeviceKey, remember);
  }

  bool getRememberDevice() {
    return _prefs.getBool(_rememberDeviceKey) ?? false;
  }

  // Last Username

  Future<void> setLastUsername(String username) async {
    await _prefs.setString(_lastUsernameKey, username);
  }

  String? getLastUsername() {
    return _prefs.getString(_lastUsernameKey);
  }

  // Clear all preferences

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
