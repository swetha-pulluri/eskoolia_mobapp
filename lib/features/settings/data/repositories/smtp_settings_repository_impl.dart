import '../../domain/entities/smtp_config_entity.dart';
import '../../domain/repositories/smtp_settings_repository.dart';
import '../datasources/smtp_settings_remote_datasource.dart';

class SmtpSettingsRepositoryImpl implements SmtpSettingsRepository {
  final SmtpSettingsRemoteDataSource _remoteDataSource;

  SmtpSettingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SmtpConfigEntity>> getConfigs() => _remoteDataSource.getConfigs();

  @override
  Future<SmtpConfigEntity> createConfig(Map<String, dynamic> payload) => _remoteDataSource.createConfig(payload);

  @override
  Future<SmtpConfigEntity> updateConfig(int id, Map<String, dynamic> payload) =>
      _remoteDataSource.updateConfig(id, payload);

  @override
  Future<void> deleteConfig(int id) => _remoteDataSource.deleteConfig(id);

  @override
  Future<SmtpConfigEntity> activateConfig(int id) => _remoteDataSource.activateConfig(id);

  @override
  Future<void> testSend(Map<String, dynamic> payload) => _remoteDataSource.testSend(payload);

  @override
  Future<List<SmtpAuditEntry>> getAuditLog(int objectId) => _remoteDataSource.getAuditLog(objectId);
}
