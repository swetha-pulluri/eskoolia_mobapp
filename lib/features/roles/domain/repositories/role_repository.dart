import '../models/permission_tree.dart';
import '../models/role_data.dart';
import '../models/roles_page.dart';

/// Domain-facing seam over the Roles API.
/// Reference: backend/apps/access_control/views.py::RoleViewSet
abstract class RoleRepository {
  /// GET roles/?minimal=1&show_inactive=&search=
  Future<RolesPage> fetchRoles({
    String? search,
    bool showInactive = false,
    int page = 1,
    int pageSize = 100,
  });

  /// GET roles/{id}/ — full detail, including portal_type (the list/minimal
  /// endpoint omits it).
  Future<RoleData> fetchRoleDetail(int id);

  /// POST roles/ — creates a new role scoped to the caller's school
  /// (backend's perform_create sets school = request.user.school).
  Future<RoleData> createRole({
    required String name,
    required PortalType portalType,
  });

  /// PUT roles/{id}/
  Future<RoleData> updateRole(
    int id, {
    required String name,
    required bool isActive,
    required PortalType portalType,
  });

  /// PATCH roles/{id}/ — activate/deactivate only.
  Future<RoleData> setActive(int id, bool isActive);

  /// DELETE roles/{id}/ — throws if the role is a system role or has users
  /// assigned (backend business rule), surfaced via the error message.
  Future<void> deleteRole(int id);

  /// GET roles/{id}/permission-tree/
  Future<PermissionTree> fetchPermissionTree(int roleId);

  /// POST roles/{id}/assign-permissions/ — replaces the role's full
  /// permission set with [permissionIds].
  Future<void> assignPermissions(int roleId, List<int> permissionIds);
}
