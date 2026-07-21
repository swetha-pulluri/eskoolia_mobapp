import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/permission_tree.dart';
import '../../domain/models/role_data.dart';
import '../../domain/models/roles_page.dart';

/// Role Remote DataSource
/// Handles Roles API calls
/// Reference: backend/apps/access_control/views.py - RoleViewSet
abstract class RoleRemoteDataSource {
  /// GET /api/v1/access-control/roles/
  Future<RolesPage> fetchRoles({
    required String? search,
    required bool showInactive,
    required int page,
    required int pageSize,
  });

  /// GET /api/v1/access-control/roles/{id}/
  Future<RoleData> fetchRoleDetail(int id);

  /// POST /api/v1/access-control/roles/
  Future<RoleData> createRole({
    required String name,
    required PortalType portalType,
  });

  /// PUT /api/v1/access-control/roles/{id}/
  Future<RoleData> updateRole(
    int id, {
    required String name,
    required bool isActive,
    required PortalType portalType,
  });

  /// PATCH /api/v1/access-control/roles/{id}/
  Future<RoleData> setActive(int id, bool isActive);

  /// DELETE /api/v1/access-control/roles/{id}/
  Future<void> deleteRole(int id);

  /// GET /api/v1/access-control/roles/{id}/permission-tree/
  Future<PermissionTree> fetchPermissionTree(int roleId);

  /// POST /api/v1/access-control/roles/{id}/assign-permissions/
  Future<void> assignPermissions(int roleId, List<int> permissionIds);
}

class RoleRemoteDataSourceImpl implements RoleRemoteDataSource {
  final Dio _dio;

  RoleRemoteDataSourceImpl(this._dio);

  @override
  Future<RolesPage> fetchRoles({
    required String? search,
    required bool showInactive,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.roles,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'minimal': '1',
          if (showInactive) 'show_inactive': '1',
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return RolesPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load roles.');
    }
  }

  @override
  Future<RoleData> fetchRoleDetail(int id) async {
    try {
      final response = await _dio.get(ApiConstants.roleDetail(id));
      final body = response.data as Map<String, dynamic>;
      return RoleData.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load role.');
    }
  }

  @override
  Future<RoleData> createRole({
    required String name,
    required PortalType portalType,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.roles,
        data: {'name': name, 'portal_type': portalType.value},
      );
      final body = response.data as Map<String, dynamic>;
      return RoleData.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to create role.');
    }
  }

  @override
  Future<RoleData> updateRole(
    int id, {
    required String name,
    required bool isActive,
    required PortalType portalType,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.roleDetail(id),
        data: {
          'name': name,
          'is_active': isActive,
          'portal_type': portalType.value,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return RoleData.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update role.');
    }
  }

  @override
  Future<RoleData> setActive(int id, bool isActive) async {
    try {
      final response = await _dio.patch(
        ApiConstants.roleDetail(id),
        data: {'is_active': isActive},
      );
      final body = response.data as Map<String, dynamic>;
      return RoleData.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to update role status.');
    }
  }

  @override
  Future<void> deleteRole(int id) async {
    try {
      await _dio.delete(ApiConstants.roleDetail(id));
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to delete role.');
    }
  }

  @override
  Future<PermissionTree> fetchPermissionTree(int roleId) async {
    try {
      final response = await _dio.get(ApiConstants.rolePermissionTree(roleId));
      final body = response.data as Map<String, dynamic>;
      return PermissionTree.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load permissions.');
    }
  }

  @override
  Future<void> assignPermissions(int roleId, List<int> permissionIds) async {
    try {
      await _dio.post(
        ApiConstants.roleAssignPermissions(roleId),
        data: {'permission_ids': permissionIds},
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to save permissions.');
    }
  }
}
