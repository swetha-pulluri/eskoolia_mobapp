import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administration/presentation/providers/administration_list_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../roles/domain/models/role_data.dart';
import '../../../roles/domain/repositories/role_repository.dart';
import '../../../roles/presentation/providers/roles_providers.dart';
import '../../data/datasources/attendance_rules_remote_datasource.dart';
import '../../data/repositories/attendance_rules_repository_impl.dart';
import '../../domain/entities/attendance_policy_entity.dart';
import '../../domain/repositories/attendance_rules_repository.dart';
import 'attendance_rules_state.dart';

final attendanceRulesRemoteDataSourceProvider = Provider<AttendanceRulesRemoteDataSource>((ref) {
  return AttendanceRulesRemoteDataSource(ref.watch(dioClientProvider));
});

final attendanceRulesRepositoryProvider = Provider<AttendanceRulesRepository>((ref) {
  return AttendanceRulesRepositoryImpl(ref.watch(attendanceRulesRemoteDataSourceProvider));
});

final attendanceRulesNotifierProvider =
    StateNotifierProvider.autoDispose<AttendanceRulesNotifier, AttendanceRulesState>((ref) {
  return AttendanceRulesNotifier(ref.watch(attendanceRulesRepositoryProvider), ref.watch(roleRepositoryProvider));
});

/// Drives the policy list + 7-step wizard — a 1:1 port of every function in
/// `AttendanceRulesPanel.tsx`.
class AttendanceRulesNotifier extends StateNotifier<AttendanceRulesState> {
  final AttendanceRulesRepository _repository;
  final RoleRepository _roleRepository;

  AttendanceRulesNotifier(this._repository, this._roleRepository) : super(const AttendanceRulesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final policiesFuture = _repository.getPolicies();
      final rolesFuture = _loadRoles();
      final policies = await policiesFuture;
      final roles = await rolesFuture;
      state = state.copyWith(loading: false, policies: policies, roles: roles);
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }

  /// Mirrors `loadRoles` — excludes inactive roles and the Parent role. The
  /// list endpoint (`?minimal=1`) never returns `portal_type` at all (see
  /// `RoleData.portalType`'s own doc comment), so unlike the web (which can
  /// check `portal_type==='parent'` directly) this can only match by name;
  /// harmless in practice since `portal_type` is checked too whenever it
  /// happens to be present.
  Future<List<RoleData>> _loadRoles() async {
    try {
      final page = await _roleRepository.fetchRoles(showInactive: false, pageSize: 200);
      return page.results
          .where((r) => r.isActive)
          .where((r) => r.portalType != PortalType.parent)
          .where((r) => !RegExp(r'^parent$', caseSensitive: false).hasMatch(r.name))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void startCreate() {
    state = state.copyWith(editingId: null, draft: buildAttendanceWizardDefaults(), step: 0, wizardOpen: true);
  }

  void startEdit(AttendancePolicyEntity policy) {
    state = state.copyWith(editingId: policy.id, draft: policy.toFormMap(), step: 0, wizardOpen: true);
  }

  void closeWizard() {
    state = state.copyWith(wizardOpen: false, editingId: null);
  }

  void setStep(int step) => state = state.copyWith(step: step);

  void setDraftField(String key, dynamic value) {
    state = state.copyWith(draft: {...state.draft, key: value});
  }

  void toggleRole(int roleId) {
    final current = List<int>.from((state.draft['applies_to_roles'] as List?) ?? const <int>[]);
    if (current.contains(roleId)) {
      current.remove(roleId);
    } else {
      current.add(roleId);
    }
    setDraftField('applies_to_roles', current);
  }

  void toggleWeeklyOff(String key) {
    final current = (state.draft[key] as bool?) ?? false;
    setDraftField(key, !current);
  }

  Future<void> submit() async {
    state = state.copyWith(saving: true, error: null, success: null);
    try {
      final payload = Map<String, dynamic>.from(state.draft);
      final editingId = state.editingId;
      if (editingId != null) {
        final updated = await _repository.updatePolicy(editingId, payload);
        state = state.copyWith(
          saving: false,
          policies: [for (final p in state.policies) if (p.id == editingId) updated else p],
          success: 'Policy updated.',
          wizardOpen: false,
          editingId: null,
        );
      } else {
        final created = await _repository.createPolicy(payload);
        state = state.copyWith(
          saving: false,
          policies: [...state.policies, created],
          success: 'Attendance policy created.',
          wizardOpen: false,
          editingId: null,
        );
      }
    } catch (e) {
      state = state.copyWith(saving: false, error: adminErrorMessage(e));
      rethrow;
    }
  }

  Future<bool> delete(AttendancePolicyEntity policy) async {
    state = state.copyWith(busyId: policy.id, error: null);
    try {
      await _repository.deletePolicy(policy.id);
      state = state.copyWith(busyId: null, policies: state.policies.where((p) => p.id != policy.id).toList());
      // A deleted default policy is re-assigned server-side to another
      // active policy for the school — reload so the new default's badge
      // shows immediately instead of waiting for the next manual refresh.
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(busyId: null, error: adminErrorMessage(e));
      return false;
    }
  }

  Future<void> makeDefault(AttendancePolicyEntity policy) async {
    state = state.copyWith(busyId: policy.id, error: null);
    try {
      final updated = await _repository.makeDefault(policy.id);
      state = state.copyWith(
        busyId: null,
        policies: [
          for (final p in state.policies)
            if (p.id == updated.id) updated else p.copyWithDefault(false),
        ],
      );
    } catch (e) {
      state = state.copyWith(busyId: null, error: adminErrorMessage(e));
    }
  }

  Future<void> toggleHistory(AttendancePolicyEntity policy) async {
    if (state.historyOpenId == policy.id) {
      state = state.copyWith(historyOpenId: null);
      return;
    }
    state = state.copyWith(historyOpenId: policy.id, historyLoading: true, history: const []);
    try {
      final history = await _repository.getAuditLog(policy.id);
      state = state.copyWith(history: history, historyLoading: false);
    } catch (_) {
      state = state.copyWith(history: const [], historyLoading: false);
    }
  }
}
