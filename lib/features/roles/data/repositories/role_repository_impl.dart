import '../../domain/models/permission_tree.dart';
import '../../domain/models/role_data.dart';
import '../../domain/models/roles_page.dart';
import '../../domain/repositories/role_repository.dart';
import '../datasources/role_remote_datasource.dart';

/// Role Repository Implementation
/// Implements the domain repository interface
class RoleRepositoryImpl implements RoleRepository {
  final RoleRemoteDataSource _remoteDataSource;

  RoleRepositoryImpl(this._remoteDataSource);

  @override
  Future<RolesPage> fetchRoles({
    String? search,
    bool showInactive = false,
    int page = 1,
    int pageSize = 100,
  }) {
    return _remoteDataSource.fetchRoles(
      search: search,
      showInactive: showInactive,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<RoleData> fetchRoleDetail(int id) =>
      _remoteDataSource.fetchRoleDetail(id);

  @override
  Future<RoleData> createRole({
    required String name,
    required PortalType portalType,
  }) => _remoteDataSource.createRole(name: name, portalType: portalType);

  @override
  Future<RoleData> updateRole(
    int id, {
    required String name,
    required bool isActive,
    required PortalType portalType,
  }) {
    return _remoteDataSource.updateRole(
      id,
      name: name,
      isActive: isActive,
      portalType: portalType,
    );
  }

  @override
  Future<RoleData> setActive(int id, bool isActive) =>
      _remoteDataSource.setActive(id, isActive);

  @override
  Future<void> deleteRole(int id) => _remoteDataSource.deleteRole(id);

  @override
  Future<PermissionTree> fetchPermissionTree(int roleId) =>
      _remoteDataSource.fetchPermissionTree(roleId);

  @override
  Future<void> assignPermissions(int roleId, List<int> permissionIds) =>
      _remoteDataSource.assignPermissions(roleId, permissionIds);
}
