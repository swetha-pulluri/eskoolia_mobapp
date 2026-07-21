import 'login_permission_user.dart';

/// A role as returned by GET login-permission/meta/.
/// Matches backend `LoginPermissionViewSet._meta_response` exactly.
class RoleOption {
  final String id;
  final String name;
  final bool isStudent;
  final String portalType;

  RoleOption({
    required this.id,
    required this.name,
    required this.isStudent,
    required this.portalType,
  });

  factory RoleOption.fromJson(Map<String, dynamic> json) {
    return RoleOption(
      id: json['id'] as String,
      name: json['name'] as String,
      isStudent: json['isStudent'] as bool? ?? false,
      portalType: json['portalType'] as String? ?? 'admin',
    );
  }
}

class ClassOption {
  final String id;
  final String name;

  ClassOption({required this.id, required this.name});

  factory ClassOption.fromJson(Map<String, dynamic> json) {
    return ClassOption(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class SectionOption {
  final String id;
  final String name;
  final String classId;

  SectionOption({required this.id, required this.name, required this.classId});

  factory SectionOption.fromJson(Map<String, dynamic> json) {
    return SectionOption(
      id: json['id'] as String,
      name: json['name'] as String,
      classId: json['classId'] as String,
    );
  }
}

class MetaResult {
  final List<RoleOption> roles;
  final List<ClassOption> classes;
  final List<SectionOption> sections;

  MetaResult({
    required this.roles,
    required this.classes,
    required this.sections,
  });

  factory MetaResult.fromJson(Map<String, dynamic> json) {
    return MetaResult(
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((e) => RoleOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      classes: (json['classes'] as List<dynamic>? ?? [])
          .map((e) => ClassOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((e) => SectionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Classifies a backend Role into one of the app's fixed portal tabs.
/// Ported verbatim from frontend `getRoleTab()` in
/// frontend/app/(dashboard)/roles/login-permission/page.tsx so tab grouping
/// matches the web app exactly.
PortalTab getPortalTabForRole(RoleOption role) {
  final name = role.name.toLowerCase();
  final pt = role.portalType.toLowerCase();

  if (pt == 'teacher' || name.contains('teacher')) return PortalTab.teacher;
  if (pt == 'student' || role.isStudent || name.contains('student')) {
    return PortalTab.student;
  }
  if (pt == 'parent' || name.contains('parent') || name.contains('guardian')) {
    return PortalTab.parent;
  }
  if (name.contains('driver') ||
      name.contains('transport') ||
      name.contains('bus') ||
      name.contains('vehicle')) {
    return PortalTab.driver;
  }
  if (name.contains('principal') ||
      name.contains('vice') ||
      name.contains('hod') ||
      name.contains('head of') ||
      name.contains('rector') ||
      name.contains('headmaster') ||
      name.contains('headmistress')) {
    return PortalTab.principal;
  }
  return PortalTab.staff;
}
