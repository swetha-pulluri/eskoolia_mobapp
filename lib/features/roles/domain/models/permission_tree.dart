/// A single assignable permission — leaf node of the permission tree.
/// Reference: backend/apps/access_control/views.py::RoleViewSet._build_permission_tree_rows
class PermissionNode {
  final int id;
  final String code;
  final String name;
  final bool selected;

  const PermissionNode({
    required this.id,
    required this.code,
    required this.name,
    required this.selected,
  });

  factory PermissionNode.fromJson(Map<String, dynamic> json) {
    return PermissionNode(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      selected: json['selected'] as bool? ?? false,
    );
  }
}

/// A module grouping of permissions (e.g. "fees", "students").
class PermissionModule {
  final String module;
  final String moduleName;
  final List<PermissionNode> permissions;

  const PermissionModule({
    required this.module,
    required this.moduleName,
    required this.permissions,
  });

  factory PermissionModule.fromJson(Map<String, dynamic> json) {
    return PermissionModule(
      module: json['module'] as String,
      moduleName: json['module_name'] as String,
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((e) => PermissionNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// GET roles/{id}/permission-tree/ response shape.
class PermissionTree {
  final int roleId;
  final String roleName;
  final List<PermissionModule> modules;

  const PermissionTree({
    required this.roleId,
    required this.roleName,
    required this.modules,
  });

  factory PermissionTree.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;
    return PermissionTree(
      roleId: role?['id'] as int? ?? 0,
      roleName: role?['name'] as String? ?? '',
      modules: (json['modules'] as List<dynamic>? ?? [])
          .map((e) => PermissionModule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
