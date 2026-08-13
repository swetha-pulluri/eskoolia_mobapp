import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administration/domain/entities/paginated_result.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/settings_audit_log_remote_datasource.dart';
import '../../data/repositories/settings_audit_log_repository_impl.dart';
import '../../domain/entities/settings_audit_log_entity.dart';
import '../../domain/repositories/settings_audit_log_repository.dart';

final settingsAuditLogRemoteDataSourceProvider = Provider<SettingsAuditLogRemoteDataSource>((ref) {
  return SettingsAuditLogRemoteDataSource(ref.watch(dioClientProvider));
});

final settingsAuditLogRepositoryProvider = Provider<SettingsAuditLogRepository>((ref) {
  return SettingsAuditLogRepositoryImpl(ref.watch(settingsAuditLogRemoteDataSourceProvider));
});

/// Web hardcodes `pageSize = 20` (`AuditLogPanel.tsx`) and never exposes a
/// page-size control — matched here exactly.
const kSettingsAuditPageSize = 20;
const Object _settingsAuditUnset = Object();

/// Filter + page state — mirrors the web's own local `useState`s
/// (`moduleFilter`, `actionFilter`, `actorFilter`, `dateFrom`, `dateTo`,
/// `page`). Deliberately separate from School Tenancy's own `AuditFilters`
/// (different filter set — no `search`/`severity`, has `module`).
class SettingsAuditFilters {
  final int page;
  final String? module;
  final String? action;
  final String? actor;
  final String? dateFrom;
  final String? dateTo;

  const SettingsAuditFilters({
    this.page = 1,
    this.module,
    this.action,
    this.actor,
    this.dateFrom,
    this.dateTo,
  });

  bool get hasActiveFilters =>
      module != null || action != null || actor != null || dateFrom != null || dateTo != null;

  SettingsAuditFilters copyWith({
    int? page,
    Object? module = _settingsAuditUnset,
    Object? action = _settingsAuditUnset,
    Object? actor = _settingsAuditUnset,
    Object? dateFrom = _settingsAuditUnset,
    Object? dateTo = _settingsAuditUnset,
  }) {
    return SettingsAuditFilters(
      page: page ?? this.page,
      module: module == _settingsAuditUnset ? this.module : module as String?,
      action: action == _settingsAuditUnset ? this.action : action as String?,
      actor: actor == _settingsAuditUnset ? this.actor : actor as String?,
      dateFrom: dateFrom == _settingsAuditUnset ? this.dateFrom : dateFrom as String?,
      dateTo: dateTo == _settingsAuditUnset ? this.dateTo : dateTo as String?,
    );
  }
}

final settingsAuditFiltersProvider = StateProvider.autoDispose<SettingsAuditFilters>(
  (ref) => const SettingsAuditFilters(),
);

/// Refetches whenever [settingsAuditFiltersProvider] changes — the page's
/// "Filter"/"Clear" buttons are the only things that write to that
/// provider (see `settings_audit_log_page.dart`), matching the web's own
/// button-triggered (not live-as-you-type) refetch.
final settingsAuditLogProvider =
    FutureProvider.autoDispose<PaginatedResult<SettingsAuditLogEntity>>((ref) {
  final filters = ref.watch(settingsAuditFiltersProvider);
  final repository = ref.watch(settingsAuditLogRepositoryProvider);
  return repository.getAuditLog(
    page: filters.page,
    pageSize: kSettingsAuditPageSize,
    module: filters.module,
    action: filters.action,
    actor: filters.actor,
    dateFrom: filters.dateFrom,
    dateTo: filters.dateTo,
  );
});
