import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_dto.dart';

/// Auth Remote Data Source
class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource(this._dioClient);

  Future<Map<String, String>> login(String username, String password) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return {
        'access': data['access'] as String,
        'refresh': data['refresh'] as String,
      };
    } catch (e) {
      AppLogger.error('Login error', e);
      rethrow;
    }
  }

  Future<UserDto> getCurrentUser() async {
    try {
      final response = await _dioClient.get(ApiConstants.meEndpoint);
      return UserDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get current user error', e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dioClient.post(ApiConstants.logoutEndpoint);
    } catch (e) {
      AppLogger.error('Logout error', e);
      // Don't rethrow - logout should succeed even if API fails
    }
  }
}
