import '../entities/smtp_config_entity.dart';

/// Settings → SMTP Settings — backed by `/api/v1/settings/smtp/`
/// (backend/apps/settings/views.py::SchoolSMTPSettingsViewSet).
abstract class SmtpSettingsRepository {
  Future<List<SmtpConfigEntity>> getConfigs();

  Future<SmtpConfigEntity> createConfig(Map<String, dynamic> payload);

  Future<SmtpConfigEntity> updateConfig(int id, Map<String, dynamic> payload);

  Future<void> deleteConfig(int id);

  Future<SmtpConfigEntity> activateConfig(int id);

  /// Sends via the raw draft payload — no saved config required server-side.
  Future<void> testSend(Map<String, dynamic> payload);

  Future<List<SmtpAuditEntry>> getAuditLog(int objectId);
}
