/// Role Data Model
/// Source: frontend/components/access-control/RoleManagementPanel.tsx - RoleItem type
///
/// Represents a role in the access control system with portal type,
/// system status, and active state.
class RoleData {
  final int id;
  final String name;
  final bool isSystem;
  final bool isActive;

  /// Null when this role came from the list endpoint (`?minimal=1`), which
  /// (matching the backend's `RoleMinimalSerializer` and the frontend's own
  /// list fetch) omits `portal_type` entirely — only the single-role detail
  /// fetch (`GET /roles/{id}/`) returns it. The portal badge is simply
  /// hidden when null, matching the frontend's `role.portal_type &&` guard.
  final PortalType? portalType;
  final DateTime? createdAt;

  const RoleData({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.isActive,
    this.portalType,
    this.createdAt,
  });

  RoleData copyWith({
    String? name,
    bool? isActive,
    PortalType? portalType,
  }) {
    return RoleData(
      id: id,
      name: name ?? this.name,
      isSystem: isSystem,
      isActive: isActive ?? this.isActive,
      portalType: portalType ?? this.portalType,
      createdAt: createdAt,
    );
  }

  /// Create RoleData from JSON
  factory RoleData.fromJson(Map<String, dynamic> json) {
    return RoleData(
      id: json['id'] as int,
      name: json['name'] as String,
      isSystem: json['is_system'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      portalType: _portalTypeFromString(json['portal_type'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert RoleData to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_system': isSystem,
      'is_active': isActive,
      if (portalType != null) 'portal_type': portalType!.value,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Helper to parse portal type from string — returns null when absent
  /// (minimal list responses) rather than guessing.
  static PortalType? _portalTypeFromString(String? value) {
    switch (value) {
      case 'admin':
        return PortalType.admin;
      case 'teacher':
        return PortalType.teacher;
      case 'parent':
        return PortalType.parent;
      case 'student':
        return PortalType.student;
      case 'custom':
        return PortalType.custom;
      default:
        return null;
    }
  }

}

/// Portal Type Enum
/// Controls which portal users with this role are sent to after login
enum PortalType {
  admin('admin', 'Admin', 'School admin / management staff'),
  teacher('teacher', 'Teacher', 'Teachers and class teachers'),
  parent('parent', 'Parent', 'Parents and guardians'),
  student('student', 'Student', 'Enrolled students'),
  custom('custom', 'Custom', 'Configurable access via permissions');

  const PortalType(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;
}
