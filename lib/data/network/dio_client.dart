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
    // Prints in both debug and release builds (print() is never stripped by
    // Flutter's release compiler) — view via `adb logcat` for a release APK.
    // Added after a release-only bug where this resolved to the same LAN IP
    // as debug but cleartext HTTP to it was blocked in release (see
    // android/app/src/main/res/xml/network_security_config.xml), which a
    // "No Internet Connection" toast alone gave no way to diagnose.
    print('[DioClient] Resolved base URL: ${ApiConstants.baseUrl}');
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
      _databaseUnavailableRetryInterceptor(),
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

  /// Retries idempotent GET requests when the backend reports its Neon
  /// free-tier "database is asleep" 503 (see backend/config/
  /// exception_handler.py::custom_exception_handler — it returns
  /// `error.code == "database_unavailable"` specifically for this and its
  /// own message literally says "please try again in a few seconds").
  /// Neon's serverless Postgres auto-suspends when idle and needs a couple
  /// of seconds to wake on the next query, so a short delay-and-retry here
  /// resolves it silently instead of surfacing a scary error for what is
  /// normally a one-off cold start. Scoped to GET only — POST/PATCH/DELETE
  /// aren't safe to blindly retry.
  static const int _maxDbUnavailableRetries = 2;
  static const Duration _dbUnavailableRetryDelay = Duration(seconds: 2);

  InterceptorsWrapper _databaseUnavailableRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final data = error.response?.data;
        final isDbUnavailable = error.response?.statusCode == 503 &&
            data is Map &&
            data['error'] is Map &&
            (data['error'] as Map)['code'] == 'database_unavailable';

        final options = error.requestOptions;
        final attempt = (options.extra['dbRetryCount'] as int?) ?? 0;

        if (isDbUnavailable && options.method == 'GET' && attempt < _maxDbUnavailableRetries) {
          print('[DioClient] Database unavailable, retrying ${options.path} (attempt ${attempt + 1})');
          await Future.delayed(_dbUnavailableRetryDelay);
          try {
            options.extra['dbRetryCount'] = attempt + 1;
            final response = await _dio.fetch(options);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(e is DioException ? e : error);
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
        // The DioException reconstructed below deliberately drops the
        // original `error.error` (the real underlying exception object —
        // e.g. a SocketException/HandshakeException with the actual OS-level
        // message) and `error.message`, replacing both with a generic
        // friendly string for display. That's by design for the UI, but it
        // means every caller downstream — including diagnostic prints in
        // auth_remote_datasource.dart — only ever sees "Message: null" and
        // the friendly text, never the real cause. Log the original here,
        // before it's discarded, so a release-only failure (which can't be
        // attached to a debugger) is still diagnosable via `adb logcat`.
        print('[DioClient] Raw error type: ${error.type}');
        print('[DioClient] Raw error.message: ${error.message}');
        print('[DioClient] Raw error.error: ${error.error} (${error.error?.runtimeType})');
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
      // The refresh endpoint authenticates via the refresh token in the
      // request body, not a bearer access token. It was missing from this
      // list, so a stale/expired access token still in storage (the exact
      // one that just triggered this 401) was being attached as the
      // Authorization header on the refresh call itself — which a
      // JWT-authenticated backend can reject outright (an invalid bearer
      // token fails authentication before the endpoint's own AllowAny
      // permission is ever checked), breaking the automatic
      // refresh-and-retry recovery below.
      '/api/v1/auth/refresh/',
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
