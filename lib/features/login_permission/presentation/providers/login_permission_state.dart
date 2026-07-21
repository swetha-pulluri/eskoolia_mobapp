import '../../domain/models/login_permission_api_results.dart';
import '../../domain/models/login_permission_meta.dart';
import '../../domain/models/login_permission_user.dart';

/// Sentinel used by [LoginPermissionScreenState.copyWith] to distinguish
/// "leave this field unchanged" from "set this field to null".
const Object _unset = Object();

/// Screen state for the Login Permission page. A single flat class (rather
/// than a sealed union like AuthState) since this screen has many
/// concurrently-relevant pieces of state — meta, active tab/filters, and the
/// current page of users — not a small set of mutually-exclusive phases.
class LoginPermissionScreenState {
  final bool metaLoading;
  final String? metaError;
  final MetaResult? meta;

  final PortalTab activeTab;
  final String? role;
  final String searchQuery;
  final StatusFilter statusFilter;
  final int page;
  final int pageSize;

  final bool usersLoading;
  final String? usersError;
  final PageResult? pageResult;

  /// User ids with an in-flight toggle/credential request.
  final Set<String> pendingIds;

  /// Ids currently checked in the users table (drives the bulk action bar).
  final Set<String> selectedIds;

  const LoginPermissionScreenState({
    required this.metaLoading,
    this.metaError,
    this.meta,
    required this.activeTab,
    this.role,
    required this.searchQuery,
    required this.statusFilter,
    required this.page,
    required this.pageSize,
    required this.usersLoading,
    this.usersError,
    this.pageResult,
    required this.pendingIds,
    required this.selectedIds,
  });

  factory LoginPermissionScreenState.initial() {
    return const LoginPermissionScreenState(
      metaLoading: true,
      activeTab: PortalTab.teacher,
      searchQuery: '',
      statusFilter: StatusFilter.all,
      page: 1,
      pageSize: 100,
      usersLoading: false,
      pendingIds: {},
      selectedIds: {},
    );
  }

  LoginPermissionScreenState copyWith({
    bool? metaLoading,
    Object? metaError = _unset,
    Object? meta = _unset,
    PortalTab? activeTab,
    Object? role = _unset,
    String? searchQuery,
    StatusFilter? statusFilter,
    int? page,
    int? pageSize,
    bool? usersLoading,
    Object? usersError = _unset,
    Object? pageResult = _unset,
    Set<String>? pendingIds,
    Set<String>? selectedIds,
  }) {
    return LoginPermissionScreenState(
      metaLoading: metaLoading ?? this.metaLoading,
      metaError: identical(metaError, _unset)
          ? this.metaError
          : metaError as String?,
      meta: identical(meta, _unset) ? this.meta : meta as MetaResult?,
      activeTab: activeTab ?? this.activeTab,
      role: identical(role, _unset) ? this.role : role as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      usersLoading: usersLoading ?? this.usersLoading,
      usersError: identical(usersError, _unset)
          ? this.usersError
          : usersError as String?,
      pageResult: identical(pageResult, _unset)
          ? this.pageResult
          : pageResult as PageResult?,
      pendingIds: pendingIds ?? this.pendingIds,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  /// Roles belonging to [tab], grouped from meta using the same
  /// classification the frontend uses for its portal tab badges/dropdowns.
  List<RoleOption> rolesForTab(PortalTab tab) {
    final roles = meta?.roles;
    if (roles == null) return const [];
    return roles.where((r) => getPortalTabForRole(r) == tab).toList();
  }

  List<RoleOption> get currentTabRoles => rolesForTab(activeTab);

  /// Role-count badge per tab (matches the frontend's per-tab role count,
  /// e.g. "Teachers 2" for Teacher + Class Teacher).
  Map<PortalTab, int> get tabCounts {
    return {
      for (final tab in PortalTab.values) tab: rolesForTab(tab).length,
    };
  }

  List<LoginPermissionUser> get users => pageResult?.results ?? const [];

  LoginPermissionCounts get counts =>
      pageResult?.counts ??
      LoginPermissionCounts(total: 0, active: 0, disabled: 0, neverLoggedIn: 0);

  bool get hasRolesForActiveTab => currentTabRoles.isNotEmpty;

  bool get allOnPageSelected =>
      users.isNotEmpty && users.every((u) => selectedIds.contains(u.id));
}
