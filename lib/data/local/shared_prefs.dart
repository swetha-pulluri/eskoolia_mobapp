import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

/// Shared Preferences wrapper
class SharedPrefs {
  static final SharedPrefs _instance = SharedPrefs._internal();
  factory SharedPrefs() => _instance;
  SharedPrefs._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Generic setters
  Future<bool> setString(String key, String value) async {
    try {
      return await prefs.setString(key, value);
    } catch (e) {
      AppLogger.error('Error saving string: $key', e);
      return false;
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      return await prefs.setInt(key, value);
    } catch (e) {
      AppLogger.error('Error saving int: $key', e);
      return false;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    try {
      return await prefs.setBool(key, value);
    } catch (e) {
      AppLogger.error('Error saving bool: $key', e);
      return false;
    }
  }

  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await prefs.setStringList(key, value);
    } catch (e) {
      AppLogger.error('Error saving string list: $key', e);
      return false;
    }
  }

  // Generic getters
  String? getString(String key) {
    try {
      return prefs.getString(key);
    } catch (e) {
      AppLogger.error('Error reading string: $key', e);
      return null;
    }
  }

  int? getInt(String key) {
    try {
      return prefs.getInt(key);
    } catch (e) {
      AppLogger.error('Error reading int: $key', e);
      return null;
    }
  }

  bool? getBool(String key) {
    try {
      return prefs.getBool(key);
    } catch (e) {
      AppLogger.error('Error reading bool: $key', e);
      return null;
    }
  }

  List<String>? getStringList(String key) {
    try {
      return prefs.getStringList(key);
    } catch (e) {
      AppLogger.error('Error reading string list: $key', e);
      return null;
    }
  }

  // Save/Load JSON
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      AppLogger.error('Error saving JSON: $key', e);
      return false;
    }
  }

  Map<String, dynamic>? getJson(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error reading JSON: $key', e);
      return null;
    }
  }

  // Save/Load JSON List
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      AppLogger.error('Error saving JSON list: $key', e);
      return false;
    }
  }

  List<Map<String, dynamic>>? getJsonList(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      final decoded = jsonDecode(jsonString);
      return (decoded as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      AppLogger.error('Error reading JSON list: $key', e);
      return null;
    }
  }

  // Remove key
  Future<bool> remove(String key) async {
    try {
      return await prefs.remove(key);
    } catch (e) {
      AppLogger.error('Error removing key: $key', e);
      return false;
    }
  }

  // Clear all
  Future<bool> clear() async {
    try {
      return await prefs.clear();
    } catch (e) {
      AppLogger.error('Error clearing preferences', e);
      return false;
    }
  }

  // Check if key exists
  bool containsKey(String key) {
    try {
      return prefs.containsKey(key);
    } catch (e) {
      AppLogger.error('Error checking key: $key', e);
      return false;
    }
  }
}
