import 'package:dio/dio.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart'; // Temporarily disabled
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../local/secure_storage_service.dart';

/// Dio HTTP Client Configuration
/// Handles API requests with interceptors for authentication and logging
class DioClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _authInterceptor(),
      _errorInterceptor(),
      // Temporarily disabled - may interfere with response parsing
      // PrettyDioLogger(
      //   requestHeader: true,
      //   requestBody: true,
      //   responseBody: true,
      //   responseHeader: false,
      //   error: true,
      //   compact: true,
      // ),
    ]);
  }

  Dio get dio => _dio;

  /// Auth Interceptor - Adds access token to requests
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth for public endpoints
        if (_isPublicEndpoint(options.path)) {
          return handler.next(options);
        }

        // Add access token to headers
        final accessToken = await _secureStorage.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized - token expired
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final options = error.requestOptions;
            final accessToken = await _secureStorage.getAccessToken();
            options.headers['Authorization'] = 'Bearer $accessToken';

            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    );
  }

  /// Error Interceptor - Handles and formats errors
  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // Format error response
        String errorMessage = 'An unexpected error occurred';

        if (error.response != null) {
          final data = error.response!.data;
          if (data is Map<String, dynamic>) {
            errorMessage = _extractErrorMessage(data);
          } else if (data is String) {
            errorMessage = data;
          }
        } else if (error.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout. Please check your internet.';
        } else if (error.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Server response timeout. Please try again.';
        } else if (error.type == DioExceptionType.connectionError) {
          errorMessage = 'No internet connection. Please check your network.';
        }

        // Return a new DioException with the formatted error message
        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: errorMessage,
          ),
        );
      },
    );
  }

  /// Extract error message from response data
  String _extractErrorMessage(Map<String, dynamic> data) {
    // Check common error keys from Django REST framework
    if (data.containsKey('detail')) {
      return data['detail'].toString();
    }
    if (data.containsKey('message')) {
      return data['message'].toString();
    }
    if (data.containsKey('error')) {
      final error = data['error'];
      if (error is String) return error;
      if (error is Map) {
        return error['message']?.toString() ?? 'An error occurred';
      }
    }
    if (data.containsKey('non_field_errors')) {
      final errors = data['non_field_errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
    }

    // Return first error from any field
    for (var entry in data.entries) {
      if (entry.value is List && (entry.value as List).isNotEmpty) {
        return '${entry.key}: ${(entry.value as List).first}';
      }
      if (entry.value is String && entry.value.isNotEmpty) {
        return entry.value;
      }
    }

    return 'An error occurred';
  }

  /// Check if endpoint is public (no auth required)
  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      '/api/v1/auth/login/',
      '/api/v1/tenancy/school-info/',
      '/api/v1/auth/forgot-password/',
      '/api/v1/auth/reset-password/',
    ];
    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConstants.refresh,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'] as String?;
        if (newAccessToken != null) {
          await _secureStorage.saveAccessToken(newAccessToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Convenience HTTP methods used by feature datasources
  // (dashboard, administration, school tenancy, etc.)

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger.error('GET request error: $path', e);
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger.error('POST request error: $path', e);
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger.error('PUT request error: $path', e);
      rethrow;
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger.error('PATCH request error: $path', e);
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger.error('DELETE request error: $path', e);
      rethrow;
    }
  }
}
