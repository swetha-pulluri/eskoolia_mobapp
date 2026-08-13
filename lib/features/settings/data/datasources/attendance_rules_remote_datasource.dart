import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/attendance_policy_entity.dart';

/// Reference: backend/apps/settings/{urls,views}.py
/// (SchoolAttendancePolicyViewSet, SettingsAuditLogViewSet),
/// frontend/components/settings/AttendanceRulesPanel.tsx.
class AttendanceRulesRemoteDataSource {
  final DioClient _dioClient;

  AttendanceRulesRemoteDataSource(this._dioClient);

  /// List responses may be a bare array or DRF's `{count,results}` shape —
  /// tolerate both, same convention as every other Settings data source.
  static List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) return (data['results'] as List?) ?? const [];
    return const [];
  }

  Future<List<AttendancePolicyEntity>> getPolicies() async {
    final response = await _dioClient.get(ApiConstants.settingsAttendancePolicies);
    return _asList(response.data).map((e) => AttendancePolicyEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AttendancePolicyEntity> createPolicy(Map<String, dynamic> payload) async {
    final response = await _dioClient.post(ApiConstants.settingsAttendancePolicies, data: payload);
    return AttendancePolicyEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AttendancePolicyEntity> updatePolicy(int id, Map<String, dynamic> payload) async {
    final response = await _dioClient.patch(ApiConstants.settingsAttendancePolicyDetail(id), data: payload);
    return AttendancePolicyEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePolicy(int id) async {
    await _dioClient.delete(ApiConstants.settingsAttendancePolicyDetail(id));
  }

  Future<AttendancePolicyEntity> makeDefault(int id) async {
    final response = await _dioClient.post(ApiConstants.settingsAttendancePolicyMakeDefault(id));
    return AttendancePolicyEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AttendanceAuditEntry>> getAuditLog(int objectId) async {
    final response = await _dioClient.get(
      ApiConstants.settingsAuditLog,
      queryParameters: {'module': 'SchoolAttendancePolicy', 'object_id': objectId},
    );
    return _asList(response.data).map((e) => AttendanceAuditEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
