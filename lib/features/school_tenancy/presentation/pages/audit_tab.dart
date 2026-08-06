import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/action_badge_widget.dart';
import '../../domain/entities/audit_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Matches web's `normalizeSev` (`audit/page.tsx:19-23`).
String _normalizeSeverity(String s) {
  final v = s.toLowerCase();
  if (v == 'critical' || v == 'error' || v == 'failed') return 'error';
  if (v == 'warning' || v == 'partial') return 'warning';
  return 'info';
}

/// Matches web's real `ACTION_OPTIONS` exactly (`audit/page.tsx:138-153`).
const _kActionOptions = [
  'auth.login', 'auth.impersonate', 'school.provision', 'school.archive',
  'plan.upgrade', 'plan.downgrade', 'invoice.generated', 'invoice.overdue',
  'api_key.rotate', 'policy.updated', 'backup.complete',
  'migration.complete', 'migration.rollback',
];

/// Super Admin Audit Log Page — real server-side pagination + filters,
/// matching web's actual behavior (`audit/page.tsx`) exactly. Previously
/// fetched a flat batch of up to 200 events once and filtered/severity-
/// matched client-side over just that window, which silently missed
/// anything outside it (tapping "Critical" could show 0 results even with
/// real critical events further back) and showed a flat "Events (N)" list
/// with no real pages, unlike web's genuine `page`/`page_size=25` + total
/// count pagination.
class SuperAdminAuditPage extends ConsumerStatefulWidget {
  const SuperAdminAuditPage({super.key});

  @override
  ConsumerState<SuperAdminAuditPage> createState() => _SuperAdminAuditPageState();
}

class _SuperAdminAuditPageState extends ConsumerState<SuperAdminAuditPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showActionOptions = false;
  bool _exportBusy = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters({
    Object? search = _unset,
    Object? action = _unset,
    Object? severity = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    int? page,
  }) {
    final current = ref.read(auditFiltersProvider);
    ref.read(auditFiltersProvider.notifier).state = current.copyWith(
      // Matches web's own `useEffect(() => setPage(1), [actionFilter,
      // sevFilter, dateFrom, dateTo])` — any filter change resets to page 1;
      // only an explicit page-nav call carries a `page`.
      page: page ?? 1,
      search: search == _unset ? current.search : search as String?,
      action: action == _unset ? current.action : action as String?,
      severity: severity == _unset ? current.severity : severity as String?,
      dateFrom: dateFrom == _unset ? current.dateFrom : dateFrom as String?,
      dateTo: dateTo == _unset ? current.dateTo : dateTo as String?,
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    // Matches web's own 400ms debounce (`audit/page.tsx:181-184`).
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _applyFilters(search: value.trim().isEmpty ? null : value.trim());
    });
  }

  /// Real call to `GET /audit/export/` — mirrors web's `handleExport()`
  /// (`audit/page.tsx:229-245`): exports every row matching the CURRENT
  /// filters, not just whatever page is on screen.
  Future<void> _handleExportCsv(AuditFilters filters) async {
    setState(() => _exportBusy = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final bytes = await repository.exportAuditCsv(
        action: filters.action,
        severity: filters.severity,
        search: filters.search,
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
      );
      await saveBytesForDownload(
        bytes: Uint8List.fromList(bytes),
        filename: 'eskoolia-audit-${DateTime.now().toIso8601String().split('T').first}.csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audit log exported.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  String _relativeTime(String timestamp) {
    final diff = DateTime.now().difference(DateTime.parse(timestamp));
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom, required AuditFilters filters}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final iso = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (isFrom) {
      _applyFilters(dateFrom: iso);
    } else {
      _applyFilters(dateTo: iso);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(auditFiltersProvider);
    final auditAsync = ref.watch(auditEventsProvider);

    if (auditAsync.isLoading && !auditAsync.hasValue) {
      return const SchoolTenancyLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (auditAsync.hasError && !auditAsync.hasValue) {
      return SchoolTenancyLayout(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load audit log.\n${auditAsync.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageSubtitle,
            ),
          ),
        ),
      );
    }

    final page = auditAsync.value!;
    final events = page.results;
    final refreshing = auditAsync.isLoading;
    final totalPages = (page.count / kAuditPageSize).ceil().clamp(1, 999999);
    final pageStart = page.count == 0 ? 0 : (filters.page - 1) * kAuditPageSize + 1;
    final pageEnd = (filters.page * kAuditPageSize).clamp(0, page.count);

    // KPIs — matches web's `kpis` exactly (`audit/page.tsx:222-227`): Total
    // Events uses the real server-side `totalCount`, but Critical/Unique
    // actors/Last 24h are deliberately scoped to just the CURRENT PAGE's
    // events ("in loaded window" / "failed actions"), not the full filtered
    // result set — a real web quirk, not something to "fix" into a global
    // count here.
    final criticalCount = events.where((e) => _normalizeSeverity(e.severity) == 'error').length;
    final uniqueActors = events.map((e) => e.actor).toSet().length;
    final last24h = events
        .where((e) => DateTime.now().difference(DateTime.parse(e.timestamp)).inHours < 24)
        .length;

    return SchoolTenancyLayout(
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PAGE HEADER
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: [
                        Text('Audit', style: AppTextStyles.pageTitle),
                        Text('Log', style: AppTextStyles.pageTitleAccent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Immutable record of all platform-level actions',
                      style: AppTextStyles.pageSubtitle,
                    ),
                    const SizedBox(height: 16),
                    // `Wrap` (not a bare `Row`) — at narrow phone widths or
                    // larger text-scale settings, "Refresh" + "Exporting…"
                    // together could exceed the available row width with
                    // neither button able to shrink; matches the same
                    // header-button convention already used elsewhere in
                    // School Tenancy (Policies/Schools tabs).
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: refreshing ? null : () => ref.invalidate(auditEventsProvider),
                          icon: refreshing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 14),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: AppTextStyles.buttonSecondary,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _exportBusy ? null : () => _handleExportCsv(filters),
                          icon: _exportBusy
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download, size: 14),
                          label: Text(_exportBusy ? 'Exporting…' : 'Export CSV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: AppTextStyles.buttonSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // KPI CARDS — `KpiCardGrid` (width-constrained, height-
              // intrinsic tiles), not a fixed-`childAspectRatio` `GridView`,
              // which forces every tile to a height derived only from
              // width/aspect-ratio math regardless of actual text content —
              // a real, already-diagnosed-elsewhere `RenderFlex overflowed
              // on the bottom` at narrow widths / larger text-scale
              // settings (see `KpiCardGrid`'s own doc comment;
              // Dashboard/Schools tabs already use this fix).
              KpiCardGrid(
                spacing: 14,
                cards: [
                  KpiCard(
                    label: 'Total Events',
                    value: '${page.count}',
                    icon: Icons.show_chart,
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF5836E0),
                    trend: 'in loaded window',
                    trendColor: AppColors.textTertiary,
                    footnote: 'All events',
                  ),
                  KpiCard(
                    label: 'Critical / Error',
                    value: '$criticalCount',
                    icon: Icons.cancel_outlined,
                    sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                    sparklineColor: const Color(0xFFE0463A),
                    trend: 'failed actions',
                    trendColor: AppColors.dangerRed,
                    footnote: 'High severity',
                  ),
                  KpiCard(
                    label: 'Unique Actors',
                    value: '$uniqueActors',
                    icon: Icons.group_outlined,
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0369A1),
                    trend: 'distinct users',
                    trendColor: AppColors.infoBlue,
                    footnote: 'All actors',
                  ),
                  KpiCard(
                    label: 'Last 24 Hours',
                    value: '$last24h',
                    icon: Icons.access_time,
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0E9F6E),
                    trend: 'recent activity',
                    trendColor: AppColors.successGreen,
                    footnote: 'Today',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SEARCH BAR
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search actor, action, school, IP…',
                  hintStyle: AppTextStyles.sectionSubtitle,
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.bgPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // SEVERITY FILTER BUTTONS — now real server-side filters
              // (`severity=critical|warning|info`), matching web's SEV_OPTS
              // exactly (`audit/page.tsx:155-160`).
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterButton('All', null, filters.severity),
                  _buildFilterButton('Critical', 'critical', filters.severity),
                  _buildFilterButton('Warning', 'warning', filters.severity),
                  _buildFilterButton('Info', 'info', filters.severity),
                ],
              ),

              const SizedBox(height: 8),

              // ACTION FILTER TOGGLE — matches web's `Filter` icon + label
              // button (`audit/page.tsx:322-333`), previously missing
              // entirely from Flutter. `LayoutBuilder` drops the date-range
              // group to its own row below "Action" once the combined
              // content (action button + 2 date fields + a clear-dates
              // icon, all with real minimum widths that can't shrink to
              // zero) wouldn't fit a single row at narrow phone widths —
              // a plain `Row` here could genuinely overflow on a 320dp
              // screen once both dates are set (clear-dates icon appears).
              LayoutBuilder(builder: (context, constraints) {
                final actionButton = OutlinedButton.icon(
                  onPressed: () => setState(() => _showActionOptions = !_showActionOptions),
                  icon: const Icon(Icons.filter_list, size: 14),
                  label: Text(filters.action ?? 'Action', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: (_showActionOptions || filters.action != null) ? AppColors.purpleTint : AppColors.bgSecondary,
                    side: BorderSide(color: (_showActionOptions || filters.action != null) ? AppColors.purpleSoft : AppColors.borderPrimary),
                    foregroundColor: (_showActionOptions || filters.action != null) ? AppColors.purpleDeep : AppColors.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                );
                final dateRangeRow = Row(
                  children: [
                    Expanded(child: _dateField(context, 'From', filters.dateFrom, () => _pickDate(context, isFrom: true, filters: filters))),
                    const SizedBox(width: 6),
                    Expanded(child: _dateField(context, 'To', filters.dateTo, () => _pickDate(context, isFrom: false, filters: filters))),
                    if (filters.dateFrom != null || filters.dateTo != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: 'Clear dates',
                        onPressed: () => _applyFilters(dateFrom: null, dateTo: null),
                      ),
                  ],
                );
                if (constraints.maxWidth < 380) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [actionButton, const SizedBox(height: 8), dateRangeRow],
                  );
                }
                return Row(
                  children: [actionButton, const SizedBox(width: 8), Expanded(child: dateRangeRow)],
                );
              }),

              // Action filter option pills — matches web's expanded panel
              // (`audit/page.tsx:362-379`).
              if (_showActionOptions) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildActionPill('All actions', null, filters.action),
                    ..._kActionOptions.map((a) => _buildActionPill(a, a, filters.action)),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              Text(
                auditAsync.isLoading
                    ? 'Loading…'
                    : page.count > 0
                        ? '$pageStart–$pageEnd of ${page.count} events'
                        : '0 events',
                style: AppTextStyles.sectionSubtitle,
              ),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border.all(color: AppColors.borderPrimary),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: events.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.shield_outlined, size: 28, color: AppColors.textTertiary),
                              const SizedBox(height: 10),
                              Text('No events match the current filter', style: AppTextStyles.boardLabel.copyWith(fontSize: 13)),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(auditFiltersProvider.notifier).state = const AuditFilters();
                                },
                                child: const Text('Clear all filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderPrimary),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return InkWell(
                      onTap: () => _showEventDetail(context, event),
                      child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action badge and timestamp
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: ActionBadge(
                                  action: event.action,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _relativeTime(event.timestamp),
                                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Detail
                          Text(
                            event.detail,
                            style: AppTextStyles.boardLabel.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 8),

                          // Actor and severity
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.actor,
                                  style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace'),
                                ),
                              ),
                              SeverityBadge(severity: event.severity),
                            ],
                          ),

                          // IP Address — matches web's "IP Address" column
                          // (`audit/page.tsx:352`).
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.lan_outlined, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.actorIp.isEmpty ? '—' : event.actorIp,
                                  style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          if (event.schoolName != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.business_outlined, size: 14, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                // A real school name can be long — without
                                // `Expanded`+ellipsis this row could overflow
                                // horizontally on a 320dp screen.
                                Expanded(
                                  child: Text(
                                    event.schoolName!,
                                    style: AppTextStyles.sectionSubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      ),
                    );
                  },
                ),
              ),

              // PAGINATION — real page navigation matching web's real
              // paginated table (`audit/page.tsx:446-494`), replacing the
              // old flat "Events (N)" list that just dumped everything from
              // one 200-row fetch. Simplified to Prev/Next + first/last
              // jump for mobile width rather than web's 7-pill page
              // navigator, which doesn't fit a phone screen.
              if (!auditAsync.isLoading && totalPages > 1) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // `Expanded`+ellipsis — with neither side of a
                    // `spaceBetween` Row able to shrink the other, a 3-digit
                    // page count ("Page 100 of 328") combined with the 4
                    // fixed-size nav buttons could overflow on a 320dp
                    // screen without this.
                    Expanded(
                      child: Text(
                        'Page ${filters.page} of $totalPages',
                        style: AppTextStyles.sectionSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        _pageNavButton(Icons.first_page, filters.page > 1 ? () => _applyFilters(page: 1) : null),
                        _pageNavButton(Icons.chevron_left, filters.page > 1 ? () => _applyFilters(page: filters.page - 1) : null),
                        _pageNavButton(Icons.chevron_right, filters.page < totalPages ? () => _applyFilters(page: filters.page + 1) : null),
                        _pageNavButton(Icons.last_page, filters.page < totalPages ? () => _applyFilters(page: totalPages) : null),
                      ],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _pageNavButton(IconData icon, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.bgSecondary,
        side: const BorderSide(color: AppColors.borderPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _dateField(BuildContext context, String label, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value ?? label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, color: value == null ? AppColors.textTertiary : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile bottom-sheet equivalent of web's Event Detail side panel
  /// (`audit/page.tsx:412-508`) — same content (badges, timestamp, actor,
  /// school, detail, status, error, changed-fields diff), adapted from a
  /// desktop side panel to a bottom sheet for mobile.
  void _showEventDetail(BuildContext context, AuditEventEntity event) {
    final timestamp = DateTime.parse(event.timestamp);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EVENT DETAIL', style: AppTextStyles.sectionSubtitle.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                          Text('#${event.id}', style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 11)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      SeverityBadge(severity: event.severity),
                      ActionBadge(action: event.action, color: AppColors.primaryPurple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailBlock('Timestamp', '${_relativeTime(event.timestamp)}\n${timestamp.toLocal()}'),
                  _detailBlock('Actor', event.actorIp.isEmpty ? event.actor : '${event.actor}\n${event.actorIp}'),
                  if (event.schoolName != null)
                    _detailBlock('School', event.tenantId != null ? '${event.schoolName}\n${event.tenantId}' : event.schoolName!),
                  _detailBlock('Detail', event.detail),
                  const SizedBox(height: 4),
                  Text('STATUS', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(event.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _statusColor(event.status).withValues(alpha: 0.3)),
                    ),
                    child: Text(event.status, style: AppTextStyles.chipLabel(color: _statusColor(event.status))),
                  ),
                  if (event.errorMessage != null && event.errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.redSoft,
                        border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ERROR', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.dangerRed)),
                          const SizedBox(height: 4),
                          Text(event.errorMessage!, style: AppTextStyles.boardLabel.copyWith(fontSize: 12, color: AppColors.dangerRed)),
                        ],
                      ),
                    ),
                  ],
                  if (event.affectedFields != null && event.affectedFields!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('CHANGED FIELDS', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    ...event.affectedFields!.map((field) {
                      final before = event.beforeValues?[field];
                      final after = event.afterValues?[field];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          border: Border.all(color: AppColors.borderPrimary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field, style: AppTextStyles.boardLabel.copyWith(fontFamily: 'monospace', fontSize: 12)),
                            if (before != null)
                              Text('$before', style: const TextStyle(color: AppColors.dangerRed, decoration: TextDecoration.lineThrough, fontSize: 12)),
                            if (after != null)
                              Text('$after', style: const TextStyle(color: AppColors.successGreen, fontSize: 12)),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailBlock(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.boardLabel.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return AppColors.successGreen;
      case 'partial':
        return AppColors.warningAmber;
      default:
        return AppColors.dangerRed;
    }
  }

  Widget _buildFilterButton(String label, String? value, String? current) {
    final isSelected = current == value;
    return OutlinedButton(
      onPressed: () => _applyFilters(severity: value),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.purpleTint : AppColors.bgSecondary,
        side: BorderSide(
          color: isSelected ? AppColors.purpleSoft : AppColors.borderPrimary,
        ),
        foregroundColor: isSelected ? AppColors.purpleDeep : AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }

  Widget _buildActionPill(String label, String? value, String? current) {
    final isSelected = current == value;
    return OutlinedButton(
      onPressed: () {
        setState(() => _showActionOptions = false);
        _applyFilters(action: value);
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.purpleTint : AppColors.bgSecondary,
        side: BorderSide(color: isSelected ? AppColors.purpleSoft : AppColors.borderPrimary),
        foregroundColor: isSelected ? AppColors.purpleDeep : AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

const Object _unset = Object();
