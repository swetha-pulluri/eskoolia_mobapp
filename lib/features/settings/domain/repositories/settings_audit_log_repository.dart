import '../../../administration/domain/entities/paginated_result.dart';
import '../entities/settings_audit_log_entity.dart';

/// Reference: backend/apps/settings/views.py (SettingsAuditLogViewSet — a
/// plain `ReadOnlyModelViewSet`, school-scoped, `-created_at` ordering),
/// frontend/components/settings/AuditLogPanel.tsx.
abstract class SettingsAuditLogRepository {
  Future<PaginatedResult<SettingsAuditLogEntity>> getAuditLog({
    required int page,
    required int pageSize,
    String? module,
    String? action,
    String? actor,
    String? dateFrom,
    String? dateTo,
  });
}
