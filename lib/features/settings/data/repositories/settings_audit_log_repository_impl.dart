import '../../../administration/domain/entities/paginated_result.dart';
import '../../domain/entities/settings_audit_log_entity.dart';
import '../../domain/repositories/settings_audit_log_repository.dart';
import '../datasources/settings_audit_log_remote_datasource.dart';

class SettingsAuditLogRepositoryImpl implements SettingsAuditLogRepository {
  final SettingsAuditLogRemoteDataSource _dataSource;

  SettingsAuditLogRepositoryImpl(this._dataSource);

  @override
  Future<PaginatedResult<SettingsAuditLogEntity>> getAuditLog({
    required int page,
    required int pageSize,
    String? module,
    String? action,
    String? actor,
    String? dateFrom,
    String? dateTo,
  }) {
    return _dataSource.getAuditLog(
      page: page,
      pageSize: pageSize,
      module: module,
      action: action,
      actor: actor,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
