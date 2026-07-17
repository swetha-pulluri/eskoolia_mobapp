import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

/// Auth Remote DataSource
/// Handles authentication API calls
/// Reference: backend/apps/users/views.py - LoginView, MeView, LogoutView
abstract class AuthRemoteDataSource {
  /// Login user
  /// POST /api/v1/auth/login/
  Future<LoginResponseModel> login(LoginRequestModel request);

  /// Get current user profile
  /// GET /api/v1/auth/me/
  Future<UserModel> getCurrentUser();

  /// Logout user
  /// POST /api/v1/auth/logout/
  Future<void> logout(String refreshToken);

  /// Refresh access token
  /// POST /api/v1/auth/refresh/
  Future<String> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      return LoginResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Login failed');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to get user profile');
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(ApiConstants.logout, data: {'refresh': refreshToken});
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Logout failed');
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.refresh,
        data: {'refresh': refreshToken},
      );
      return response.data['access'] as String;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Token refresh failed');
    }
  }
}
