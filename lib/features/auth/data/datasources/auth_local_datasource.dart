import '../../../../data/local/secure_storage_service.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

/// Auth Local DataSource
/// Handles local storage of auth data
abstract class AuthLocalDataSource {
  /// Save login response data
  Future<void> saveLoginData(LoginResponseModel response);

  /// Save user data
  Future<void> saveUserData(UserModel user);

  /// Get stored tokens
  Future<Map<String, String?>> getTokens();

  /// Clear all auth data
  Future<void> clearAuthData();

  /// Check if user is logged in
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _secureStorage;

  AuthLocalDataSourceImpl(this._secureStorage);

  @override
  Future<void> saveLoginData(LoginResponseModel response) async {
    await Future.wait([
      _secureStorage.saveAccessToken(response.access),
      _secureStorage.saveRefreshToken(response.refresh),
      _secureStorage.savePortalType(response.portal_type),
      _secureStorage.saveMustChangePassword(response.must_change_password),
      _secureStorage.saveTenantId(response.tenant_id),
      if (response.school_code != null)
        _secureStorage.saveSchoolName(response.school_code!),
    ]);
  }

  @override
  Future<void> saveUserData(UserModel user) async {
    await Future.wait([
      _secureStorage.saveUserId(user.id),
      _secureStorage.saveUsername(user.username),
      if (user.role_names.isNotEmpty)
        _secureStorage.saveUserRole(user.role_names.first),
      if (user.school_name != null)
        _secureStorage.saveSchoolName(user.school_name!),
    ]);
  }

  @override
  Future<Map<String, String?>> getTokens() async {
    final accessToken = await _secureStorage.getAccessToken();
    final refreshToken = await _secureStorage.getRefreshToken();
    return {'access': accessToken, 'refresh': refreshToken};
  }

  @override
  Future<void> clearAuthData() async {
    await _secureStorage.clearAll();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _secureStorage.isLoggedIn();
  }
}
