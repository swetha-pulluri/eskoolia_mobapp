import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../../administration/domain/entities/paginated_result.dart';
import '../../domain/entities/settings_audit_log_entity.dart';

class SettingsAuditLogRemoteDataSource {
  final DioClient _dioClient;

  SettingsAuditLogRemoteDataSource(this._dioClient);

  Future<PaginatedResult<SettingsAuditLogEntity>> getAuditLog({
    required int page,
    required int pageSize,
    String? module,
    String? action,
    String? actor,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.settingsAuditLog,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (module != null && module.isNotEmpty) 'module': module,
        if (action != null && action.isNotEmpty) 'action': action,
        if (actor != null && actor.isNotEmpty) 'actor': actor,
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
      },
    );
    return PaginatedResult.fromJson(response.data, SettingsAuditLogEntity.fromJson);
  }
}
