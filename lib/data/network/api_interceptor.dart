import 'package:dio/dio.dart';
import '../../core/utils/logger.dart';
import '../local/secure_storage.dart';

/// API Interceptor for adding auth token
class ApiInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get access token
    final token = await _secureStorage.getAccessToken();
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      AppLogger.debug('Added auth token to request: ${options.path}');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    AppLogger.error(
      'API Error: ${err.requestOptions.path}',
      err.message,
    );

    // Handle 401 Unauthorized - token refresh logic can be added here
    if (err.response?.statusCode == 401) {
      AppLogger.warning('Unauthorized request - token may be expired');
      // TODO: Implement token refresh logic if needed
    }

    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug('API Response: ${response.requestOptions.path} - Status: ${response.statusCode}');
    handler.next(response);
  }
}
