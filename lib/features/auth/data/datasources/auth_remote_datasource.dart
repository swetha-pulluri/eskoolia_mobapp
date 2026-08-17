import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/school_info_model.dart';
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

  /// Resolve a school's public branding info from its subdomain, before
  /// login. `GET /api/v1/tenancy/school-info/?subdomain=<subdomain>`
  /// (AllowAny — backend/apps/tenancy/views.py::school_info_view). Returns
  /// null when the subdomain doesn't match any school (backend responds
  /// 404) rather than throwing, since "not found" is an expected outcome
  /// while the user is still typing/correcting the subdomain.
  Future<SchoolInfoModel?> resolveSchoolInfo(String subdomain);
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
  Future<SchoolInfoModel?> resolveSchoolInfo(String subdomain) async {
    try {
      final response = await _dio.get(
        ApiConstants.schoolInfo,
        queryParameters: {'subdomain': subdomain},
      );
      return SchoolInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.error ?? 'Could not reach the server');
    }
  }
}
