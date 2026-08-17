import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Secure Storage Service
/// Manages secure storage of sensitive data like tokens
/// Reference: Uses Flutter Secure Storage for encrypted storage
class SecureStorageService {
  final FlutterSecureStorage _storage;

  /// In-memory mirror of the persisted access/refresh tokens.
  ///
  /// On Android, `FlutterSecureStorage` with `encryptedSharedPreferences:
  /// true` backs onto a keystore-encrypted file whose first read
  /// immediately after a write (before the underlying master key /
  /// encrypted-prefs file has settled) can transiently return null or throw
  /// — a documented flutter_secure_storage race, not a Dio/network issue.
  /// This surfaced as: login's POST succeeds and saves fresh tokens, but the
  /// very next call (GET /me/, fired moments later by the same login flow)
  /// reads the access token back too early via this same storage and comes
  /// up empty, so the request goes out unauthenticated and 401s — read as
  /// "Unexpected Error" on the first attempt. A second, identical login a
  /// moment later succeeds because by then the disk-backed store has caught
  /// up. Serving reads from this cache (updated synchronously the instant a
  /// token is saved, before the disk write is even awaited) removes the
  /// race entirely for the lifetime of the process.
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedTenantId;

  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  // Token Management

  Future<void> saveAccessToken(String token) async {
    _cachedAccessToken = token;
    await _storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    final value = await _storage.read(key: AppConstants.accessTokenKey);
    _cachedAccessToken = value;
    return value;
  }

  Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    final value = await _storage.read(key: AppConstants.refreshTokenKey);
    _cachedRefreshToken = value;
    return value;
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
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
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

  /// Tenant ID for the `X-Tenant` header (`TenantAwareJWTAuthentication`'s
  /// backend-documented API-access path for non-subdomain clients — the
  /// mobile app hits a single fixed base URL, so it can't rely on the
  /// subdomain-based tenant resolution web uses). Null for superusers, who
  /// authenticate in the public schema and don't need one. Written
  /// unconditionally (not only when non-null) so a superuser login after a
  /// tenant-user login clears any previously-cached tenant rather than
  /// leaving a stale one attached to future requests.
  Future<void> saveTenantId(String? tenantId) async {
    _cachedTenantId = tenantId;
    if (tenantId != null) {
      await _storage.write(key: AppConstants.tenantIdKey, value: tenantId);
    } else {
      await _storage.delete(key: AppConstants.tenantIdKey);
    }
  }

  Future<String?> getTenantId() async {
    if (_cachedTenantId != null) return _cachedTenantId;
    final value = await _storage.read(key: AppConstants.tenantIdKey);
    _cachedTenantId = value;
    return value;
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
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedTenantId = null;
    await _storage.deleteAll();
  }

  // Check if user is logged in

  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
