import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/logger.dart';

/// Secure Storage for sensitive data (tokens)
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Access Token
  Future<void> setAccessToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.accessToken, value: token);
      AppLogger.debug('Access token saved');
    } catch (e) {
      AppLogger.error('Error saving access token', e);
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: StorageKeys.accessToken);
    } catch (e) {
      AppLogger.error('Error reading access token', e);
      return null;
    }
  }

  Future<void> deleteAccessToken() async {
    try {
      await _storage.delete(key: StorageKeys.accessToken);
      AppLogger.debug('Access token deleted');
    } catch (e) {
      AppLogger.error('Error deleting access token', e);
    }
  }

  // Refresh Token
  Future<void> setRefreshToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.refreshToken, value: token);
      AppLogger.debug('Refresh token saved');
    } catch (e) {
      AppLogger.error('Error saving refresh token', e);
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: StorageKeys.refreshToken);
    } catch (e) {
      AppLogger.error('Error reading refresh token', e);
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: StorageKeys.refreshToken);
      AppLogger.debug('Refresh token deleted');
    } catch (e) {
      AppLogger.error('Error deleting refresh token', e);
    }
  }

  // Clear all secure data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.debug('All secure storage cleared');
    } catch (e) {
      AppLogger.error('Error clearing secure storage', e);
    }
  }
}
