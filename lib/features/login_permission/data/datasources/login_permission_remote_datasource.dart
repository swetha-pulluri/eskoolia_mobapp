import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/login_permission_api_results.dart';
import '../../domain/models/login_permission_meta.dart';

/// Login Permission Remote DataSource
/// Handles Login Permission API calls
/// Reference: backend/apps/access_control/views.py - LoginPermissionViewSet
abstract class LoginPermissionRemoteDataSource {
  /// GET /api/v1/access-control/login-permission/meta/
  Future<MetaResult> fetchMeta();

  /// GET /api/v1/access-control/login-permission/users/
  Future<PageResult> listUsers({
    required String role,
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? classId,
    String? sectionId,
  });

  /// POST /api/v1/access-control/login-permission/toggle/
  Future<bool> toggleAccess(String id, bool loginAccess);

  /// POST /api/v1/access-control/login-permission/reset-password/
  Future<CredentialActionResult> resetPassword(String id);

  /// POST /api/v1/access-control/login-permission/set-initial-password/
  Future<CredentialActionResult> setInitialPassword(
    String id, {
    required String mode,
    String? password,
  });

  /// POST /api/v1/access-control/login-permission/bulk-access/
  Future<int> bulkSetAccess({
    required List<String> ids,
    required bool loginAccess,
  });

  /// POST /api/v1/access-control/login-permission/bulk-reset/
  Future<int> bulkResetPasswords({required List<String> ids});
}

class LoginPermissionRemoteDataSourceImpl
    implements LoginPermissionRemoteDataSource {
  final Dio _dio;

  LoginPermissionRemoteDataSourceImpl(this._dio);

  @override
  Future<MetaResult> fetchMeta() async {
    try {
      final response = await _dio.get(ApiConstants.loginPermissionMeta);
      return MetaResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load roles.');
    }
  }

  @override
  Future<PageResult> listUsers({
    required String role,
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? classId,
    String? sectionId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.loginPermissionUsers,
        queryParameters: {
          'role': role,
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (classId != null && classId.isNotEmpty) 'class_id': classId,
          if (sectionId != null && sectionId.isNotEmpty)
            'section_id': sectionId,
        },
      );
      return PageResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load users.');
    }
  }

  @override
  Future<bool> toggleAccess(String id, bool loginAccess) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginPermissionToggle,
        data: {'id': id, 'loginAccess': loginAccess},
      );
      final data = response.data as Map<String, dynamic>;
      return data['loginAccess'] as bool? ?? loginAccess;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update login access.');
    }
  }

  @override
  Future<CredentialActionResult> resetPassword(String id) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginPermissionResetPassword,
        data: {'id': id},
      );
      return CredentialActionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to reset password.');
    }
  }

  @override
  Future<CredentialActionResult> setInitialPassword(
    String id, {
    required String mode,
    String? password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginPermissionSetInitialPassword,
        data: {'id': id, 'mode': mode, 'password': ?password},
      );
      return CredentialActionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to set initial password.');
    }
  }

  @override
  Future<int> bulkSetAccess({
    required List<String> ids,
    required bool loginAccess,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginPermissionBulkAccess,
        data: {'ids': ids, 'allMatching': false, 'login_access': loginAccess},
      );
      final data = response.data as Map<String, dynamic>;
      return data['affected'] as int? ?? 0;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update login access.');
    }
  }

  @override
  Future<int> bulkResetPasswords({required List<String> ids}) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginPermissionBulkReset,
        data: {'ids': ids, 'allMatching': false},
      );
      final data = response.data as Map<String, dynamic>;
      return data['affected'] as int? ?? 0;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to reset passwords.');
    }
  }
}
