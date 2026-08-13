import '../../../hr/domain/entities/department_entity.dart';
import '../../../hr/domain/entities/designation_entity.dart';
import '../../domain/entities/leave_policy_entity.dart';

const Object _unset = Object();

/// Combines every `useState` hook from `LeavePolicyPanel.tsx` (list +
/// wizard) into one immutable state object for a single `StateNotifier`.
class LeavePolicyState {
  final List<LeavePolicyEntity> policies;
  final List<DepartmentEntity> departments;
  final List<DesignationEntity> designations;
  final bool loading;
  final String? error;
  final String? success;
  final int? busyId;

  final bool wizardOpen;
  final int step;
  final int? editingId;
  final Map<String, dynamic> draft;
  final bool saving;

  final int? historyOpenId;
  final List<LeaveAuditEntry> history;
  final bool historyLoading;

  const LeavePolicyState({
    this.policies = const [],
    this.departments = const [],
    this.designations = const [],
    this.loading = true,
    this.error,
    this.success,
    this.busyId,
    this.wizardOpen = false,
    this.step = 0,
    this.editingId,
    this.draft = const {},
    this.saving = false,
    this.historyOpenId,
    this.history = const [],
    this.historyLoading = false,
  });

  bool get isEditing => editingId != null;

  LeavePolicyState copyWith({
    List<LeavePolicyEntity>? policies,
    List<DepartmentEntity>? departments,
    List<DesignationEntity>? designations,
    bool? loading,
    Object? error = _unset,
    Object? success = _unset,
    Object? busyId = _unset,
    bool? wizardOpen,
    int? step,
    Object? editingId = _unset,
    Map<String, dynamic>? draft,
    bool? saving,
    Object? historyOpenId = _unset,
    List<LeaveAuditEntry>? history,
    bool? historyLoading,
  }) {
    return LeavePolicyState(
      policies: policies ?? this.policies,
      departments: departments ?? this.departments,
      designations: designations ?? this.designations,
      loading: loading ?? this.loading,
      error: error == _unset ? this.error : error as String?,
      success: success == _unset ? this.success : success as String?,
      busyId: busyId == _unset ? this.busyId : busyId as int?,
      wizardOpen: wizardOpen ?? this.wizardOpen,
      step: step ?? this.step,
      editingId: editingId == _unset ? this.editingId : editingId as int?,
      draft: draft ?? this.draft,
      saving: saving ?? this.saving,
      historyOpenId: historyOpenId == _unset ? this.historyOpenId : historyOpenId as int?,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
    );
  }
}

/// `CarryForwardSection`'s own independent state — mirrors the web
/// splitting it into a separate component with its own `useState`s.
class CarryForwardState {
  final int fromYear;
  final int toYear;
  final List<Map<String, dynamic>>? rows;
  final List<Map<String, dynamic>> history;
  final bool loading;
  final String? error;
  final String? success;

  const CarryForwardState({
    required this.fromYear,
    required this.toYear,
    this.rows,
    this.history = const [],
    this.loading = false,
    this.error,
    this.success,
  });

  CarryForwardState copyWith({
    int? fromYear,
    int? toYear,
    Object? rows = _unset,
    List<Map<String, dynamic>>? history,
    bool? loading,
    Object? error = _unset,
    Object? success = _unset,
  }) {
    return CarryForwardState(
      fromYear: fromYear ?? this.fromYear,
      toYear: toYear ?? this.toYear,
      rows: rows == _unset ? this.rows : rows as List<Map<String, dynamic>>?,
      history: history ?? this.history,
      loading: loading ?? this.loading,
      error: error == _unset ? this.error : error as String?,
      success: success == _unset ? this.success : success as String?,
    );
  }
}
