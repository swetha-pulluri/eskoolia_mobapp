import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../widgets/compact_kpi_card.dart';
import '../../../../core/widgets/filter_pill_widget.dart';
import '../../domain/entities/school_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';
import 'add_school_page.dart';

/// Super Admin Schools Page
/// Exact conversion of web frontend schools structure
class SuperAdminSchoolsPage extends ConsumerStatefulWidget {
  /// Matches web's `?add=1` query param (`schools/page.tsx`) — when true,
  /// the "Add a new school" accordion auto-opens and scrolls into view on
  /// arrival, instead of requiring a second manual tap on this page's own
  /// "Add school" button. Set by the Dashboard's "Add school" button.
  final bool autoOpenAdd;

  const SuperAdminSchoolsPage({super.key, this.autoOpenAdd = false});

  @override
  ConsumerState<SuperAdminSchoolsPage> createState() =>
      _SuperAdminSchoolsPageState();
}

/// Plan/Board option lists match the web frontend's own `<select>` options
/// exactly (`schools/page.tsx`'s Smart Filters accordion).
const _kPlanOptions = ['trial', 'starter', 'standard', 'premium', 'enterprise'];
const _kBoardOptions = ['CBSE', 'ICSE', 'SSC_TG', 'SSC_AP', 'OTHER'];

/// Full real state/UT list — verbatim from the backend's own
/// `SchoolFormChoicesView._STATES` (`apps/super_admin/views.py`), same
/// source web's own Smart Filters "State" select draws `states` from.
const _kStateOptions = {
  '35': 'Andaman and Nicobar Islands',
  '37': 'Andhra Pradesh',
  '12': 'Arunachal Pradesh',
  '18': 'Assam',
  '10': 'Bihar',
  '04': 'Chandigarh',
  '22': 'Chhattisgarh',
  '26': 'Dadra and Nagar Haveli and Daman and Diu',
  '07': 'Delhi',
  '30': 'Goa',
  '24': 'Gujarat',
  '06': 'Haryana',
  '02': 'Himachal Pradesh',
  '01': 'Jammu and Kashmir',
  '20': 'Jharkhand',
  '29': 'Karnataka',
  '32': 'Kerala',
  '38': 'Ladakh',
  '31': 'Lakshadweep',
  '23': 'Madhya Pradesh',
  '27': 'Maharashtra',
  '14': 'Manipur',
  '17': 'Meghalaya',
  '15': 'Mizoram',
  '13': 'Nagaland',
  '21': 'Odisha',
  '34': 'Puducherry',
  '03': 'Punjab',
  '08': 'Rajasthan',
  '11': 'Sikkim',
  '33': 'Tamil Nadu',
  '36': 'Telangana',
  '16': 'Tripura',
  '09': 'Uttar Pradesh',
  '05': 'Uttarakhand',
  '19': 'West Bengal',
};

/// Matches web's real "Region" filter options (`schools/page.tsx`) — the
/// backend's `region` filter is real and working (`views.py:572-575`), the
/// web frontend just never wired its own select to it.
const _kRegionOptions = {
  'ap-south-1': 'ap-south-1 Mumbai',
  'ap-south-2': 'ap-south-2 Hyderabad',
};

/// Sentinel used to distinguish "argument not passed" from "argument
/// explicitly passed as null" in [_SuperAdminSchoolsPageState._applyFilters].
const Object _unset = Object();

class _SuperAdminSchoolsPageState extends ConsumerState<SuperAdminSchoolsPage> {
  final TextEditingController _searchController = TextEditingController();

  /// "Schools list" accordion (03) — matches web's `accListOpen`, which
  /// defaults to open (`schools/page.tsx`), unlike "Add school" (01).
  bool _schoolsListOpen = true;

  // "Add a new school" accordion — matches web's `accAddOpen` (defaults to
  // closed, `schools/page.tsx:437`), embedded inline above "Smart filters"
  // rather than as a separate screen (web never navigates anywhere for this;
  // it just expands Accordion "01" in place on the same Schools page).
  bool _addSchoolOpen = false;
  final GlobalKey _addSchoolKey = GlobalKey();

  /// "Smart filters" accordion (02) — matches web's `accFiltersOpen`, which
  /// also defaults to closed (`schools/page.tsx`).
  bool _smartFiltersOpen = false;

  /// Matches web's own `activeFilterCount` formula exactly
  /// (`schools/page.tsx`): search/plan/board/state count, plus status only
  /// when it's neither the default `'all'` nor `'active'` — region and
  /// health-flag aren't counted on web either.
  int _activeFilterCount(SchoolFilters filters) {
    return [
      filters.search,
      filters.plan,
      filters.board,
      filters.state,
      (filters.status != null &&
              filters.status != 'all' &&
              filters.status != 'active')
          ? filters.status
          : null,
    ].where((v) => v != null && v.isNotEmpty).length;
  }

  // Set alongside `_addSchoolOpen` and cleared only once the scroll-into-view
  // actually succeeds — see `_scheduleScrollToAddSchool`'s doc comment for
  // why a single one-shot attempt from `_openAddSchool()` alone isn't enough.
  bool _pendingScrollToAdd = false;

  void _openAddSchool() {
    setState(() {
      _addSchoolOpen = true;
      _pendingScrollToAdd = true;
    });
    _scheduleScrollToAddSchool();
  }

  /// Attempts to scroll the "Add a new school" accordion into view, retrying
  /// on a later frame if it can't yet. `_addSchoolKey`'s `Container` only
  /// exists once `build()` has rendered the real page body — but when
  /// arriving via the Dashboard's "Add school" button (`?add=1`), the very
  /// first frame after `initState` almost always still has `schoolsProvider`
  /// loading, so `build()` is showing its `CircularProgressIndicator()`
  /// branch instead, and `_addSchoolKey.currentContext` is null. The old
  /// single-attempt version silently gave up right there: `_addSchoolOpen`
  /// stayed `true` (so the accordion *did* end up expanded once real data
  /// loaded), but nothing ever scrolled to it — landing on the Schools page
  /// with the already-open form sitting off-screen below the KPI cards read
  /// exactly like "navigating to Schools but not to the Add School data."
  /// `build()` calls this again itself once the real body actually renders
  /// (see the `_pendingScrollToAdd` check there), so this keeps retrying
  /// across rebuilds until the key attaches and the scroll can succeed.
  void _scheduleScrollToAddSchool() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pendingScrollToAdd) return;
      final context = _addSchoolKey.currentContext;
      if (context == null) return;
      _pendingScrollToAdd = false;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _closeAddSchool() => setState(() => _addSchoolOpen = false);

  bool _exportBusy = false;

  /// Exports schools matching the current filters as an .xlsx file —
  /// mirrors web's `handleExportSchoolsXlsx()`, which hits the same real
  /// `GET /schools/export-xlsx/` endpoint with the same filter params.
  Future<void> _handleExportSchools(SchoolFilters filters) async {
    setState(() => _exportBusy = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final bytes = await repository.exportSchoolsXlsx(
        search: filters.search,
        status: filters.status,
        board: filters.board,
        plan: filters.plan,
        region: filters.region,
        state: filters.state,
        healthFlag: filters.healthFlag,
      );
      await saveBytesForDownload(
        bytes: bytes,
        filename:
            'eskoolia-schools-${DateTime.now().toIso8601String().split('T').first}.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Schools exported.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Web navigates here via a hard `window.location.href` reload
    // (`dashboard/page.tsx:224`), so every visit starts from fresh default
    // filters. Flutter's `context.go` doesn't reload the process, so
    // `schoolsFiltersProvider` (a plain, non-autoDispose StateProvider)
    // would otherwise keep whatever filter combination was left over from
    // a previous visit — including one that happens to match zero schools —
    // and silently show "No schools found" instead of the real list. Reset
    // on every mount to match web's actual behavior.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(schoolsFiltersProvider.notifier).state = const SchoolFilters(
        status: 'active',
      );
      // Matches web's `useEffect` that checks `searchParams.get('add') === '1'`
      // on mount (`schools/page.tsx`) — auto-open + scroll to the "Add a new
      // school" accordion when arriving from the Dashboard's "Add school"
      // button, instead of landing on the plain list.
      if (widget.autoOpenAdd) _openAddSchool();
    });
  }

  @override
  void didUpdateWidget(covariant SuperAdminSchoolsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If GoRouter/Flutter reuses this page's existing State instead of
    // mounting a fresh one (e.g. this page was already visited earlier in
    // the session), `initState()` above never re-runs — so a later visit
    // via the Dashboard's "Add school" button rebuilds this widget with
    // `autoOpenAdd` flipping false→true, but the accordion never opened.
    // React to that transition directly instead of relying on `initState`
    // alone.
    if (widget.autoOpenAdd && !oldWidget.autoOpenAdd) {
      _openAddSchool();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(
    SchoolFilters current, {
    String? search,
    Object? status = _unset,
    Object? board = _unset,
    Object? plan = _unset,
    Object? state = _unset,
    Object? region = _unset,
    Object? healthFlag = _unset,
  }) {
    ref.read(schoolsFiltersProvider.notifier).state = SchoolFilters(
      page: 1,
      pageSize: current.pageSize,
      search: search ?? current.search,
      status: status == _unset ? current.status : status as String?,
      board: board == _unset ? current.board : board as String?,
      plan: plan == _unset ? current.plan : plan as String?,
      state: state == _unset ? current.state : state as String?,
      region: region == _unset ? current.region : region as String?,
      healthFlag: healthFlag == _unset
          ? current.healthFlag
          : healthFlag as String?,
    );
  }

  Future<void> _refreshAfterMutation() async {
    ref.invalidate(schoolsProvider);
    ref.invalidate(schoolsGlobalStatsProvider);
  }

  List<Color> _getAvatarGradient(String tenantId) {
    return AppColors.getAvatarGradient(tenantId);
  }

  String _getSchoolInitials(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length < 2 ? name.length : 2).toUpperCase();
  }

  /// Matches the web frontend's `?? '—'` fallback (see `boardLabel`/the
  /// state cell in `schools/page.tsx`) — the backend can return `null` or
  /// an empty string for optional tenant fields like `board`/`state`.
  String _orDash(String? value) =>
      (value == null || value.isEmpty) ? '—' : value;

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsProvider);
    final globalStatsAsync = ref.watch(schoolsGlobalStatsProvider);
    final filters = ref.watch(schoolsFiltersProvider);

    if (schoolsAsync.isLoading && !schoolsAsync.hasValue) {
      return const SchoolTenancyLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (schoolsAsync.hasError && !schoolsAsync.hasValue) {
      return SchoolTenancyLayout(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load schools.\n${schoolsAsync.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageSubtitle,
            ),
          ),
        ),
      );
    }

    // The real page body (containing `_addSchoolKey`) is only ever built
    // from this point on — retry the pending scroll-into-view now that it
    // actually has something to scroll to (see `_scheduleScrollToAddSchool`'s
    // doc comment for why the first attempt, right after `initState`, was
    // too early whenever `schoolsProvider` was still loading).
    if (_pendingScrollToAdd) {
      _scheduleScrollToAddSchool();
    }

    final schools = schoolsAsync.value!;
    final globalStats = globalStatsAsync.value;
    final healthFlagCounts = schools.healthFlagsCounts;

    // Page-level stats (over the current filtered/paginated batch only) —
    // mirrors web's `totalStudents`/`totalActiveStudents`/`totalStaff`
    // computed from `rows`, not from global stats.
    final totalStudents = schools.results.fold<int>(
      0,
      (sum, s) => sum + s.students,
    );
    final totalActiveStudents = schools.results.fold<int>(
      0,
      (sum, s) => sum + s.activeStudents,
    );
    final totalStaff = schools.results.fold<int>(0, (sum, s) => sum + s.staff);

    // Fallback local counts (used only until schoolsGlobalStatsProvider
    // resolves) — mirrors web's `globalStats.X || localCount` pattern.
    final activeCountFallback = schools.results
        .where((s) => !['archived', 'suspended'].contains(s.status))
        .length;
    final trialCountFallback = schools.results
        .where(
          (s) =>
              s.plan == 'trial' &&
              !['archived', 'suspended'].contains(s.status),
        )
        .length;
    final attnCountFallback = schools.results
        .where((s) => s.status == 'suspended')
        .length;
    final archivedCountFallback = schools.results
        .where((s) => s.status == 'archived')
        .length;

    final totalCount = globalStats?.total ?? schools.count;
    final activeCount = (globalStats != null && globalStats.active > 0)
        ? globalStats.active
        : activeCountFallback;
    final trialCount = (globalStats != null && globalStats.trial > 0)
        ? globalStats.trial
        : trialCountFallback;
    final attnCount = (globalStats != null && globalStats.attention > 0)
        ? globalStats.attention
        : attnCountFallback;
    final archivedCount = (globalStats != null && globalStats.archived > 0)
        ? globalStats.archived
        : archivedCountFallback;

    return SchoolTenancyLayout(
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          // Pull-to-refresh + `AlwaysScrollableScrollPhysics` — matches
          // Admin Home's own scroll behavior exactly.
          child: RefreshIndicator(
            onRefresh: _refreshAfterMutation,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PAGE HEADER — its own card, same white/bordered style as
                  // every accordion/section below it, instead of floating text
                  // directly on the page background.
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      border: Border.all(color: AppColors.borderPrimary),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title row
                        Wrap(
                          spacing: 6,
                          children: [
                            Text('School', style: AppTextStyles.pageTitle),
                            Text(
                              'Management',
                              style: AppTextStyles.pageTitleAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text.rich(
                          TextSpan(
                            style: AppTextStyles.pageSubtitle,
                            children: const [
                              TextSpan(
                                text:
                                    'Provision, monitor & manage every school tenant. · Each school has its own ',
                              ),
                              TextSpan(
                                text: 'tenant ID',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ', GSTIN, dedicated DB shard & zero cross-tenant visibility.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action buttons
                        // `Wrap` (not a bare `Row`) — on a narrow real device
                        // (small phone width and/or a larger system font-scale
                        // setting), a `Row` with neither button flexing has
                        // nowhere to give: the "Add school" label can end up
                        // squeezed into an effectively zero-width box, which
                        // forces Flutter's text layout to wrap after every
                        // single letter instead of overflowing normally. `Wrap`
                        // gives each button its own natural width and moves the
                        // overflow button to a new line instead.
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _exportBusy
                                  ? null
                                  : () => _handleExportSchools(filters),
                              icon: _exportBusy
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.download, size: 14),
                              label: Text(
                                _exportBusy ? 'Exporting…' : 'Export',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(
                                  color: AppColors.borderPrimary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                textStyle: AppTextStyles.buttonSecondary,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _openAddSchool(),
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Add school'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                textStyle: AppTextStyles.buttonPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // KPI CARDS
                  CompactKpiCardGrid(
                    spacing: 14,
                    cards: [
                      CompactKpiCard(
                        label: 'Total Schools',
                        value: '$totalCount',
                        sparklineData: const [
                          4,
                          7,
                          5,
                          9,
                          6,
                          11,
                          8,
                          10,
                          9,
                          13,
                          10,
                          12,
                          11,
                          14,
                        ],
                        sparklineColor: const Color(0xFF5836E0),
                        // Web hardcodes this exact trend/footnote copy on the
                        // Schools page too (`schools/page.tsx:800-801`) — not a
                        // Flutter-side fabrication.
                        trend: '+3 QoQ',
                        trendColor: AppColors.successGreen,
                        footnote: 'Telangana & Andhra Pradesh',
                      ),
                      CompactKpiCard(
                        label: 'Active Tenants',
                        value: '$activeCount',
                        sparklineData: const [
                          4,
                          7,
                          5,
                          9,
                          6,
                          11,
                          8,
                          10,
                          9,
                          13,
                          10,
                          12,
                          11,
                          14,
                        ],
                        sparklineColor: const Color(0xFF0E9F6E),
                        trend: 'Healthy',
                        trendColor: AppColors.successGreen,
                        footnote:
                            '$totalStudents enrolled · $totalActiveStudents active',
                      ),
                      CompactKpiCard(
                        label: 'On Trial',
                        value: '$trialCount',
                        sparklineData: const [
                          4,
                          7,
                          5,
                          9,
                          6,
                          11,
                          8,
                          10,
                          9,
                          13,
                          10,
                          12,
                          11,
                          14,
                        ],
                        sparklineColor: const Color(0xFFA65D08),
                        // Web hardcodes "Avg conv 68%" too (`schools/page.tsx:806`).
                        trend: 'Avg conv 68%',
                        trendColor: AppColors.warningAmber,
                        footnote: 'Trial-to-paid conversion',
                      ),
                      CompactKpiCard(
                        label: 'Needs Attention',
                        value: '$attnCount',
                        sparklineData: const [
                          14,
                          11,
                          13,
                          9,
                          12,
                          8,
                          10,
                          7,
                          9,
                          6,
                          8,
                          5,
                          7,
                          4,
                        ],
                        sparklineColor: const Color(0xFFE0463A),
                        trend: attnCount > 0
                            ? '$attnCount suspended'
                            : 'All clear',
                        trendColor: attnCount > 0
                            ? AppColors.dangerRed
                            : AppColors.textTertiary,
                        footnote: 'Open across tenants',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ACCORDION 01 — ADD A NEW SCHOOL / EDIT SCHOOL — embedded
                  // inline above Smart filters, matching web's real layout
                  // exactly (`schools/page.tsx` Accordion "01", collapsed by
                  // default — `accAddOpen` starts `false`). This used to be a
                  // separate pushed page, which didn't match web: web never
                  // navigates anywhere for "Add school"/"Edit" — it just expands
                  // this section in place on the same Schools page.
                  Container(
                    key: _addSchoolKey,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      border: Border.all(
                        color: _addSchoolOpen
                            ? AppColors.primaryPurple
                            : AppColors.borderPrimary,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            if (_addSchoolOpen) {
                              _closeAddSchool();
                            } else {
                              _openAddSchool();
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add a new school',
                                        style: AppTextStyles.accordionTitle,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Provisions a new isolated tenant · 9 sections · Identity, branding, contacts, GST, plan & data residency',
                                        style: AppTextStyles.accordionSubtitle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // `Flexible`+ellipsis — this chip's fixed-size
                                // `Text` combined with the icon badge and
                                // chevron genuinely overflowed this Row by
                                // 144px on a 320dp screen (confirmed via a
                                // widget test); it now shrinks instead.
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.purpleTint,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Auto-generates tenant ID',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.chipLabel(
                                        color: AppColors.purpleDeep,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _addSchoolOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_addSchoolOpen)
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.borderPrimary),
                              ),
                            ),
                            child: AddSchoolForm(
                              onCancel: _closeAddSchool,
                              onSaved: _closeAddSchool,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // SMART FILTERS — matches web's real behavior
                  // (`schools/page.tsx`'s Smart Filters accordion): Search,
                  // Plan, Board, State and Region are a plain 5-field row where
                  // each applies immediately on change
                  // (`onChange={e => { setXFilter(e.target.value); setPage(1); }}`
                  // — there is no staging/"Apply" button for these on web), plus
                  // a "Health flags" pill row below sourced from the backend's
                  // own `health_flags_counts`. Web's own "Region" <select> has no
                  // `value`/`onChange` at all — a real, confirmed bug on web
                  // itself (`region` IS a working backend filter,
                  // `views.py:572-575`, `queryset.filter(region=value)` — the
                  // web frontend just never wired the control to it). Wired here
                  // deliberately deviating from strict web parity since the
                  // underlying filter genuinely works.
                  Container(
                    margin: const EdgeInsets.only(bottom: 0),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      border: Border.all(
                        color: _smartFiltersOpen
                            ? AppColors.primaryPurple
                            : AppColors.borderPrimary,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(
                            () => _smartFiltersOpen = !_smartFiltersOpen,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Matches web's Accordion header `<span
                                // className="rounded-[6px] border px-[7px]
                                // py-[3px] font-mono ...">{num}</span>` — the
                                // numbered badge every accordion shows before
                                // its icon; this one was missing here.
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    // `purpleTint` (not `purpleSoft`) —
                                    // matches this same badge's own icon
                                    // container's background right next to
                                    // it, which already uses `purpleTint`;
                                    // they used to be two different purple
                                    // shades sitting side by side.
                                    color: _smartFiltersOpen
                                        ? AppColors.purpleTint
                                        : AppColors.bgSecondary,
                                    border: Border.all(
                                      color: _smartFiltersOpen
                                          ? Colors.transparent
                                          : AppColors.borderPrimary,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '02',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.4,
                                      color: _smartFiltersOpen
                                          ? AppColors.purpleDeep
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.purpleTint,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.filter_alt_outlined,
                                    color: AppColors.primaryPurple,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Smart filters',
                                        style: AppTextStyles.sectionTitle
                                            .copyWith(fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Find schools by status, plan, board, region & billing health',
                                        style: AppTextStyles.sectionSubtitle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_activeFilterCount(filters) > 0)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.purpleTint,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        '${_activeFilterCount(filters)} active',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.chipLabel(
                                          color: AppColors.purpleDeep,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Icon(
                                  _smartFiltersOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_smartFiltersOpen)
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.borderPrimary),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 14),
                                // Matches web's `<label>Search</label>` above the
                                // Smart Filters search box (`schools/page.tsx`) — the
                                // same missing-heading issue as the "02" badge above.
                                _filterLabel(
                                  'Search',
                                  TextField(
                                    controller: _searchController,
                                    onChanged: (value) => _applyFilters(
                                      filters,
                                      search: value.trim().isEmpty
                                          ? null
                                          : value.trim(),
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Name, tenant ID, GSTIN, UDISE, owner email…',
                                      hintStyle: AppTextStyles.sectionSubtitle,
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 18,
                                        color: AppColors.textTertiary,
                                      ),
                                      isDense: true,
                                      filled: true,
                                      fillColor: AppColors.bgSecondary,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.borderPrimary,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.borderPrimary,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.primaryPurple,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _filterLabel(
                                        'Plan',
                                        AppDropdown<String>(
                                          value: filters.plan,
                                          hint: const Text(
                                            'All plans',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text('All plans'),
                                            ),
                                            ..._kPlanOptions.map(
                                              (p) => DropdownMenuItem(
                                                value: p,
                                                child: Text(
                                                  p[0].toUpperCase() +
                                                      p.substring(1),
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (v) =>
                                              _applyFilters(filters, plan: v),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _filterLabel(
                                        'Board',
                                        AppDropdown<String>(
                                          value: filters.board,
                                          hint: const Text(
                                            'All boards',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text('All boards'),
                                            ),
                                            ..._kBoardOptions.map(
                                              (b) => DropdownMenuItem(
                                                value: b,
                                                child: Text(b),
                                              ),
                                            ),
                                          ],
                                          onChanged: (v) =>
                                              _applyFilters(filters, board: v),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _filterLabel(
                                        'State',
                                        AppDropdown<String>(
                                          value: filters.state,
                                          hint: const Text(
                                            'All states',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text('All states'),
                                            ),
                                            ..._kStateOptions.entries.map(
                                              (e) => DropdownMenuItem(
                                                value: e.key,
                                                child: Text(e.value),
                                              ),
                                            ),
                                          ],
                                          onChanged: (v) =>
                                              _applyFilters(filters, state: v),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _filterLabel(
                                        'Region',
                                        AppDropdown<String>(
                                          value: filters.region,
                                          hint: const Text(
                                            'All regions',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text('All regions'),
                                            ),
                                            ..._kRegionOptions.entries.map(
                                              (e) => DropdownMenuItem(
                                                value: e.key,
                                                child: Text(e.value),
                                              ),
                                            ),
                                          ],
                                          onChanged: (v) =>
                                              _applyFilters(filters, region: v),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'HEALTH FLAGS',
                                  style: AppTextStyles.sectionSubtitle.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    FilterPill(
                                      label: 'Billing overdue',
                                      count:
                                          healthFlagCounts?.billingOverdue ?? 0,
                                      isSelected:
                                          filters.healthFlag ==
                                          'billing_overdue',
                                      onTap: () => _applyFilters(
                                        filters,
                                        healthFlag:
                                            filters.healthFlag ==
                                                'billing_overdue'
                                            ? null
                                            : 'billing_overdue',
                                      ),
                                    ),
                                    FilterPill(
                                      label: 'Storage 80%+',
                                      count: healthFlagCounts?.storage80 ?? 0,
                                      isSelected:
                                          filters.healthFlag == 'storage_80',
                                      onTap: () => _applyFilters(
                                        filters,
                                        healthFlag:
                                            filters.healthFlag == 'storage_80'
                                            ? null
                                            : 'storage_80',
                                      ),
                                    ),
                                    FilterPill(
                                      label: 'Trial ending <7d',
                                      count: healthFlagCounts?.trialEnding ?? 0,
                                      isSelected:
                                          filters.healthFlag == 'trial_ending',
                                      onTap: () => _applyFilters(
                                        filters,
                                        healthFlag:
                                            filters.healthFlag == 'trial_ending'
                                            ? null
                                            : 'trial_ending',
                                      ),
                                    ),
                                    FilterPill(
                                      label: 'GSTIN missing',
                                      count:
                                          healthFlagCounts?.gstinMissing ?? 0,
                                      isSelected:
                                          filters.healthFlag == 'gstin_missing',
                                      onTap: () => _applyFilters(
                                        filters,
                                        healthFlag:
                                            filters.healthFlag ==
                                                'gstin_missing'
                                            ? null
                                            : 'gstin_missing',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SCHOOLS LIST — accordion "03", matching "Add a new school"
                  // (01) / "Smart filters" (02)'s exact visual pattern
                  // (`schools/page.tsx`'s Accordion num="03" title="Schools
                  // list"). Web defaults this open (`accListOpen` starts
                  // `true`), unlike "Add school" which starts closed.
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      border: Border.all(color: AppColors.borderPrimary),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(
                            () => _schoolsListOpen = !_schoolsListOpen,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    // `purpleTint` — matches this badge's own
                                    // icon container right next to it (same
                                    // fix as Section 02's badge above).
                                    color: _schoolsListOpen
                                        ? AppColors.purpleTint
                                        : AppColors.bgSecondary,
                                    border: Border.all(
                                      color: _schoolsListOpen
                                          ? Colors.transparent
                                          : AppColors.borderPrimary,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '03',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.4,
                                      color: _schoolsListOpen
                                          ? AppColors.purpleDeep
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.purpleTint,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.people_outline,
                                    color: AppColors.purpleDeep,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Schools list',
                                        style: AppTextStyles.accordionTitle,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${schools.results.length} of ${schools.count} shown · sorted by last activity',
                                        style: AppTextStyles.accordionSubtitle,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _buildMetaChip(
                                            '$totalStudents students',
                                            AppColors.successGreen,
                                          ),
                                          if (totalActiveStudents > 0 &&
                                              totalActiveStudents <
                                                  totalStudents) ...[
                                            _buildMetaChip(
                                              '$totalActiveStudents active',
                                              AppColors.successGreen,
                                            ),
                                            _buildMetaChip(
                                              '${totalStudents - totalActiveStudents} inactive',
                                              AppColors.textSecondary,
                                            ),
                                          ],
                                          _buildMetaChip(
                                            '$totalStaff staff',
                                            AppColors.infoBlue,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _schoolsListOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_schoolsListOpen)
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.borderPrimary),
                              ),
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // STATUS QUICK TABS — server-side filter (mirrors
                                // web's status quick-tabs, `schools/page.tsx`);
                                // "Trial" sends `status=trial`, which the
                                // backend maps to `plan=trial` internally.
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilterPill(
                                      label: 'All',
                                      count: totalCount,
                                      isSelected: filters.status == null,
                                      onTap: () =>
                                          _applyFilters(filters, status: null),
                                    ),
                                    FilterPill(
                                      label: 'Active',
                                      count: activeCount,
                                      isSelected: filters.status == 'active',
                                      onTap: () => _applyFilters(
                                        filters,
                                        status: 'active',
                                      ),
                                    ),
                                    FilterPill(
                                      label: 'Trial',
                                      count: trialCount,
                                      isSelected: filters.status == 'trial',
                                      onTap: () => _applyFilters(
                                        filters,
                                        status: 'trial',
                                      ),
                                    ),
                                    FilterPill(
                                      label: 'Suspended',
                                      count: attnCount,
                                      isSelected: filters.status == 'suspended',
                                      onTap: () => _applyFilters(
                                        filters,
                                        status: 'suspended',
                                      ),
                                    ),
                                    FilterPill(
                                      label: 'Archived',
                                      count: archivedCount,
                                      isSelected: filters.status == 'archived',
                                      onTap: () => _applyFilters(
                                        filters,
                                        status: 'archived',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // ACTIVE FILTER + EXPORT/REFRESH — matches web's
                                // `schools/page.tsx` row directly above the
                                // table. `LayoutBuilder`-based split (not a
                                // plain `Row`/`Wrap`) — a `Row`'s non-flexible
                                // children (including a `Wrap` that isn't itself
                                // given a bounded width) are laid out at their
                                // full natural size regardless of an `Expanded`
                                // sibling, which genuinely overflowed by 10px at
                                // 320dp (confirmed via widget test) once both
                                // buttons' natural width plus the label's
                                // couldn't fit one line. Below the threshold,
                                // the label moves above the button pair instead.
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final label = Text.rich(
                                      TextSpan(
                                        style: AppTextStyles.sectionSubtitle,
                                        children: [
                                          const TextSpan(
                                            text: 'Active filter: ',
                                          ),
                                          TextSpan(
                                            text: filters.status == null
                                                ? 'All · Active'
                                                : filters.status![0]
                                                          .toUpperCase() +
                                                      filters.status!.substring(
                                                        1,
                                                      ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.purpleDeep,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                    final buttons = Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: _exportBusy
                                              ? null
                                              : () => _handleExportSchools(
                                                  filters,
                                                ),
                                          icon: _exportBusy
                                              ? const SizedBox(
                                                  width: 13,
                                                  height: 13,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.download,
                                                  size: 13,
                                                ),
                                          label: Text(
                                            _exportBusy
                                                ? 'Exporting…'
                                                : 'Export',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              ref.invalidate(schoolsProvider),
                                          icon: const Icon(
                                            Icons.refresh,
                                            size: 13,
                                          ),
                                          label: const Text('Refresh'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                    // Below this width, the label's minimum
                                    // (ellipsized) width plus both buttons'
                                    // natural width can't share one line — stack
                                    // the label above the buttons instead of
                                    // ever letting the Row overflow.
                                    if (constraints.maxWidth < 300) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          label,
                                          const SizedBox(height: 8),
                                          buttons,
                                        ],
                                      );
                                    }
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: label),
                                        const SizedBox(width: 8),
                                        buttons,
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),

                                if (schools.results.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            'No schools found',
                                            style: AppTextStyles.sectionTitle
                                                .copyWith(fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Try adjusting the filters or add a new school above.',
                                            style:
                                                AppTextStyles.sectionSubtitle,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ...schools.results.map((school) {
                                    final gradient = _getAvatarGradient(
                                      school.tenantId,
                                    );

                                    return _buildSchoolCard(
                                      gradient: gradient,
                                      school: school,
                                    );
                                  }),

                                // PAGINATION
                                if (schools.count > (filters.pageSize ?? 20))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${((filters.page ?? 1) - 1) * (filters.pageSize ?? 20) + 1}–'
                                          '${((filters.page ?? 1) * (filters.pageSize ?? 20)).clamp(0, schools.count)} of ${schools.count}',
                                          style: AppTextStyles.sectionSubtitle,
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.chevron_left,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  (filters.page ?? 1) <= 1
                                                  ? null
                                                  : () =>
                                                        ref
                                                            .read(
                                                              schoolsFiltersProvider
                                                                  .notifier,
                                                            )
                                                            .state = filters
                                                            .copyWith(
                                                              page:
                                                                  (filters.page ??
                                                                      1) -
                                                                  1,
                                                            ),
                                            ),
                                            Text(
                                              '${filters.page ?? 1}',
                                              style:
                                                  AppTextStyles.sectionSubtitle,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                              ),
                                              onPressed: schools.next == null
                                                  ? null
                                                  : () =>
                                                        ref
                                                            .read(
                                                              schoolsFiltersProvider
                                                                  .notifier,
                                                            )
                                                            .state = filters
                                                            .copyWith(
                                                              page:
                                                                  (filters.page ??
                                                                      1) +
                                                                  1,
                                                            ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One school — a compact two-column row matching web's own table row
  /// exactly (`schools/page.tsx`'s `<table>`: SCHOOL column = avatar/name/
  /// subdomain, TENANT · STATE column on the right), not the previous
  /// expanded card that also showed board/plan/status chips, the GSTIN/PAN/
  /// UDISE/Seats/Staff grid, the LLM toggle, and Edit/Impersonate/Suspend/
  /// Archive inline. Those didn't disappear — they now live on the School
  /// Detail page ([SchoolDetailPage], already showing every one of those
  /// fields plus its own Impersonate/Archive/LLM actions added alongside
  /// this change) — tapping a row (matching web's own `<Link>` on the name)
  /// is the way there, same as before.
  Widget _buildSchoolCard({
    required List<Color> gradient,
    required SchoolEntity school,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderPrimary),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/super-admin/schools/${school.tenantId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getSchoolInitials(school.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // SCHOOL column — name + subdomain, matches web's table cell.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      school.name,
                      style: AppTextStyles.accordionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${school.subdomainUrl}.eskoolia.com',
                      style: AppTextStyles.accordionSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // TENANT · STATE column — web's own second table column,
              // right-aligned to sit at the row's trailing edge like a
              // table's second `<td>` rather than wrapping under the name.
              Text(
                '${school.tenantId} · ${_orDash(school.state)}',
                textAlign: TextAlign.right,
                style: AppTextStyles.accordionSubtitle.copyWith(fontFamily: 'monospace'),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Matches web's `<label>Plan</label>` etc. above each Smart Filters
  /// `<select>` (`schools/page.tsx`) — Flutter's own dropdowns don't carry
  /// a visible field label otherwise.
  Widget _filterLabel(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.sectionSubtitle.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.chipLabel(color: color)),
    );
  }

}
