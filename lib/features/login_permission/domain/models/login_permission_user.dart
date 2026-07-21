class LoginPermissionUser {
  final String id;
  final String staffId;
  final String name;
  final String role;
  final String email;
  final bool loginAccess;
  final DateTime? lastLogin;
  final bool mustChange;

  /// Dev login credentials — mock mode only (mirrors frontend MOCK_ACCOUNTS).
  /// Present only for seeded dev accounts so the credential drawer can surface
  /// the shared team login. Null for ordinary users.
  final String? devUsername;
  final String? devPassword;

  LoginPermissionUser({
    required this.id,
    required this.staffId,
    required this.name,
    required this.role,
    required this.email,
    required this.loginAccess,
    this.lastLogin,
    required this.mustChange,
    this.devUsername,
    this.devPassword,
  });

  /// Returns a copy with selected fields overridden.
  LoginPermissionUser copyWith({
    bool? loginAccess,
    DateTime? lastLogin,
    bool? mustChange,
  }) {
    return LoginPermissionUser(
      id: id,
      staffId: staffId,
      name: name,
      role: role,
      email: email,
      loginAccess: loginAccess ?? this.loginAccess,
      lastLogin: lastLogin ?? this.lastLogin,
      mustChange: mustChange ?? this.mustChange,
      devUsername: devUsername,
      devPassword: devPassword,
    );
  }

  factory LoginPermissionUser.fromJson(Map<String, dynamic> json) {
    return LoginPermissionUser(
      id: json['id'] as String,
      staffId: json['staffId'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      email: json['email'] as String,
      loginAccess: json['loginAccess'] as bool,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      mustChange: json['mustChange'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'name': name,
      'role': role,
      'email': email,
      'loginAccess': loginAccess,
      'lastLogin': lastLogin?.toIso8601String(),
      'mustChange': mustChange,
    };
  }
}

class LoginPermissionCounts {
  final int total;
  final int active;
  final int disabled;
  final int neverLoggedIn;

  LoginPermissionCounts({
    required this.total,
    required this.active,
    required this.disabled,
    required this.neverLoggedIn,
  });

  factory LoginPermissionCounts.fromJson(Map<String, dynamic> json) {
    return LoginPermissionCounts(
      total: json['total'] as int,
      active: json['active'] as int,
      disabled: json['disabled'] as int,
      neverLoggedIn: json['neverLoggedIn'] as int? ?? 0,
    );
  }
}

enum PortalTab {
  teacher,
  principal,
  student,
  parent,
  driver,
  staff;

  String get label {
    switch (this) {
      case PortalTab.teacher:
        return 'Teachers';
      case PortalTab.principal:
        return 'Principals';
      case PortalTab.student:
        return 'Students';
      case PortalTab.parent:
        return 'Parents';
      case PortalTab.driver:
        return 'Drivers';
      case PortalTab.staff:
        return 'Admin Staff';
    }
  }

  String get title {
    switch (this) {
      case PortalTab.teacher:
        return 'Teaching Staff';
      case PortalTab.principal:
        return 'Principals & Leadership';
      case PortalTab.student:
        return 'Students';
      case PortalTab.parent:
        return 'Parents & Guardians';
      case PortalTab.driver:
        return 'Drivers & Transport Staff';
      case PortalTab.staff:
        return 'Admin & Support Staff';
    }
  }

  String get subtitle {
    switch (this) {
      case PortalTab.teacher:
        return 'Manage login access and credentials for all teachers and class teachers.';
      case PortalTab.principal:
        return 'Manage login access and credentials for principals, vice principals, and HODs.';
      case PortalTab.student:
        return 'Manage login access and portal credentials for enrolled students.';
      case PortalTab.parent:
        return 'Manage login access and credentials for parents and guardians.';
      case PortalTab.driver:
        return 'Manage login access and credentials for transport and driver staff.';
      case PortalTab.staff:
        return 'Manage login access and credentials for administrative and support staff.';
    }
  }

  String get badge {
    switch (this) {
      case PortalTab.teacher:
        return 'TEACHER PORTAL';
      case PortalTab.principal:
        return 'ADMIN CONSOLE';
      case PortalTab.student:
        return 'STUDENT PORTAL';
      case PortalTab.parent:
        return 'PARENT PORTAL';
      case PortalTab.driver:
        return 'TRANSPORT ROLE';
      case PortalTab.staff:
        return 'ADMIN CONSOLE';
    }
  }
}

enum StatusFilter {
  all,
  active,
  disabled,
  neverLoggedIn;

  String get label {
    switch (this) {
      case StatusFilter.all:
        return 'All';
      case StatusFilter.active:
        return 'Active';
      case StatusFilter.disabled:
        return 'Disabled';
      case StatusFilter.neverLoggedIn:
        return 'Never logged in';
    }
  }
}
