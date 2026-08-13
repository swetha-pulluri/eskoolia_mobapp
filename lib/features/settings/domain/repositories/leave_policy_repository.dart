import '../entities/leave_policy_entity.dart';

/// Settings → Leave Policy — backed by `/api/v1/settings/leave-policy/`
/// (backend/apps/settings/views.py::LeavePolicyViewSet) plus the
/// leave-carry-forward and audit-log sub-resources it renders alongside.
abstract class LeavePolicyRepository {
  Future<List<LeavePolicyEntity>> getPolicies();

  Future<LeavePolicyEntity> createPolicy(Map<String, dynamic> payload);

  Future<LeavePolicyEntity> updatePolicy(int id, Map<String, dynamic> payload);

  Future<void> deletePolicy(int id);

  Future<List<LeaveAuditEntry>> getAuditLog(int objectId);

  Future<List<Map<String, dynamic>>> previewCarryForward(int fromYear, int toYear);

  Future<Map<String, dynamic>> runCarryForward(int fromYear, int toYear);

  Future<List<Map<String, dynamic>>> getCarryForwardHistory();
}
