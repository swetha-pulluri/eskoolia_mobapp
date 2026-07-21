import '../../../../data/local/secure_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Auth Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  AuthRepositoryImpl(this._remoteDataSource, this._secureStorage);

  @override
  Future<Map<String, String>> login(String username, String password) async {
    final tokens = await _remoteDataSource.login(username, password);
    
    // Save tokens
    await _secureStorage.setAccessToken(tokens['access']!);
    await _secureStorage.setRefreshToken(tokens['refresh']!);
    
    // Log success (without exposing full token)
    final accessPreview = tokens['access']!.substring(0, 20);
    AppLogger.info('Login successful - Token saved: $accessPreview...');
    
    return tokens;
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final userDto = await _remoteDataSource.getCurrentUser();
    return userDto.toEntity();
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
    
    // Clear tokens
    await _secureStorage.deleteAccessToken();
    await _secureStorage.deleteRefreshToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getAccessToken();
    return token != null;
  }
}
