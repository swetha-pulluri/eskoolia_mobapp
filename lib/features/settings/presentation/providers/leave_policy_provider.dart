import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administration/presentation/providers/administration_list_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../hr/domain/entities/department_entity.dart';
import '../../../hr/domain/entities/designation_entity.dart';
import '../../../hr/domain/repositories/hr_repository.dart';
import '../../../hr/presentation/providers/hr_provider.dart';
import '../../data/datasources/leave_policy_remote_datasource.dart';
import '../../data/repositories/leave_policy_repository_impl.dart';
import '../../domain/entities/leave_policy_entity.dart';
import '../../domain/leave_policy_choices.dart';
import '../../domain/repositories/leave_policy_repository.dart';
import 'leave_policy_state.dart';

final leavePolicyRemoteDataSourceProvider = Provider<LeavePolicyRemoteDataSource>((ref) {
  return LeavePolicyRemoteDataSource(ref.watch(dioClientProvider));
});

final leavePolicyRepositoryProvider = Provider<LeavePolicyRepository>((ref) {
  return LeavePolicyRepositoryImpl(ref.watch(leavePolicyRemoteDataSourceProvider));
});

final leavePolicyNotifierProvider =
    StateNotifierProvider.autoDispose<LeavePolicyNotifier, LeavePolicyState>((ref) {
  return LeavePolicyNotifier(ref.watch(leavePolicyRepositoryProvider), ref.watch(hrRepositoryProvider));
});

final carryForwardNotifierProvider =
    StateNotifierProvider.autoDispose<CarryForwardNotifier, CarryForwardState>((ref) {
  return CarryForwardNotifier(ref.watch(leavePolicyRepositoryProvider));
});

/// Drives the leave-types list + 9-step wizard — a 1:1 port of every
/// function in `LeavePolicyPanel.tsx` (excluding `CarryForwardSection`,
/// which has its own independent [CarryForwardNotifier] below, matching the
/// web's own component split).
class LeavePolicyNotifier extends StateNotifier<LeavePolicyState> {
  final LeavePolicyRepository _repository;
  final HrRepository _hrRepository;

  LeavePolicyNotifier(this._repository, this._hrRepository) : super(const LeavePolicyState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final policiesFuture = _repository.getPolicies();
      final departmentsFuture = _hrRepository
          .getAllDepartments()
          .then((r) => r.results)
          .catchError((_) => <DepartmentEntity>[]);
      final designationsFuture = _hrRepository
          .getDesignations()
          .then((r) => r.results)
          .catchError((_) => <DesignationEntity>[]);
      final policies = await policiesFuture;
      final departments = await departmentsFuture;
      final designations = await designationsFuture;
      state = state.copyWith(
        loading: false,
        policies: policies,
        departments: departments,
        designations: designations,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }

  void startCreate() {
    state = state.copyWith(editingId: null, draft: buildLeaveWizardDefaults(), step: 0, wizardOpen: true);
  }

  void startEdit(LeavePolicyEntity policy) {
    state = state.copyWith(editingId: policy.id, draft: policy.toFormMap(), step: 0, wizardOpen: true);
  }

  void closeWizard() {
    state = state.copyWith(wizardOpen: false, editingId: null);
  }

  void setStep(int step) => state = state.copyWith(step: step);

  void setDraftField(String key, dynamic value) {
    state = state.copyWith(draft: {...state.draft, key: value});
  }

  /// Toggles one value in a multi-select scope field (`applicable_*`) —
  /// mirrors `toggleListValue`.
  void toggleListValue(String key, String value) {
    final current = List<String>.from((state.draft[key] as List?) ?? const <String>[]);
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    setDraftField(key, current);
  }

  /// Mirrors `buildPayload()` — always sends every editable field in full,
  /// no partial diffing, on both create and update.
  Map<String, dynamic> _buildPayload() {
    final source = state.draft;
    final payload = <String, dynamic>{};
    for (final key in identityKeys) {
      payload[key] = source[key];
    }
    for (final key in allFieldKeys) {
      payload[key] = source[key];
    }
    for (final key in scopeKeys) {
      payload[key] = source[key] ?? const <String>[];
    }
    return payload;
  }

  Future<void> submit() async {
    state = state.copyWith(saving: true, error: null, success: null);
    try {
      final payload = _buildPayload();
      final editingId = state.editingId;
      if (editingId != null) {
        final updated = await _repository.updatePolicy(editingId, payload);
        state = state.copyWith(
          saving: false,
          policies: [for (final p in state.policies) if (p.id == editingId) updated else p],
          success: 'Leave type updated.',
          wizardOpen: false,
          editingId: null,
        );
      } else {
        final created = await _repository.createPolicy(payload);
        state = state.copyWith(
          saving: false,
          policies: [...state.policies, created],
          success: 'Leave type created.',
          wizardOpen: false,
          editingId: null,
        );
      }
    } catch (e) {
      state = state.copyWith(saving: false, error: adminErrorMessage(e));
      rethrow;
    }
  }

  /// Returns whether the delete actually went through — mirrors the web's
  /// `handleDelete`, which surfaces a server message (e.g. "built-in or
  /// already in use") on failure instead of removing the card.
  Future<bool> delete(LeavePolicyEntity policy) async {
    state = state.copyWith(busyId: policy.id, error: null);
    try {
      await _repository.deletePolicy(policy.id);
      state = state.copyWith(busyId: null, policies: state.policies.where((p) => p.id != policy.id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(busyId: null, error: adminErrorMessage(e));
      return false;
    }
  }

  Future<void> toggleHistory(LeavePolicyEntity policy) async {
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

/// Drives the standalone "Leave Balance Carry-Forward" section — mirrors
/// `CarryForwardSection`'s own local state, independent of the leave-types
/// list/wizard above.
class CarryForwardNotifier extends StateNotifier<CarryForwardState> {
  final LeavePolicyRepository _repository;

  CarryForwardNotifier(this._repository)
      : super(CarryForwardState(fromYear: DateTime.now().year - 1, toYear: DateTime.now().year)) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final history = await _repository.getCarryForwardHistory();
      state = state.copyWith(history: history);
    } catch (_) {
      // Non-fatal — history is supplementary, matches the web's silent catch.
    }
  }

  void setFromYear(int year) => state = state.copyWith(fromYear: year);

  void setToYear(int year) => state = state.copyWith(toYear: year);

  Future<void> preview() async {
    state = state.copyWith(loading: true, error: null, success: null);
    try {
      final rows = await _repository.previewCarryForward(state.fromYear, state.toYear);
      state = state.copyWith(loading: false, rows: rows);
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }

  Future<void> run() async {
    state = state.copyWith(loading: true, error: null, success: null);
    try {
      final log = await _repository.runCarryForward(state.fromYear, state.toYear);
      final processed = log['total_processed'] ?? 0;
      final skipped = log['total_skipped'] ?? 0;
      final failed = log['total_failed'] ?? 0;
      state = state.copyWith(
        loading: false,
        rows: null,
        success: 'Carry-forward run complete: $processed processed, $skipped skipped, $failed failed.',
      );
      await loadHistory();
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }
}
