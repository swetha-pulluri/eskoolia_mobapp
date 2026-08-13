import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/leave_policy_entity.dart';

/// Reference: backend/apps/settings/{urls,views}.py (LeavePolicyViewSet,
/// LeaveCarryForward*View, SettingsAuditLogViewSet),
/// frontend/components/settings/LeavePolicyPanel.tsx.
class LeavePolicyRemoteDataSource {
  final DioClient _dioClient;

  LeavePolicyRemoteDataSource(this._dioClient);

  /// List responses may be a bare array or DRF's `{count,results}` shape —
  /// tolerate both, same as `PaginatedResult.fromJson`.
  static List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) return (data['results'] as List?) ?? const [];
    return const [];
  }

  Future<List<LeavePolicyEntity>> getPolicies() async {
    final response = await _dioClient.get(ApiConstants.settingsLeavePolicy);
    return _asList(response.data).map((e) => LeavePolicyEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LeavePolicyEntity> createPolicy(Map<String, dynamic> payload) async {
    final response = await _dioClient.post(ApiConstants.settingsLeavePolicy, data: payload);
    return LeavePolicyEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LeavePolicyEntity> updatePolicy(int id, Map<String, dynamic> payload) async {
    final response = await _dioClient.patch(ApiConstants.settingsLeavePolicyDetail(id), data: payload);
    return LeavePolicyEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePolicy(int id) async {
    await _dioClient.delete(ApiConstants.settingsLeavePolicyDetail(id));
  }

  Future<List<LeaveAuditEntry>> getAuditLog(int objectId) async {
    final response = await _dioClient.get(
      ApiConstants.settingsAuditLog,
      queryParameters: {'module': 'LeaveType', 'object_id': objectId},
    );
    return _asList(response.data).map((e) => LeaveAuditEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> previewCarryForward(int fromYear, int toYear) async {
    final response = await _dioClient.post(
      ApiConstants.settingsLeaveCarryForwardPreview,
      data: {'from_year': fromYear, 'to_year': toYear},
    );
    final data = response.data as Map<String, dynamic>;
    return ((data['rows'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> runCarryForward(int fromYear, int toYear) async {
    final response = await _dioClient.post(
      ApiConstants.settingsLeaveCarryForwardRun,
      data: {'from_year': fromYear, 'to_year': toYear},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCarryForwardHistory() async {
    final response = await _dioClient.get(ApiConstants.settingsLeaveCarryForwardHistory);
    return _asList(response.data).cast<Map<String, dynamic>>();
  }
}
