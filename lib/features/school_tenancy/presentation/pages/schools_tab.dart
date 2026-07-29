import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/filter_pill_widget.dart';
import '../../../../core/widgets/status_chip_widget.dart';
import '../../domain/entities/school_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';
import 'add_school_page.dart';

/// Super Admin Schools Page
/// Exact conversion of web frontend schools structure
class SuperAdminSchoolsPage extends ConsumerStatefulWidget {
  const SuperAdminSchoolsPage({super.key});

  @override
  ConsumerState<SuperAdminSchoolsPage> createState() => _SuperAdminSchoolsPageState();
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

  /// tenant_ids currently mid-LLM-toggle, used to show a spinner and
  /// disable that row's switch while in flight.
  final Set<String> _llmToggling = {};

  /// "Schools list" accordion (03) — matches web's `accListOpen`, which
  /// defaults to open (`schools/page.tsx`), unlike "Add school" (01).
  bool _schoolsListOpen = true;

  // "Add a new school" accordion — matches web's `accAddOpen` (defaults to
  // closed, `schools/page.tsx:437`), embedded inline above "Smart filters"
  // rather than as a separate screen (web never navigates anywhere for this;
  // it just expands Accordion "01" in place on the same Schools page).
  bool _addSchoolOpen = false;
  final GlobalKey _addSchoolKey = GlobalKey();

  void _openAddSchool() {
    setState(() => _addSchoolOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _addSchoolKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }

  void _closeAddSchool() => setState(() => _addSchoolOpen = false);

  /// tenant_id currently mid-mutation (suspend/restore/archive/impersonate),
  /// used to show a spinner and disable that row's actions while in flight.
  String? _busyTenantId;

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
        filename: 'eskoolia-schools-${DateTime.now().toIso8601String().split('T').first}.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schools exported.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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
      ref.read(schoolsFiltersProvider.notifier).state = const SchoolFilters(status: 'active');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(SchoolFilters current, {
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
      healthFlag: healthFlag == _unset ? current.healthFlag : healthFlag as String?,
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  void _notImplemented(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshAfterMutation() async {
    ref.invalidate(schoolsProvider);
    ref.invalidate(schoolsGlobalStatsProvider);
  }

  Future<void> _handleLLMToggle(SchoolEntity school, LLMSchoolStateEntity llm) async {
    setState(() => _llmToggling.add(school.tenantId));
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final newVal = await repository.toggleSchoolLLM(llm.id, !llm.llmEnabled);
      ref.invalidate(llmStatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('LLM ${newVal ? 'enabled' : 'disabled'} for ${school.name}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update LLM access: $e')));
      }
    } finally {
      if (mounted) setState(() => _llmToggling.remove(school.tenantId));
    }
  }

  Future<void> _handleImpersonate(SchoolEntity school) async {
    setState(() => _busyTenantId = school.tenantId);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final result = await repository.impersonateSchool(school.tenantId);
      await _launch(result.handoffUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impersonation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyTenantId = null);
    }
  }

  Future<void> _handleStatusChange(SchoolEntity school, String newStatus, String successMessage) async {
    setState(() => _busyTenantId = school.tenantId);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      await repository.updateSchoolStatus(school.tenantId, newStatus);
      await _refreshAfterMutation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busyTenantId = null);
    }
  }

  Future<void> _handleArchive(SchoolEntity school) async {
    setState(() => _busyTenantId = school.tenantId);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      await repository.archiveSchool(school.tenantId);
      await _refreshAfterMutation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${school.name} archived.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busyTenantId = null);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    return result ?? false;
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
  String _orDash(String? value) => (value == null || value.isEmpty) ? '—' : value;

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsProvider);
    final globalStatsAsync = ref.watch(schoolsGlobalStatsProvider);
    final filters = ref.watch(schoolsFiltersProvider);

    if (schoolsAsync.isLoading && !schoolsAsync.hasValue) {
      return const SchoolTenancyLayout(
        currentPath: '/super-admin/schools',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (schoolsAsync.hasError && !schoolsAsync.hasValue) {
      return SchoolTenancyLayout(
        currentPath: '/super-admin/schools',
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

    final schools = schoolsAsync.value!;
    final globalStats = globalStatsAsync.value;
    final healthFlagCounts = schools.healthFlagsCounts;
    final llmStates = ref.watch(llmStatesProvider).value;

    // Page-level stats (over the current filtered/paginated batch only) —
    // mirrors web's `totalStudents`/`totalActiveStudents`/`totalStaff`
    // computed from `rows`, not from global stats.
    final totalStudents = schools.results.fold<int>(0, (sum, s) => sum + s.students);
    final totalActiveStudents = schools.results.fold<int>(0, (sum, s) => sum + s.activeStudents);
    final totalStaff = schools.results.fold<int>(0, (sum, s) => sum + s.staff);

    // Fallback local counts (used only until schoolsGlobalStatsProvider
    // resolves) — mirrors web's `globalStats.X || localCount` pattern.
    final activeCountFallback = schools.results.where((s) => !['archived', 'suspended'].contains(s.status)).length;
    final trialCountFallback = schools.results.where((s) => s.plan == 'trial' && !['archived', 'suspended'].contains(s.status)).length;
    final attnCountFallback = schools.results.where((s) => s.status == 'suspended').length;
    final archivedCountFallback = schools.results.where((s) => s.status == 'archived').length;

    final totalCount = globalStats?.total ?? schools.count;
    final activeCount = (globalStats != null && globalStats.active > 0) ? globalStats.active : activeCountFallback;
    final trialCount = (globalStats != null && globalStats.trial > 0) ? globalStats.trial : trialCountFallback;
    final attnCount = (globalStats != null && globalStats.attention > 0) ? globalStats.attention : attnCountFallback;
    final archivedCount = (globalStats != null && globalStats.archived > 0) ? globalStats.archived : archivedCountFallback;

    return SchoolTenancyLayout(
      currentPath: '/super-admin/schools',
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
                    // Title row
                    Wrap(
                      spacing: 6,
                      children: [
                        Text('School', style: AppTextStyles.pageTitle),
                        Text('Management', style: AppTextStyles.pageTitleAccent),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.pageSubtitle,
                        children: const [
                          TextSpan(text: 'Provision, monitor & manage every school tenant. · Each school has its own '),
                          TextSpan(
                            text: 'tenant ID',
                            style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                          TextSpan(text: ', GSTIN, dedicated DB shard & zero cross-tenant visibility.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _exportBusy ? null : () => _handleExportSchools(filters),
                          icon: _exportBusy
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download, size: 14),
                          label: Text(_exportBusy ? 'Exporting…' : 'Export'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: AppTextStyles.buttonSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _openAddSchool(),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add school'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: AppTextStyles.buttonPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // KPI CARDS
              KpiCardGrid(
                spacing: 14,
                cards: [
                  KpiCard(
                    label: 'Total Schools',
                    value: '$totalCount',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF5836E0),
                    // Web hardcodes this exact trend/footnote copy on the
                    // Schools page too (`schools/page.tsx:800-801`) — not a
                    // Flutter-side fabrication.
                    trend: '+3 QoQ',
                    trendColor: AppColors.successGreen,
                    footnote: 'Telangana & Andhra Pradesh',
                  ),
                  KpiCard(
                    label: 'Active Tenants',
                    value: '$activeCount',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0E9F6E),
                    trend: 'Healthy',
                    trendColor: AppColors.successGreen,
                    footnote: '$totalStudents enrolled · $totalActiveStudents active',
                  ),
                  KpiCard(
                    label: 'On Trial',
                    value: '$trialCount',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFFA65D08),
                    // Web hardcodes "Avg conv 68%" too (`schools/page.tsx:806`).
                    trend: 'Avg conv 68%',
                    trendColor: AppColors.warningAmber,
                    footnote: 'Trial-to-paid conversion',
                  ),
                  KpiCard(
                    label: 'Needs Attention',
                    value: '$attnCount',
                    sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                    sparklineColor: const Color(0xFFE0463A),
                    trend: attnCount > 0 ? '$attnCount suspended' : 'All clear',
                    trendColor: attnCount > 0 ? AppColors.dangerRed : AppColors.textTertiary,
                    footnote: 'Open across tenants',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ACCORDION 01 — ADD A NEW SCHOOL / EDIT SCHOOL — embedded
              // inline above Smart filters, matching web's real layout
              // exactly (`schools/page.tsx` Accordion "01", collapsed by
              // default — `accAddOpen` starts `false`). This used to be a
              // separate pushed page, which didn't match web: web never
              // navigates anywhere for "Add school"/"Edit" — it just expands
              // this section in place on the same Schools page.
              Container(
                key: _addSchoolKey,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border.all(color: _addSchoolOpen ? AppColors.primaryPurple : AppColors.borderPrimary),
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
                              decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(9)),
                              child: const Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Add a new school', style: AppTextStyles.accordionTitle),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Provisions a new isolated tenant · 9 sections · Identity, branding, contacts, GST, plan & data residency',
                                    style: AppTextStyles.accordionSubtitle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                'Auto-generates tenant ID',
                                style: AppTextStyles.chipLabel(color: AppColors.purpleDeep),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(_addSchoolOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    if (_addSchoolOpen)
                      Container(
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border.all(color: AppColors.borderPrimary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart filters', style: AppTextStyles.sectionTitle.copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      'Find schools by status, plan, board, region & billing health',
                      style: AppTextStyles.sectionSubtitle,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => _applyFilters(filters, search: value.trim().isEmpty ? null : value.trim()),
                      decoration: InputDecoration(
                        hintText: 'Name, tenant ID, GSTIN, UDISE, owner email…',
                        hintStyle: AppTextStyles.sectionSubtitle,
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.bgSecondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.borderPrimary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.borderPrimary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              hint: const Text('All plans', style: TextStyle(fontSize: 12)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All plans')),
                                ..._kPlanOptions.map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p[0].toUpperCase() + p.substring(1)),
                                    )),
                              ],
                              onChanged: (v) => _applyFilters(filters, plan: v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _filterLabel(
                            'Board',
                            AppDropdown<String>(
                              value: filters.board,
                              hint: const Text('All boards', style: TextStyle(fontSize: 12)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All boards')),
                                ..._kBoardOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                              ],
                              onChanged: (v) => _applyFilters(filters, board: v),
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
                              hint: const Text('All states', style: TextStyle(fontSize: 12)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All states')),
                                ..._kStateOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                              ],
                              onChanged: (v) => _applyFilters(filters, state: v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _filterLabel(
                            'Region',
                            AppDropdown<String>(
                              value: filters.region,
                              hint: const Text('All regions', style: TextStyle(fontSize: 12)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All regions')),
                                ..._kRegionOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                              ],
                              onChanged: (v) => _applyFilters(filters, region: v),
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
                          count: healthFlagCounts?.billingOverdue ?? 0,
                          isSelected: filters.healthFlag == 'billing_overdue',
                          onTap: () => _applyFilters(
                            filters,
                            healthFlag: filters.healthFlag == 'billing_overdue' ? null : 'billing_overdue',
                          ),
                        ),
                        FilterPill(
                          label: 'Storage 80%+',
                          count: healthFlagCounts?.storage80 ?? 0,
                          isSelected: filters.healthFlag == 'storage_80',
                          onTap: () => _applyFilters(
                            filters,
                            healthFlag: filters.healthFlag == 'storage_80' ? null : 'storage_80',
                          ),
                        ),
                        FilterPill(
                          label: 'Trial ending <7d',
                          count: healthFlagCounts?.trialEnding ?? 0,
                          isSelected: filters.healthFlag == 'trial_ending',
                          onTap: () => _applyFilters(
                            filters,
                            healthFlag: filters.healthFlag == 'trial_ending' ? null : 'trial_ending',
                          ),
                        ),
                        FilterPill(
                          label: 'GSTIN missing',
                          count: healthFlagCounts?.gstinMissing ?? 0,
                          isSelected: filters.healthFlag == 'gstin_missing',
                          onTap: () => _applyFilters(
                            filters,
                            healthFlag: filters.healthFlag == 'gstin_missing' ? null : 'gstin_missing',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                      onTap: () => setState(() => _schoolsListOpen = !_schoolsListOpen),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.purpleSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('03', style: AppTextStyles.numberedBadge.copyWith(color: AppColors.purpleDeep)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(9)),
                              child: const Icon(Icons.people_outline, color: AppColors.purpleDeep, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Schools list', style: AppTextStyles.accordionTitle),
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
                                      _buildMetaChip('$totalStudents students', AppColors.successGreen),
                                      if (totalActiveStudents > 0 && totalActiveStudents < totalStudents) ...[
                                        _buildMetaChip('$totalActiveStudents active', AppColors.successGreen),
                                        _buildMetaChip('${totalStudents - totalActiveStudents} inactive', AppColors.textSecondary),
                                      ],
                                      _buildMetaChip('$totalStaff staff', AppColors.infoBlue),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(_schoolsListOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    if (_schoolsListOpen)
                      Container(
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
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
                                  onTap: () => _applyFilters(filters, status: null),
                                ),
                                FilterPill(
                                  label: 'Active',
                                  count: activeCount,
                                  isSelected: filters.status == 'active',
                                  onTap: () => _applyFilters(filters, status: 'active'),
                                ),
                                FilterPill(
                                  label: 'Trial',
                                  count: trialCount,
                                  isSelected: filters.status == 'trial',
                                  onTap: () => _applyFilters(filters, status: 'trial'),
                                ),
                                FilterPill(
                                  label: 'Suspended',
                                  count: attnCount,
                                  isSelected: filters.status == 'suspended',
                                  onTap: () => _applyFilters(filters, status: 'suspended'),
                                ),
                                FilterPill(
                                  label: 'Archived',
                                  count: archivedCount,
                                  isSelected: filters.status == 'archived',
                                  onTap: () => _applyFilters(filters, status: 'archived'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // ACTIVE FILTER + EXPORT/REFRESH — matches web's
                            // `schools/page.tsx` row directly above the table.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: AppTextStyles.sectionSubtitle,
                                      children: [
                                        const TextSpan(text: 'Active filter: '),
                                        TextSpan(
                                          text: filters.status == null
                                              ? 'All · Active'
                                              : filters.status![0].toUpperCase() + filters.status!.substring(1),
                                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.purpleDeep),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _exportBusy ? null : () => _handleExportSchools(filters),
                                  icon: _exportBusy
                                      ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.download, size: 13),
                                  label: Text(_exportBusy ? 'Exporting…' : 'Export'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton.icon(
                                  onPressed: () => ref.invalidate(schoolsProvider),
                                  icon: const Icon(Icons.refresh, size: 13),
                                  label: const Text('Refresh'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            if (schools.results.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text('No schools found', style: AppTextStyles.sectionTitle.copyWith(fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Try adjusting the filters or add a new school above.',
                                        style: AppTextStyles.sectionSubtitle,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...schools.results.map((school) {
                                final gradient = _getAvatarGradient(school.tenantId);

                                return _buildSchoolCard(
                                  gradient: gradient,
                                  school: school,
                                  llm: llmStates?[school.tenantId],
                                  llmBusy: _llmToggling.contains(school.tenantId),
                                  onLlmToggle: (v) => _handleLLMToggle(school, llmStates![school.tenantId]!),
                                );
                              }),

                            // PAGINATION
                            if (schools.count > (filters.pageSize ?? 20))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${((filters.page ?? 1) - 1) * (filters.pageSize ?? 20) + 1}–'
                                      '${((filters.page ?? 1) * (filters.pageSize ?? 20)).clamp(0, schools.count)} of ${schools.count}',
                                      style: AppTextStyles.sectionSubtitle,
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left, size: 20),
                                          onPressed: (filters.page ?? 1) <= 1
                                              ? null
                                              : () => ref.read(schoolsFiltersProvider.notifier).state =
                                                  filters.copyWith(page: (filters.page ?? 1) - 1),
                                        ),
                                        Text('${filters.page ?? 1}', style: AppTextStyles.sectionSubtitle),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right, size: 20),
                                          onPressed: schools.next == null
                                              ? null
                                              : () => ref.read(schoolsFiltersProvider.notifier).state =
                                                  filters.copyWith(page: (filters.page ?? 1) + 1),
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// One school — a real [Card] (not a plain [Container] stacked inside the
  /// page's outer scroll view) matching web's table row content, field for
  /// field: School / Tenant · State / Board / GSTIN / Plan · Students /
  /// Status / LLM / Actions. Tapping the header navigates to the school's
  /// detail screen (mirrors web's `<Link href={/super-admin/schools/
  /// ${tenant_id}}>` on the name) instead of only expanding in place —
  /// per-row actions (Edit/Impersonate/Suspend/Archive) stay inline and act
  /// immediately, matching web's own separate "Actions" column.
  Widget _buildSchoolCard({
    required List<Color> gradient,
    required SchoolEntity school,
    LLMSchoolStateEntity? llm,
    bool llmBusy = false,
    ValueChanged<bool>? onLlmToggle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderPrimary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => context.go('/super-admin/schools/${school.tenantId}'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
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
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // School + Tenant · State
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(school.name, style: AppTextStyles.accordionTitle),
                        const SizedBox(height: 2),
                        Text('${school.subdomainUrl}.eskoolia.com', style: AppTextStyles.accordionSubtitle),
                        const SizedBox(height: 2),
                        Text(
                          '${school.tenantId} · ${_orDash(school.state)}',
                          style: AppTextStyles.accordionSubtitle.copyWith(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Board / Plan · Students / Status
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    BoardChip(label: _orDash(school.board), color: AppColors.getBoardColor(school.board)),
                    BoardChip(
                      label: '${school.plan[0].toUpperCase()}${school.plan.substring(1)} · ${school.students}',
                      color: AppColors.getPlanColor(school.plan),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: school.status == 'active' ? AppColors.successGreen : AppColors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            school.status[0].toUpperCase() + school.status.substring(1),
                            style: AppTextStyles.chipLabel().copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // GSTIN / UDISE / PAN / Seats / Staff — real fields already
                // on [SchoolEntity], not otherwise visible in the header row.
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;
                    final itemWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        SizedBox(width: itemWidth, child: _buildDetailItem('GSTIN', school.gstin?.isNotEmpty == true ? school.gstin! : 'Unregistered')),
                        SizedBox(width: itemWidth, child: _buildDetailItem('PAN', _orDash(school.pan))),
                        SizedBox(width: itemWidth, child: _buildDetailItem('UDISE+ code', _orDash(school.udiseCode))),
                        SizedBox(width: itemWidth, child: _buildDetailItem('Seats', school.seats > 0 ? '${school.seats}' : '—')),
                        SizedBox(width: itemWidth, child: _buildDetailItem('Staff', '${school.staff}')),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // LLM — real toggle wired to `getLLMStates()`/`toggleSchoolLLM()`.
                Row(
                  children: [
                    Text('LLM access', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    if (llmBusy)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Switch(
                        value: llm?.llmEnabled ?? false,
                        onChanged: llm == null ? null : onLlmToggle,
                      ),
                    if (llm == null)
                      Text('Not in LLM registry', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons — mirrors web's per-row action set exactly
                // (`schools/page.tsx`): archived schools get Restore/Audit
                // Logs, everyone else gets Edit/Impersonate/Suspend/Archive.
                // "Open" is the header tap above, matching web's Link.
                _buildRowActions(school),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.boardLabel.copyWith(fontSize: 14),
        ),
      ],
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

  Widget _buildRowActions(SchoolEntity school) {
    final busy = _busyTenantId == school.tenantId;

    if (school.status == 'archived') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildActionButton('Open', Icons.open_in_new, busy ? null : () => context.go('/super-admin/schools/${school.tenantId}')),
          _buildActionButton('Restore', Icons.restore, busy ? null : () async {
            if (await _confirm('Restore school', 'Restore ${school.name} to active status?')) {
              await _handleStatusChange(school, 'active', '${school.name} restored to active.');
            }
          }, busy: busy),
          _buildActionButton('Audit Logs', Icons.description_outlined, busy ? null : () => context.go('/super-admin/schools/${school.tenantId}')),
          _buildActionButton('Delete', Icons.delete_outline, () => _notImplemented('Permanent delete is not yet available — contact system administrator.')),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton('Open', Icons.open_in_new, busy ? null : () => context.go('/super-admin/schools/${school.tenantId}')),
        // Navigates to the dedicated Edit School screen — mirrors web's own
        // separate `/super-admin/schools/{tenantId}/edit` route, which has
        // its own distinct 5-section field set, not this "Add a new school"
        // wizard's 9 sections.
        _buildActionButton('Edit', Icons.edit_outlined, busy ? null : () => context.go('/super-admin/schools/${school.tenantId}/edit')),
        _buildActionButton('Impersonate', Icons.people_outline, busy ? null : () => _handleImpersonate(school), busy: busy),
        _buildActionButton(
          'Suspend',
          Icons.pause_circle_outline,
          (busy || school.status == 'suspended') ? null : () async {
            if (await _confirm('Suspend school', 'Suspend ${school.name}? Their admin console access will be blocked.')) {
              await _handleStatusChange(school, 'suspended', '${school.name} suspended.');
            }
          },
        ),
        _buildActionButton('Archive', Icons.archive_outlined, busy ? null : () async {
          if (await _confirm('Archive school', 'Archive ${school.name}? This can be undone via Restore.')) {
            await _handleArchive(school);
          }
        }, busy: busy),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback? onPressed, {bool busy = false}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: busy
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: AppColors.borderPrimary),
        foregroundColor: AppColors.textPrimary,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
