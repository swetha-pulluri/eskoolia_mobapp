import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/smtp_config_entity.dart';

/// Reference: backend/apps/settings/{urls,views}.py
/// (SchoolSMTPSettingsViewSet), frontend/components/settings/SmtpSettingsPanel.tsx.
class SmtpSettingsRemoteDataSource {
  final DioClient _dioClient;

  SmtpSettingsRemoteDataSource(this._dioClient);

  /// List responses may be a bare array or DRF's `{count,results}` shape.
  static List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) return (data['results'] as List?) ?? const [];
    return const [];
  }

  Future<List<SmtpConfigEntity>> getConfigs() async {
    final response = await _dioClient.get(ApiConstants.settingsSmtp);
    return _asList(response.data).map((e) => SmtpConfigEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SmtpConfigEntity> createConfig(Map<String, dynamic> payload) async {
    final response = await _dioClient.post(ApiConstants.settingsSmtp, data: payload);
    return SmtpConfigEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SmtpConfigEntity> updateConfig(int id, Map<String, dynamic> payload) async {
    final response = await _dioClient.patch(ApiConstants.settingsSmtpDetail(id), data: payload);
    return SmtpConfigEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteConfig(int id) async {
    await _dioClient.delete(ApiConstants.settingsSmtpDetail(id));
  }

  Future<SmtpConfigEntity> activateConfig(int id) async {
    final response = await _dioClient.post(ApiConstants.settingsSmtpActivate(id));
    return SmtpConfigEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> testSend(Map<String, dynamic> payload) async {
    await _dioClient.post(ApiConstants.settingsSmtpTestSend, data: payload);
  }

  Future<List<SmtpAuditEntry>> getAuditLog(int objectId) async {
    final response = await _dioClient.get(
      ApiConstants.settingsAuditLog,
      queryParameters: {'module': 'SchoolSMTPSettings', 'object_id': objectId},
    );
    return _asList(response.data).map((e) => SmtpAuditEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
