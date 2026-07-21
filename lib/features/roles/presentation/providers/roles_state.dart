import '../../domain/models/role_data.dart';

/// Sentinel used by [RolesScreenState.copyWith] to distinguish "leave this
/// field unchanged" from "set this field to null".
const Object _unset = Object();

class RolesScreenState {
  final bool loading;
  final String? error;
  final List<RoleData> roles;
  final int totalCount;

  final String searchQuery;
  final bool showInactive;
  final int? selectedRoleId;

  /// Role ids with an in-flight activate/deactivate/delete request.
  final Set<int> mutatingIds;

  const RolesScreenState({
    required this.loading,
    this.error,
    required this.roles,
    required this.totalCount,
    required this.searchQuery,
    required this.showInactive,
    this.selectedRoleId,
    required this.mutatingIds,
  });

  factory RolesScreenState.initial() {
    return const RolesScreenState(
      loading: true,
      roles: [],
      totalCount: 0,
      searchQuery: '',
      showInactive: false,
      mutatingIds: {},
    );
  }

  RolesScreenState copyWith({
    bool? loading,
    Object? error = _unset,
    List<RoleData>? roles,
    int? totalCount,
    String? searchQuery,
    bool? showInactive,
    Object? selectedRoleId = _unset,
    Set<int>? mutatingIds,
  }) {
    return RolesScreenState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      roles: roles ?? this.roles,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
      showInactive: showInactive ?? this.showInactive,
      selectedRoleId: identical(selectedRoleId, _unset)
          ? this.selectedRoleId
          : selectedRoleId as int?,
      mutatingIds: mutatingIds ?? this.mutatingIds,
    );
  }
}
