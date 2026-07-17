import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Secure Storage Service
/// Manages secure storage of sensitive data like tokens
/// Reference: Uses Flutter Secure Storage for encrypted storage
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  // Token Management

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<void> deleteTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  // User Data Management

  Future<void> saveUserId(int userId) async {
    await _storage.write(key: AppConstants.userIdKey, value: userId.toString());
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(key: AppConstants.userIdKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> saveUsername(String username) async {
    await _storage.write(key: AppConstants.usernameKey, value: username);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: AppConstants.usernameKey);
  }

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: AppConstants.userRoleKey, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: AppConstants.userRoleKey);
  }

  Future<void> saveSchoolName(String schoolName) async {
    await _storage.write(key: AppConstants.schoolNameKey, value: schoolName);
  }

  Future<String?> getSchoolName() async {
    return await _storage.read(key: AppConstants.schoolNameKey);
  }

  Future<void> savePortalType(String portalType) async {
    await _storage.write(key: AppConstants.portalTypeKey, value: portalType);
  }

  Future<String?> getPortalType() async {
    return await _storage.read(key: AppConstants.portalTypeKey);
  }

  Future<void> saveMustChangePassword(bool mustChange) async {
    await _storage.write(
      key: AppConstants.mustChangePasswordKey,
      value: mustChange.toString(),
    );
  }

  Future<bool> getMustChangePassword() async {
    final value = await _storage.read(key: AppConstants.mustChangePasswordKey);
    return value == 'true';
  }

  // Clear all data

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if user is logged in

  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
