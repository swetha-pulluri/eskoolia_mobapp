import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/role_data.dart';
import '../../domain/repositories/role_repository.dart';
import 'roles_state.dart';

/// Roles Notifier
/// Drives the Roles & Permissions "Roles" tab: loads the role list from the
/// real backend and re-fetches on search/show-inactive changes (matching the
/// frontend's debounced re-fetch, not client-side filtering of an
/// already-loaded list).
class RolesNotifier extends StateNotifier<RolesScreenState> {
  final RoleRepository _repository;
  Timer? _searchDebounce;

  RolesNotifier(this._repository) : super(RolesScreenState.initial()) {
    _loadRoles();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final page = await _repository.fetchRoles(
        search: state.searchQuery.trim().isEmpty
            ? null
            : state.searchQuery.trim(),
        showInactive: state.showInactive,
      );
      state = state.copyWith(
        loading: false,
        roles: page.results,
        totalCount: page.count,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _cleanMessage(e));
    }
  }

  Future<void> refresh() => _loadRoles();

  /// Updates the live search text and debounces a re-fetch (matches the
  /// frontend's 250ms setTimeout re-fetch on search change).
  void updateSearch(String value) {
    state = state.copyWith(searchQuery: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _loadRoles);
  }

  Future<void> toggleShowInactive() async {
    state = state.copyWith(showInactive: !state.showInactive);
    await _loadRoles();
  }

  /// Selecting a role both highlights its card and (on touch devices, where
  /// there's no hover) reveals its action icons.
  void selectRole(int? id) {
    state = state.copyWith(
      selectedRoleId: state.selectedRoleId == id ? null : id,
    );
  }

  /// Optimistically flips active/inactive, calls the API, rolls back on
  /// failure. Returns an error message on failure, or null on success.
  Future<String?> setActive(int id, bool isActive) async {
    if (state.mutatingIds.contains(id)) return null;
    final index = state.roles.indexWhere((r) => r.id == id);
    if (index == -1) return null;
    final previous = state.roles[index];

    final optimistic = [...state.roles];
    optimistic[index] = previous.copyWith(isActive: isActive);
    state = state.copyWith(
      roles: optimistic,
      mutatingIds: {...state.mutatingIds, id},
    );

    try {
      final updated = await _repository.setActive(id, isActive);
      final refreshed = [...state.roles];
      final freshIndex = refreshed.indexWhere((r) => r.id == id);
      if (freshIndex != -1) refreshed[freshIndex] = updated;
      state = state.copyWith(
        roles: refreshed,
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
      return null;
    } catch (e) {
      final rolledBack = [...state.roles];
      final rollbackIndex = rolledBack.indexWhere((r) => r.id == id);
      if (rollbackIndex != -1) rolledBack[rollbackIndex] = previous;
      state = state.copyWith(
        roles: rolledBack,
        mutatingIds: {...state.mutatingIds}..remove(id),
      );
      return _cleanMessage(e);
    }
  }

  /// Deletes a role and removes it from the list on success. Returns an
  /// error message on failure, or null on success.
  Future<String?> deleteRole(int id) async {
    if (state.mutatingIds.contains(id)) return null;
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});
    try {
      await _repository.deleteRole(id);
      state = state.copyWith(
        roles: state.roles.where((r) => r.id != id).toList(),
        totalCount: state.totalCount - 1,
        mutatingIds: {...state.mutatingIds}..remove(id),
        selectedRoleId: state.selectedRoleId == id ? null : state.selectedRoleId,
      );
      return null;
    } catch (e) {
      state = state.copyWith(mutatingIds: {...state.mutatingIds}..remove(id));
      return _cleanMessage(e);
    }
  }

  /// Merges a freshly-updated role (from the Edit panel) into the current
  /// list without a full re-fetch.
  void applyUpdatedRole(RoleData updated) {
    final next = [...state.roles];
    final index = next.indexWhere((r) => r.id == updated.id);
    if (index != -1) next[index] = updated;
    state = state.copyWith(roles: next);
  }

  String _cleanMessage(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
