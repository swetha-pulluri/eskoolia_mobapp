import '../../domain/entities/login_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';

/// Auth Repository Implementation
/// Implements the domain repository interface
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<LoginEntity> login(String username, String password) async {
    try {
      // Call remote API
      final request = LoginRequestModel(username: username, password: password);
      final response = await _remoteDataSource.login(request);

      // Save to local storage
      await _localDataSource.saveLoginData(response);

      // Map to domain entity
      return LoginEntity(
        accessToken: response.access,
        refreshToken: response.refresh,
        mustChangePassword: response.must_change_password,
        portalType: response.portal_type,
        schoolCode: response.school_code,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();

      // Save user data locally
      await _localDataSource.saveUserData(userModel);

      // Map to domain entity
      return UserEntity(
        id: userModel.id,
        username: userModel.username,
        email: userModel.email,
        firstName: userModel.first_name,
        lastName: userModel.last_name,
        schoolId: userModel.school_id,
        schoolName: userModel.school_name,
        portalType: userModel.portal_type,
        isSuperuser: userModel.is_superuser,
        roleNames: userModel.role_names,
        mustChangePassword: userModel.must_change_password,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      final tokens = await _localDataSource.getTokens();
      final refreshToken = tokens['refresh'];

      if (refreshToken != null) {
        await _remoteDataSource.logout(refreshToken);
      }

      await _localDataSource.clearAuthData();
    } catch (e) {
      // Even if API call fails, clear local data
      await _localDataSource.clearAuthData();
      throw Exception(e.toString());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _localDataSource.isLoggedIn();
  }

  @override
  Future<String> forgotPassword(String email) async {
    try {
      return await _remoteDataSource.forgotPassword(email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> verifyResetCode(String email, String code) async {
    try {
      await _remoteDataSource.verifyResetCode(email, code);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<String> resetPassword(String email, String code, String newPassword) async {
    try {
      return await _remoteDataSource.resetPassword(email, code, newPassword);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
