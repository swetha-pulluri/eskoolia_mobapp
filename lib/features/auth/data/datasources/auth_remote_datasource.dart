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

  /// Request a 6-digit reset code be emailed to [email].
  /// `POST /api/v1/auth/forgot-password/` (AllowAny —
  /// backend/apps/users/views.py::ForgotPasswordView). Returns the
  /// backend's confirmation message on success.
  Future<String> forgotPassword(String email);

  /// Verify a previously-emailed [code] without consuming it.
  /// `POST /api/v1/auth/verify-reset-code/` (AllowAny —
  /// backend/apps/users/views.py::VerifyResetCodeView).
  Future<void> verifyResetCode(String email, String code);

  /// Complete the reset — re-validates [code] and sets [newPassword].
  /// `POST /api/v1/auth/reset-password/` (AllowAny —
  /// backend/apps/users/views.py::ResetPasswordView). Returns the
  /// backend's confirmation message on success.
  Future<String> resetPassword(String email, String code, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    // Diagnostic logging for connectivity issues (e.g. a stale LAN IP in
    // EnvConfig, or the dev backend not bound to 0.0.0.0) — a connection
    // timeout gives no other clue as to which URL was actually attempted.
    final fullUrl = '${_dio.options.baseUrl}${ApiConstants.login}';
    print('[Login] Base URL: ${_dio.options.baseUrl}');
    print('[Login] Full login URL: $fullUrl');
    print('[Login] Request body: ${request.toJson()}');
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      print('[Login] Response status: ${response.statusCode}');
      // Debug: Print response data to diagnose parsing issues
      print('Login Response Data: ${response.data}');
      print('Response Data Type: ${response.data.runtimeType}');

      final loginResponse = LoginResponseModel.fromJson(response.data);
      print('Parsed Login Response: $loginResponse');

      return loginResponse;
    } on DioException catch (e) {
      print('[Login] Response status: ${e.response?.statusCode ?? "(no response)"}');
      print('DioException during login: ${e.type}, Message: ${e.message}');
      print('DioException Error: ${e.error}');
      throw Exception(e.error ?? 'Login failed');
    } catch (e, stackTrace) {
      print('Unexpected error during login: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Login failed: $e');
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

  @override
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'Reset code sent to your email.';
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Could not send the reset code');
    }
  }

  @override
  Future<void> verifyResetCode(String email, String code) async {
    try {
      await _dio.post(
        ApiConstants.verifyResetCode,
        data: {'email': email, 'code': code},
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Could not verify the code');
    }
  }

  @override
  Future<String> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: {'email': email, 'code': code, 'new_password': newPassword},
      );
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'Password reset successfully.';
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Could not reset the password');
    }
  }
}
