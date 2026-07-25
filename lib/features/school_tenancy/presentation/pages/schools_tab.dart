import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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

/// Plan/Board/State option lists match the web frontend's own `<select>`
/// options exactly (`schools/page.tsx`'s Smart Filters accordion) — the web
/// UI itself only offers these values (e.g. only 2 states), so this isn't a
/// Flutter-side omission.
const _kPlanOptions = ['trial', 'starter', 'standard', 'premium', 'enterprise'];
const _kBoardOptions = ['CBSE', 'ICSE', 'SSC_TG', 'SSC_AP', 'OTHER'];
const _kStateOptions = {'36': 'Telangana (36)', '37': 'Andhra Pradesh (37)'};

/// Sentinel used to distinguish "argument not passed" from "argument
/// explicitly passed as null" in [_SuperAdminSchoolsPageState._applyFilters].
const Object _unset = Object();

class _SuperAdminSchoolsPageState extends ConsumerState<SuperAdminSchoolsPage> {
  final Set<String> _expandedSchools = {};
  final TextEditingController _searchController = TextEditingController();

  // "Add a new school" accordion — matches web's `accAddOpen` (defaults to
  // closed, `schools/page.tsx:437`), embedded inline above "Smart filters"
  // rather than as a separate screen (web never navigates anywhere for this;
  // it just expands Accordion "01" in place on the same Schools page).
  bool _addSchoolOpen = false;
  SchoolEntity? _editingSchool;
  final GlobalKey _addSchoolKey = GlobalKey();

  void _openAddSchool({SchoolEntity? edit}) {
    setState(() {
      _addSchoolOpen = true;
      _editingSchool = edit;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _addSchoolKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }

  void _closeAddSchool() {
    setState(() {
      _addSchoolOpen = false;
      _editingSchool = null;
    });
  }

  // "Pending" board/plan/state selections, only applied to the real filter
  // (and thus re-fetched from the backend) when "Apply" is tapped — mirrors
  // web's `pendingPlan`/`pendingBoard`/`pendingState` + `handleApplyFilters`.
  String? _pendingPlan;
  String? _pendingBoard;
  String? _pendingState;

  /// tenant_id currently mid-mutation (suspend/restore/archive/impersonate),
  /// used to show a spinner and disable that row's actions while in flight.
  String? _busyTenantId;

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
  }) {
    ref.read(schoolsFiltersProvider.notifier).state = SchoolFilters(
      page: 1,
      pageSize: current.pageSize,
      search: search ?? current.search,
      status: status == _unset ? current.status : status as String?,
      board: board == _unset ? current.board : board as String?,
      plan: plan == _unset ? current.plan : plan as String?,
      state: state == _unset ? current.state : state as String?,
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
                          onPressed: () {},
                          icon: const Icon(Icons.download, size: 14),
                          label: const Text('Export'),
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
                              child: Icon(_editingSchool != null ? Icons.edit_outlined : Icons.add, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _editingSchool != null ? 'Edit school · ${_editingSchool!.name}' : 'Add a new school',
                                    style: AppTextStyles.accordionTitle,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _editingSchool != null
                                        ? 'Editing ${_editingSchool!.tenantId} · Update plan, board, state or data regions'
                                        : 'Provisions a new isolated tenant · 9 sections · Identity, branding, contacts, GST, plan & data residency',
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
                                _editingSchool != null ? 'Editing · ${_editingSchool!.tenantId}' : 'Auto-generates tenant ID',
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
                          key: ValueKey(_editingSchool?.tenantId ?? 'new'),
                          editSchool: _editingSchool,
                          onCancel: _closeAddSchool,
                          onSaved: _closeAddSchool,
                        ),
                      ),
                  ],
                ),
              ),

              // STATUS QUICK TABS — server-side filter (mirrors web's status
              // quick-tabs, `schools/page.tsx:1468-1498`); "Trial" sends
              // `status=trial`, which the backend maps to `plan=trial`
              // internally (`views.py:478-480`).
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

              const SizedBox(height: 16),

              // SMART FILTERS — search is live (matches web's controlled
              // `search` input); Plan/Board/State are staged and only
              // applied to the real query on "Apply" (matches web's
              // `pendingPlan/pendingBoard/pendingState` + `handleApplyFilters`).
              // Web's "Region" select has no `value`/`onChange` at all
              // (`schools/page.tsx:1391-1395`) — it's decorative on web
              // itself, so it's intentionally not wired here either.
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
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => _applyFilters(filters, search: value.trim().isEmpty ? null : value.trim()),
                      decoration: InputDecoration(
                        hintText: 'Name, tenant ID, GSTIN, UDISE…',
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
                          child: AppDropdown<String>(
                            value: _pendingPlan,
                            hint: const Text('All plans', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All plans')),
                              ..._kPlanOptions.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p[0].toUpperCase() + p.substring(1)),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _pendingPlan = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppDropdown<String>(
                            value: _pendingBoard,
                            hint: const Text('All boards', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All boards')),
                              ..._kBoardOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                            ],
                            onChanged: (v) => setState(() => _pendingBoard = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdown<String>(
                            value: _pendingState,
                            hint: const Text('All states', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All states')),
                              ..._kStateOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                            ],
                            onChanged: (v) => setState(() => _pendingState = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _applyFilters(
                            filters,
                            board: _pendingBoard,
                            plan: _pendingPlan,
                            state: _pendingState,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SCHOOLS LIST — already server-filtered/paginated by
              // [schoolsProvider]; no client-side re-filtering here.
              Text(
                '${schools.results.length} of ${schools.count} schools',
                style: AppTextStyles.sectionTitle,
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
              const SizedBox(height: 12),

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
                ...schools.results.asMap().entries.map((entry) {
                  final index = entry.key;
                  final school = entry.value;
                  final isExpanded = _expandedSchools.contains(school.tenantId);
                  final gradient = _getAvatarGradient(school.tenantId);
                  final pageOffset = ((filters.page ?? 1) - 1) * (filters.pageSize ?? 20);
                  final number = (pageOffset + index + 1).toString().padLeft(2, '0');

                  return _buildSchoolAccordion(
                    number: number,
                    gradient: gradient,
                    school: school,
                    isExpanded: isExpanded,
                    onToggle: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedSchools.remove(school.tenantId);
                        } else {
                          _expandedSchools.add(school.tenantId);
                        }
                      });
                    },
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSchoolAccordion({
    required String number,
    required List<Color> gradient,
    required SchoolEntity school,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(
          color: isExpanded ? AppColors.borderSecondary : AppColors.borderPrimary,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Numbered badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isExpanded ? AppColors.purpleSoft : AppColors.bgTertiary,
                      border: Border.all(
                        color: isExpanded ? Colors.transparent : AppColors.borderPrimary,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '[$number]',
                      style: AppTextStyles.numberedBadge.copyWith(
                        color: isExpanded ? AppColors.purpleDeep : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

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

                  // School info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(school.name, style: AppTextStyles.accordionTitle),
                        const SizedBox(height: 2),
                        Text(school.tenantId, style: AppTextStyles.accordionSubtitle),
                      ],
                    ),
                  ),

                  // Status & chips
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
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
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BoardChip(
                            label: _orDash(school.board),
                            color: AppColors.getBoardColor(school.board),
                          ),
                          const SizedBox(width: 4),
                          BoardChip(
                            label: school.plan[0].toUpperCase() + school.plan.substring(1),
                            color: AppColors.getPlanColor(school.plan),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Expand icon
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isExpanded ? AppColors.textPrimary : AppColors.textTertiary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderPrimary)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Details grid — a `LayoutBuilder`+`Wrap` (width-constrained,
                  // height-intrinsic tiles) rather than a fixed-aspect-ratio
                  // `GridView.count`, so a long "State" value at larger
                  // text-scale settings wraps within its own tile instead of
                  // overflowing a height ceiling that only accounted for a
                  // single line of text.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final itemWidth = (constraints.maxWidth - spacing) / 2;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(width: itemWidth, child: _buildDetailItem('Students', '${school.students}')),
                          SizedBox(width: itemWidth, child: _buildDetailItem('Active', '${school.activeStudents}')),
                          SizedBox(width: itemWidth, child: _buildDetailItem('Staff', '${school.staff}')),
                          SizedBox(width: itemWidth, child: _buildDetailItem('State', _orDash(school.state))),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Action buttons — mirrors web's per-row action set exactly
                  // (`schools/page.tsx:1626-1637`): archived schools get
                  // Open/Restore/Audit Logs/Permanent Delete, everyone else
                  // gets Open/Edit/Impersonate/Suspend/Archive.
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
          _buildActionButton('Open', Icons.open_in_new, busy ? null : () => _launch('https://${school.subdomainUrl}.eskoolia.com')),
          _buildActionButton('Restore', Icons.restore, busy ? null : () async {
            if (await _confirm('Restore school', 'Restore ${school.name} to active status?')) {
              await _handleStatusChange(school, 'active', '${school.name} restored to active.');
            }
          }, busy: busy),
          _buildActionButton('Audit Logs', Icons.description_outlined, busy ? null : () => _notImplemented('Per-school audit log is not yet available on mobile.')),
          _buildActionButton('Delete', Icons.delete_outline, () => _notImplemented('Permanent delete is not yet available — contact system administrator.')),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton('Open', Icons.open_in_new, busy ? null : () => _launch('https://${school.subdomainUrl}.eskoolia.com')),
        _buildActionButton('Edit', Icons.edit_outlined, busy ? null : () => _openAddSchool(edit: school)),
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
