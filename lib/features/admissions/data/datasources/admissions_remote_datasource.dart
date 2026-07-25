import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../administration/domain/entities/paginated_result.dart';
import '../../../administration/domain/entities/admin_setup_entity.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/entities/school_class_entity.dart';
import '../../domain/entities/analytics_data_entity.dart';

/// Admissions Remote Data Source — Command Center + Analytics.
/// Calls the real backend endpoints under `apps/admissions` (the
/// inquiry/funnel feature, confirmed distinct from the office-
/// administration models sharing the same Django app) and `apps/core`
/// (classes/sections), matching `AdmissionsCommandCenter.tsx`/
/// `AdmissionsAnalytics.tsx` on the `main` branch — the branch actually
/// served by the running frontend dev server.
class AdmissionsRemoteDataSource {
  final DioClient _dioClient;

  AdmissionsRemoteDataSource(this._dioClient);

  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final data = map['data'];
    if (data is Map<String, dynamic>) return data;
    return map;
  }

  /// Loops `page=1,2,3,...` collecting every row, since
  /// `ApiPageNumberPagination.max_page_size = 100` hard-caps a single
  /// request regardless of the requested `page_size`.
  ///
  /// This exists specifically for superuser accounts: several `get_queryset()`s
  /// (`ClassViewSet`, `AdmissionInquiryViewSet`, `AdminSetupEntryViewSet`)
  /// skip the `school_id` filter entirely when `is_superuser`, merging every
  /// school's rows together sorted globally — so the target school's own
  /// records can be scattered past the first 100-row page (confirmed
  /// directly: filtering just the first page for one school's classes
  /// recovered only 10 of its real 15, the rest pushed past the cutoff by
  /// other schools' rows). For an already-scoped (non-superuser) account
  /// this resolves in a single request as before — `count` is never above
  /// `pageSize` there. Capped at [maxPages] as a safety valve.
  Future<List<T>> _fetchAllPages<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic> baseParams = const {},
    int pageSize = 100,
    int maxPages = 20,
  }) async {
    final all = <T>[];
    var page = 1;
    while (page <= maxPages) {
      final response = await _dioClient.get(path, queryParameters: {...baseParams, 'page': page, 'page_size': pageSize});
      final result = PaginatedResult.fromJson(response.data, fromJson);
      all.addAll(result.results);
      if (all.length >= result.count || result.results.isEmpty) break;
      page++;
    }
    return all;
  }

  // ─── Inquiries ──────────────────────────────────────────────────────────
  /// The real Command Center fetches `?page_size=200` with no other filter
  /// params (all search/filter/sort/pagination is client-side over that
  /// set) — but `ApiPageNumberPagination.max_page_size = 100` clamps any
  /// single request above 100 back down to 100 server-side, so web's own
  /// `200` request already only ever returns the first 100 rows (by
  /// `-created_at`) for a normal, school-scoped account. Loops pages so a
  /// superuser account's target school isn't starved by other schools'
  /// interleaved rows (see [_fetchAllPages]).
  Future<PaginatedResult<InquiryEntity>> getInquiries({int pageSize = 100}) async {
    try {
      final all = await _fetchAllPages('/api/v1/admissions/inquiries/', InquiryEntity.fromJson, pageSize: pageSize);
      return PaginatedResult(results: all, count: all.length);
    } catch (e) {
      AppLogger.error('Get inquiries error', e);
      rethrow;
    }
  }

  Future<InquiryEntity> createInquiry(Map<String, dynamic> body) async {
    final response = await _dioClient.post('/api/v1/admissions/inquiries/', data: body);
    return InquiryEntity.fromJson(_unwrap(response.data));
  }

  Future<InquiryEntity> updateInquiry(int id, Map<String, dynamic> body) async {
    final response = await _dioClient.patch('/api/v1/admissions/inquiries/$id/', data: body);
    return InquiryEntity.fromJson(_unwrap(response.data));
  }

  Future<void> deleteInquiry(int id) async {
    await _dioClient.delete('/api/v1/admissions/inquiries/$id/');
  }

  /// `POST /inquiries/{id}/merge/` — matches `ApplicationDetailPanel.tsx`'s
  /// merge action. Note: this custom `@action` has no `permission_codes`
  /// entry on the backend (`AdmissionInquiryViewSet`), so
  /// `AdminSectionRBACMixin.initial()` raises `PermissionDenied` before
  /// even checking `is_superuser` — it 403s for every account today,
  /// identically to the real web app. Wired faithfully regardless, since
  /// that's a backend defect out of scope for this app, not a reason to
  /// hide the button.
  Future<InquiryEntity> mergeInquiry(int id, int sourceId) async {
    final response = await _dioClient.post('/api/v1/admissions/inquiries/$id/merge/', data: {'source_id': sourceId});
    return InquiryEntity.fromJson(_unwrap(response.data));
  }

  // ─── Classes / Sections (apps.core) ────────────────────────────────────
  /// The real Command Center fetches `/api/v1/core/classes/` with no
  /// `page_size` at all, so it silently gets only the server's default
  /// page (`ApiPageNumberPagination.page_size = 10`) — truncating a school
  /// with the standard Nursery/LKG/UKG + Grade 1-12 set (15 classes) down
  /// to 10, dropping Grade 8-12 entirely. That would make the Class
  /// Portfolio Grid (this screen's actual purpose) silently useless for
  /// most schools, so this deliberately requests the server's own max
  /// page size instead — a disclosed improvement over web's own
  /// pagination-starvation bug, same pattern already applied elsewhere in
  /// this app (Complaint Type/Source, ID Card recipients).
  Future<PaginatedResult<SchoolClassEntity>> getClasses({int pageSize = 100}) async {
    try {
      final all = await _fetchAllPages('/api/v1/core/classes/', SchoolClassEntity.fromJson, pageSize: pageSize);
      return PaginatedResult(results: all, count: all.length);
    } catch (e) {
      AppLogger.error('Get classes error', e);
      rethrow;
    }
  }

  /// `PATCH /api/v1/core/sections/{id}/` — matches
  /// `ClassPortfolioGrid.tsx`'s `EditSeatsModal` per-section capacity save.
  Future<void> updateSectionCapacity(int sectionId, int capacity) async {
    await _dioClient.patch('/api/v1/core/sections/$sectionId/', data: {'capacity': capacity});
  }

  // ─── Sources / References (Admin Setup type 3 / 4) ─────────────────────
  /// Matches `AdmissionsCommandCenter.tsx`'s own
  /// `/api/v1/admissions/admin-setups/?type=3&page=1&page_size=50` (source)
  /// and `?type=4&...` (reference) calls exactly — same endpoint
  /// Administration's Admin Setup screen uses, called directly here rather
  /// than cross-wiring into that feature's repository instance.
  Future<List<AdminSetupEntity>> getAdminSetupOptions(String type) async {
    try {
      return await _fetchAllPages(
        '/api/v1/admissions/admin-setups/',
        AdminSetupEntity.fromJson,
        baseParams: {'type': type},
        pageSize: 50,
      );
    } catch (e) {
      AppLogger.error('Get admin setup options error', e);
      rethrow;
    }
  }

  // ─── Analytics ──────────────────────────────────────────────────────────
  Future<AnalyticsDataEntity> getAnalyticsOverview({String period = 'all'}) async {
    try {
      final response = await _dioClient.get('/api/v1/admissions/analytics/overview/', queryParameters: {'period': period});
      final map = response.data as Map<String, dynamic>;
      return AnalyticsDataEntity.fromJson(map['data'] as Map<String, dynamic>? ?? const {});
    } catch (e) {
      AppLogger.error('Get analytics overview error', e);
      rethrow;
    }
  }

  // ─── AI Compose / contact actions ──────────────────────────────────────
  /// `POST /inquiries/ai/generate/` — matches `AIMessageComposer.tsx`'s
  /// Generate button. Note: this currently 500s on every call — the view
  /// calls `AIMessageService.generate(inquiry=..., template=..., tone_preferences=...)`
  /// but that method only accepts `system_prompt`/`user_prompt` kwargs
  /// (`apps/admissions/providers.py`), a real backend defect. Wired
  /// faithfully; the caller shows the real error text either way.
  Future<Map<String, dynamic>> generateAiMessage(int leadId) async {
    final response = await _dioClient.post('/api/v1/admissions/ai/generate/', data: {'lead_id': leadId});
    return response.data as Map<String, dynamic>;
  }

  /// `POST /inquiries/{id}/actions/{channel}/` — matches
  /// `AIMessageComposer.tsx`'s Send button. Same backend defect class as
  /// `merge()`: these custom actions have no `permission_codes` entry, so
  /// they 403 for every account today (a backend defect, not fixable
  /// here) — wired faithfully regardless.
  Future<void> sendInquiryAction(int id, String channel, Map<String, dynamic> body) async {
    await _dioClient.post('/api/v1/admissions/inquiries/$id/actions/$channel/', data: body);
  }
}
