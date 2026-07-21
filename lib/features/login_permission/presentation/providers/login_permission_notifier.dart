import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/login_permission_api_results.dart';
import '../../domain/models/login_permission_user.dart';
import '../../domain/repositories/login_permission_repository.dart';
import 'login_permission_state.dart';

/// Login Permission Notifier
/// Drives the Login Permission screen: loads meta/roles once, then the
/// user list for whatever tab/role/filters are active.
class LoginPermissionNotifier extends StateNotifier<LoginPermissionScreenState> {
  final LoginPermissionRepository _repository;

  LoginPermissionNotifier(this._repository)
    : super(LoginPermissionScreenState.initial()) {
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    state = state.copyWith(metaLoading: true, metaError: null);
    try {
      final meta = await _repository.fetchMeta();
      state = state.copyWith(metaLoading: false, meta: meta, metaError: null);
      _selectDefaultTabAndRole();
      await _loadUsers();
    } catch (e) {
      state = state.copyWith(metaLoading: false, metaError: _cleanMessage(e));
    }
  }

  /// Re-attempts the initial meta load (e.g. after a "Retry" tap).
  Future<void> retryMeta() => _loadMeta();

  void _selectDefaultTabAndRole() {
    var chosenTab = state.activeTab;
    if (state.rolesForTab(chosenTab).isEmpty) {
      final withRoles = PortalTab.values.where(
        (t) => state.rolesForTab(t).isNotEmpty,
      );
      if (withRoles.isNotEmpty) chosenTab = withRoles.first;
    }
    final roles = state.rolesForTab(chosenTab);
    // Role names are kept in their original casing (not lowercased) — the
    // backend's role lookup is case-insensitive, so this is safe, and it
    // means the dropdown displays "Class Teacher" rather than a mangled
    // lowercase string, since the same string is both the display label and
    // the query value.
    final role = roles.isNotEmpty ? roles.first.name : null;
    state = state.copyWith(activeTab: chosenTab, role: role);
  }

  Future<void> changeTab(PortalTab tab) async {
    if (tab == state.activeTab) return;
    final roles = state.rolesForTab(tab);
    final role = roles.isNotEmpty ? roles.first.name : null;
    state = state.copyWith(
      activeTab: tab,
      role: role,
      searchQuery: '',
      statusFilter: StatusFilter.all,
      page: 1,
      pageResult: null,
      usersError: null,
      selectedIds: {},
    );
    if (role != null) await _loadUsers();
  }

  Future<void> changeRole(String role) async {
    if (role == state.role) return;
    state = state.copyWith(role: role, page: 1);
    await _loadUsers();
  }

  /// Updates the live search text without triggering a fetch (matches the
  /// existing filter bar: typing doesn't reload until Search is pressed).
  void updateSearchText(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> submitSearch() async {
    state = state.copyWith(page: 1);
    await _loadUsers();
  }

  Future<void> changeStatusFilter(StatusFilter filter) async {
    if (filter == state.statusFilter) return;
    state = state.copyWith(statusFilter: filter, page: 1);
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    final role = state.role;
    if (role == null) return;
    state = state.copyWith(usersLoading: true, usersError: null);
    try {
      final trimmedSearch = state.searchQuery.trim();
      final result = await _repository.listUsers(
        role: role,
        page: state.page,
        pageSize: state.pageSize,
        search: trimmedSearch.isEmpty ? null : trimmedSearch,
        status: _statusQueryValue(state.statusFilter),
      );
      // Drop any selected ids that are no longer present in the new result
      // (e.g. a re-run after search/status change), so the bulk action bar
      // never references rows that aren't visible anymore.
      final freshIds = result.results.map((u) => u.id).toSet();
      final reconciledSelection = state.selectedIds
          .where(freshIds.contains)
          .toSet();
      state = state.copyWith(
        usersLoading: false,
        pageResult: result,
        selectedIds: reconciledSelection,
      );
    } catch (e) {
      state = state.copyWith(usersLoading: false, usersError: _cleanMessage(e));
    }
  }

  /// Re-runs the current query — used after a credential action succeeds,
  /// matching the frontend's fetchUsers()-after-success behavior.
  Future<void> refreshCurrentPage() => _loadUsers();

  String _statusQueryValue(StatusFilter filter) {
    switch (filter) {
      case StatusFilter.all:
        return 'all';
      case StatusFilter.active:
        return 'active';
      case StatusFilter.disabled:
        return 'inactive';
      case StatusFilter.neverLoggedIn:
        return 'new';
    }
  }

  /// Optimistically toggles login access, calls the API, and rolls back on
  /// failure. Returns an error message on failure, or null on success.
  Future<String?> toggleAccess(String id, bool value) async {
    if (state.pendingIds.contains(id)) return null;
    final current = state.pageResult;
    if (current == null) return null;
    final index = current.results.indexWhere((u) => u.id == id);
    if (index == -1) return null;

    final optimisticResults = [...current.results];
    optimisticResults[index] = optimisticResults[index].copyWith(
      loginAccess: value,
    );
    final optimisticCounts = LoginPermissionCounts(
      total: current.counts.total,
      active: current.counts.active + (value ? 1 : -1),
      disabled: current.counts.disabled + (value ? -1 : 1),
      neverLoggedIn: current.counts.neverLoggedIn,
    );

    state = state.copyWith(
      pageResult: PageResult(
        results: optimisticResults,
        page: current.page,
        pageSize: current.pageSize,
        totalPages: current.totalPages,
        filteredCount: current.filteredCount,
        counts: optimisticCounts,
      ),
      pendingIds: {...state.pendingIds, id},
    );

    try {
      await _repository.toggleAccess(id, value);
      state = state.copyWith(pendingIds: {...state.pendingIds}..remove(id));
      return null;
    } catch (e) {
      state = state.copyWith(
        pageResult: current,
        pendingIds: {...state.pendingIds}..remove(id),
      );
      return _cleanMessage(e);
    }
  }

  /// Toggles a single row's checkbox (drives the bulk action bar).
  void toggleSelectRow(String id, bool selected) {
    final next = {...state.selectedIds};
    if (selected) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  /// Header "select all" checkbox — selects/deselects every user on the
  /// current page.
  void toggleSelectAllOnPage(bool selectAll) {
    if (selectAll) {
      state = state.copyWith(
        selectedIds: {...state.selectedIds, ...state.users.map((u) => u.id)},
      );
    } else {
      final pageIds = state.users.map((u) => u.id).toSet();
      state = state.copyWith(
        selectedIds: state.selectedIds.where((id) => !pageIds.contains(id)).toSet(),
      );
    }
  }

  /// Dismisses the bulk action bar without taking any action.
  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  /// Bulk enable/disable for every currently-selected user. Clears the
  /// selection and refreshes the list on success. Returns an error message
  /// on failure, or null on success.
  Future<String?> bulkSetAccess(bool loginAccess) async {
    final ids = state.selectedIds.toList();
    if (ids.isEmpty) return null;
    try {
      await _repository.bulkSetAccess(ids: ids, loginAccess: loginAccess);
      state = state.copyWith(selectedIds: {});
      await _loadUsers();
      return null;
    } catch (e) {
      return _cleanMessage(e);
    }
  }

  /// Bulk password reset for every currently-selected user. Clears the
  /// selection and refreshes the list on success (so "Must change" badges
  /// reflect the reset). Returns an error message on failure, or null on
  /// success.
  Future<String?> bulkResetPasswords() async {
    final ids = state.selectedIds.toList();
    if (ids.isEmpty) return null;
    try {
      await _repository.bulkResetPasswords(ids: ids);
      state = state.copyWith(selectedIds: {});
      await _loadUsers();
      return null;
    } catch (e) {
      return _cleanMessage(e);
    }
  }

  String _cleanMessage(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
