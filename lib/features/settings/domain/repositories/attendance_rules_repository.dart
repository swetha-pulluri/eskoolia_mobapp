import '../entities/attendance_policy_entity.dart';

/// Reference: backend/apps/settings/{urls,views,serializers}.py
/// (SchoolAttendancePolicyViewSet — a real CRUD list, one row per named
/// policy, exactly one flagged `is_default`),
/// frontend/components/settings/AttendanceRulesPanel.tsx.
abstract class AttendanceRulesRepository {
  Future<List<AttendancePolicyEntity>> getPolicies();

  Future<AttendancePolicyEntity> createPolicy(Map<String, dynamic> payload);

  Future<AttendancePolicyEntity> updatePolicy(int id, Map<String, dynamic> payload);

  Future<void> deletePolicy(int id);

  /// POST .../{id}/make_default/ — unsets `is_default` on every sibling
  /// policy for the school, then sets it on this one.
  Future<AttendancePolicyEntity> makeDefault(int id);

  Future<List<AttendanceAuditEntry>> getAuditLog(int objectId);
}
