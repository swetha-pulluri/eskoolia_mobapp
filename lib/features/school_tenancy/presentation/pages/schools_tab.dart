import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/inline_kpi_card.dart';
import '../../../../core/widgets/status_chip_widget.dart';
import '../../../../core/widgets/filter_pill_widget.dart';
import '../../domain/entities/school_entity.dart' show SchoolEntity;
import '../providers/school_tenancy_local_data.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Schools page — "School Management".
/// Converts the web `/super-admin/schools` page (Title row, KPI grid, the
/// three numbered Accordion sections — Add school / Smart filters / Schools
/// list — and the schools table) directly, section by section. The desktop
/// table becomes a horizontally-scrollable mobile table (same columns, same
/// data), not cards. The "Add / Edit school" 9-section provisioning wizard
/// itself (logo upload, brand colour picker, admin credential generation)
/// has no backend wired up yet on either side and stays a stub — tapping it
/// shows a clear "coming in a follow-up pass" notice rather than a half
/// built form.
class SuperAdminSchoolsPage extends ConsumerStatefulWidget {
  const SuperAdminSchoolsPage({super.key});

  @override
  ConsumerState<SuperAdminSchoolsPage> createState() => _SuperAdminSchoolsPageState();
}

class _SuperAdminSchoolsPageState extends ConsumerState<SuperAdminSchoolsPage> {
  final TextEditingController _searchController = TextEditingController();

  // Immediate — applied as soon as tapped (matches web `statusFilter`).
  String _statusFilter = 'active';

  // Pending — only committed to the real filters when "Apply" is tapped
  // (matches web `pendingPlan/pendingBoard/pendingState` + `handleApplyFilters`).
  String _pendingPlan = '';
  String _pendingBoard = '';
  String _pendingState = '';
  String _regionValue = ''; // decorative only — web's Region select is unbound too.

  // Committed filters actually applied to the list.
  String _planFilter = '';
  String _boardFilter = '';
  String _stateFilter = '';

  // Accordion open/closed state — web defaults: 01 closed, 02 & 03 open.
  bool _accAddOpen = false;
  bool _accFiltersOpen = true;
  bool _accListOpen = true;

  // The web's State filter only lists these two states (an existing web
  // limitation, reproduced exactly rather than "fixed").
  static const Map<String, String> _stateCodeToName = {
    '36': 'Telangana',
    '37': 'Andhra Pradesh',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatIndian(int n) {
    final digits = n.toString();
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  List<Color> _avatarGradient(String tenantId) => AppColors.getAvatarGradient(tenantId);

  String _initials(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return name.substring(0, name.length < 2 ? name.length : 2).toUpperCase();
  }

  String _boardLabel(String? board) {
    if (board == 'SSC_AP') return 'SSC AP';
    if (board == 'SSC_TG') return 'SSC TG';
    return board ?? '—';
  }

  String _planLabel(String plan) => plan.isEmpty ? '—' : plan[0].toUpperCase() + plan.substring(1);

  Color _statusDotColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF0D7A55);
      case 'trial':
        return AppColors.warningAmber;
      case 'suspended':
        return AppColors.dangerRed;
      case 'onboarding':
        return AppColors.infoBlue;
      case 'archived':
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }

  String _statusLabel(String status) {
    const labels = {
      'active': 'Active',
      'trial': 'Trial',
      'suspended': 'Suspended',
      'onboarding': 'Onboarding',
      'archived': 'Archived',
    };
    return labels[status] ?? (status.isEmpty ? status : status[0].toUpperCase() + status.substring(1));
  }

  void _applyFilters() {
    setState(() {
      _planFilter = _pendingPlan;
      _boardFilter = _pendingBoard;
      _stateFilter = _pendingState;
    });
  }

  // -- Confirm dialogs — copy taken verbatim from the web ConfirmDialog ------
  Future<void> _showConfirm(BuildContext context, String type, String schoolName) async {
    final Map<String, ({String title, String body, String confirmLabel, Color color})> copy = {
      'suspend': (
        title: 'Suspend school?',
        body: '$schoolName will be suspended immediately — all users will lose access.',
        confirmLabel: 'Yes, suspend',
        color: AppColors.dangerRed,
      ),
      'archive': (
        title: 'Archive school?',
        body:
            '$schoolName will be archived and marked as inactive. Users from this school may lose access to the platform, but historical data will be preserved.',
        confirmLabel: 'Yes, archive',
        color: AppColors.dangerRed,
      ),
      'restore': (
        title: 'Restore school?',
        body:
            '$schoolName will be restored and reactivated. Users and administrators may regain access based on their previous permissions.',
        confirmLabel: 'Yes, restore',
        color: const Color(0xFF059669),
      ),
      'permanent_delete': (
        title: 'Permanently delete school?',
        body:
            '$schoolName and all associated data will be permanently deleted. This action cannot be undone.',
        confirmLabel: 'Yes, delete permanently',
        color: AppColors.dangerRed,
      ),
    };
    final c = copy[type]!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(c.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(c.confirmLabel, style: TextStyle(color: c.color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${c.confirmLabel} — $schoolName (not yet wired to a live API).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unfiltered stats mirror the web's independent `globalStats` fetch.
    final allSchools = SchoolTenancyLocalData.getSchools().results;
    final activeCount = allSchools.where((s) => !['archived', 'suspended'].contains(s.status)).length;
    final trialCount = allSchools
        .where((s) => s.plan == 'trial' && !['archived', 'suspended'].contains(s.status))
        .length;
    final attnCount = allSchools.where((s) => s.status == 'suspended').length;
    final archivedCount = allSchools.where((s) => s.status == 'archived').length;

    final schools = ref.watch(schoolsProvider);
    final rows = schools.results.where((s) {
      if (_statusFilter != 'all' && s.status != _statusFilter) return false;
      if (_planFilter.isNotEmpty && s.plan != _planFilter) return false;
      if (_boardFilter.isNotEmpty && s.board != _boardFilter) return false;
      if (_stateFilter.isNotEmpty && s.state != _stateCodeToName[_stateFilter]) return false;
      return true;
    }).toList();

    final totalStudents = rows.fold<int>(0, (a, s) => a + s.students);
    final totalActiveStudents = rows.fold<int>(0, (a, s) => a + s.activeStudents);
    final totalInactiveStudents = totalStudents - totalActiveStudents;
    final totalStaff = rows.fold<int>(0, (a, s) => a + s.staff);

    final activeFilterCount = [
      _searchController.text,
      _planFilter,
      _boardFilter,
      _stateFilter,
      (_statusFilter != 'all' && _statusFilter != 'active') ? _statusFilter : '',
    ].where((v) => v.isNotEmpty).length;

    return SchoolTenancyLayout(
      currentPath: '/super-admin/schools',
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PAGE HEADER
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text('School', style: AppTextStyles.pageTitle),
                          Text('Management', style: AppTextStyles.pageTitleAccent),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: AppTextStyles.pageSubtitle,
                          children: [
                            const TextSpan(text: 'Provision, monitor & manage every school tenant. · Each school has its own '),
                            const TextSpan(
                              text: 'tenant ID',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const TextSpan(text: ', GSTIN, dedicated DB shard & zero cross-tenant visibility.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _accAddOpen = true),
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

                // KPI GRID (2x2) — content-driven Row+Expanded, not a fixed aspect ratio.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InlineKpiCard(
                          label: 'Total Schools',
                          value: '${allSchools.length}',
                          valueFontSize: 32,
                          sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                          sparklineColor: const Color(0xFF5836E0),
                          trend: '+3 QoQ',
                          trendColor: AppColors.successGreen,
                          footnote: 'Telangana & Andhra Pradesh',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InlineKpiCard(
                          label: 'Active Tenants',
                          value: '$activeCount',
                          valueFontSize: 32,
                          sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                          sparklineColor: const Color(0xFF0E9F6E),
                          trend: 'Healthy',
                          trendColor: AppColors.successGreen,
                          footnote:
                              '${_formatIndian(allSchools.fold<int>(0, (a, s) => a + s.students))} enrolled · ${_formatIndian(allSchools.fold<int>(0, (a, s) => a + s.activeStudents))} active',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InlineKpiCard(
                          label: 'On Trial',
                          value: '$trialCount',
                          valueFontSize: 32,
                          sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                          sparklineColor: const Color(0xFFA65D08),
                          trend: 'Avg conv 68%',
                          trendColor: AppColors.successGreen,
                          footnote: 'Trial-to-paid conversion',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InlineKpiCard(
                          label: 'Needs Attention',
                          value: '$attnCount',
                          valueFontSize: 32,
                          sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                          sparklineColor: const Color(0xFFE0463A),
                          trend: attnCount > 0 ? '$attnCount suspended' : 'All clear',
                          trendColor: attnCount > 0 ? AppColors.dangerRed : AppColors.textTertiary,
                          footnote: 'Open across tenants',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── ACCORDION 01 — ADD SCHOOL (stub) ─────────────────────────
                _accordionShell(
                  num: '01',
                  icon: Icons.add,
                  title: 'Add a new school',
                  subtitle: 'Provisions a new isolated tenant · 8 sections · Identity, branding, contacts, GST, plan & data residency',
                  meta: _metaChip('Auto-generates tenant ID', indigo: true),
                  open: _accAddOpen,
                  featured: true,
                  onToggle: () => setState(() => _accAddOpen = !_accAddOpen),
                  body: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.purpleTint,
                        border: Border.all(color: AppColors.purpleSoft),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.primaryPurple),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The full provisioning wizard (identity, branding, GST, plan & data residency) needs auth/API integration and is coming in a follow-up pass.',
                              style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── ACCORDION 02 — SMART FILTERS ─────────────────────────────
                _accordionShell(
                  num: '02',
                  icon: Icons.filter_alt_outlined,
                  title: 'Smart filters',
                  subtitle: 'Find schools by status, plan, board, region & billing health',
                  meta: activeFilterCount > 0 ? _metaChip('$activeFilterCount active', indigo: true) : null,
                  open: _accFiltersOpen,
                  onToggle: () => setState(() => _accFiltersOpen = !_accFiltersOpen),
                  body: _buildSmartFiltersBody(),
                ),

                const SizedBox(height: 14),

                // ── ACCORDION 03 — SCHOOLS LIST ──────────────────────────────
                _accordionShell(
                  num: '03',
                  icon: Icons.groups_outlined,
                  title: 'Schools list',
                  subtitle: '${rows.length} of ${allSchools.length} shown · sorted by last activity',
                  meta: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _metaChip('${_formatIndian(totalStudents)} students', ok: true),
                      if (totalActiveStudents > 0 && totalActiveStudents < totalStudents) ...[
                        _metaChip('${_formatIndian(totalActiveStudents)} active', ok: true),
                        _metaChip('${_formatIndian(totalInactiveStudents)} inactive'),
                      ],
                      _metaChip('${_formatIndian(totalStaff)} staff', info: true),
                    ],
                  ),
                  open: _accListOpen,
                  onToggle: () => setState(() => _accListOpen = !_accListOpen),
                  body: _buildSchoolsListBody(context, rows, allSchools.length, activeCount, trialCount, attnCount, archivedCount),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable numbered Accordion shell (matches web `<Accordion>`) ─────────
  Widget _accordionShell({
    required String num,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? meta,
    required bool open,
    required VoidCallback onToggle,
    required Widget body,
    bool featured = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: featured ? AppColors.purpleSoft : (open ? AppColors.borderSecondary : AppColors.borderPrimary)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: open ? AppColors.purpleSoft : AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('[$num]',
                            style: AppTextStyles.numberedBadge.copyWith(color: open ? AppColors.purpleDeep : AppColors.textTertiary)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: featured ? AppColors.primaryPurple : AppColors.purpleSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 16, color: featured ? Colors.white : AppColors.purpleDeep),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppTextStyles.accordionTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(subtitle, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 22, color: open ? AppColors.textPrimary : AppColors.textTertiary),
                    ],
                  ),
                  // Meta (chip / counts) gets its own line below the title so it
                  // never squeezes the Expanded title column to near-zero width
                  // at narrow phone widths (this previously caused a RenderFlex
                  // overflow — see teamcontextfile.md).
                  if (meta != null) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 56), // aligns under the title, past badge+icon
                      child: meta,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (open)
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: body,
            ),
        ],
      ),
    );
  }

  Widget _metaChip(String label, {bool indigo = false, bool ok = false, bool info = false}) {
    Color bg = AppColors.bgSecondary, fg = AppColors.textSecondary;
    if (indigo) {
      bg = AppColors.purpleSoft;
      fg = AppColors.purpleDeep;
    } else if (ok) {
      bg = AppColors.greenSoft;
      fg = const Color(0xFF0D7A55);
    } else if (info) {
      bg = AppColors.blueSoft;
      fg = AppColors.infoBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ── Accordion 02 body: Search, Plan, Board, State, Region, Status, Health flags, Saved presets ──
  Widget _buildSmartFiltersBody() {
    final filters = ref.watch(schoolsFiltersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search', style: AppTextStyles.sectionSubtitle.copyWith(fontWeight: FontWeight.w600, fontSize: 11.5)),
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          onChanged: (v) {
            ref.read(schoolsFiltersProvider.notifier).state = filters.copyWith(search: v);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Name, tenant ID, GSTIN, UDISE, owner email…',
            hintStyle: AppTextStyles.sectionSubtitle,
            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
            isDense: true,
            filled: true,
            fillColor: AppColors.bgPrimary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppColors.borderSecondary)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppColors.borderSecondary)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _labeledDropdown('Plan', _pendingPlan, const [
                ['', 'All plans'],
                ['trial', 'Trial'],
                ['starter', 'Starter'],
                ['standard', 'Standard'],
                ['premium', 'Premium'],
                ['enterprise', 'Enterprise'],
              ], (v) => setState(() => _pendingPlan = v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _labeledDropdown('Board', _pendingBoard, const [
                ['', 'All boards'],
                ['CBSE', 'CBSE'],
                ['ICSE', 'ICSE'],
                ['SSC_TG', 'SSC TG'],
                ['SSC_AP', 'SSC AP'],
                ['OTHER', 'Other'],
              ], (v) => setState(() => _pendingBoard = v)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _labeledDropdown('State', _pendingState, const [
                ['', 'All states'],
                ['36', 'Telangana (36)'],
                ['37', 'Andhra Pradesh (37)'],
              ], (v) => setState(() => _pendingState = v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _labeledDropdown('Region', _regionValue, const [
                ['', 'All regions'],
                ['ap-south-1', 'ap-south-1 Mumbai'],
                ['ap-south-2', 'ap-south-2 Hyderabad'],
              ], (v) => setState(() => _regionValue = v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('STATUS', style: AppTextStyles.sectionSubtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FilterPill(label: 'All', count: _globalStatCache.total, isSelected: _statusFilter == 'all', onTap: () => setState(() => _statusFilter = 'all')),
            FilterPill(label: 'Active', count: _globalStatCache.active, isSelected: _statusFilter == 'active', onTap: () => setState(() => _statusFilter = 'active')),
            FilterPill(label: 'Trial', count: _globalStatCache.trial, isSelected: _statusFilter == 'trial', onTap: () => setState(() => _statusFilter = 'trial')),
            FilterPill(label: 'Suspended', count: _globalStatCache.suspended, isSelected: _statusFilter == 'suspended', onTap: () => setState(() => _statusFilter = 'suspended')),
            FilterPill(label: 'Archived', count: _globalStatCache.archived, isSelected: _statusFilter == 'archived', onTap: () => setState(() => _statusFilter = 'archived')),
          ],
        ),
        const SizedBox(height: 16),
        Text('HEALTH FLAGS', style: AppTextStyles.sectionSubtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FilterPill(label: 'Billing overdue', count: 1, isSelected: false, onTap: () {}),
            FilterPill(label: 'Storage 80%+', count: 2, isSelected: false, onTap: () {}),
            FilterPill(label: 'Trial ending <7d', count: 1, isSelected: false, onTap: () {}),
            FilterPill(label: 'GSTIN missing', count: 2, isSelected: false, onTap: () {}),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.borderSecondary),
        const SizedBox(height: 14),
        Text('SAVED PRESETS', style: AppTextStyles.sectionSubtitle.copyWith(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FilterPill(label: 'All active Telangana', isSelected: false, onTap: () {}),
            FilterPill(label: 'Trial → conversion review', isSelected: false, onTap: () {}),
            FilterPill(label: 'GSTIN missing', isSelected: false, onTap: () {}),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderSecondary, style: BorderStyle.solid),
                foregroundColor: AppColors.purpleDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('+ Save current'),
            ),
            ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                minimumSize: Size.zero,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }

  // Cached unfiltered global stats — read once per build via a getter so the
  // Smart Filters status pills (built inside a helper method) can access them.
  ({int total, int active, int trial, int suspended, int archived}) get _globalStatCache {
    final all = SchoolTenancyLocalData.getSchools().results;
    return (
      total: all.length,
      active: all.where((s) => !['archived', 'suspended'].contains(s.status)).length,
      trial: all.where((s) => s.plan == 'trial' && !['archived', 'suspended'].contains(s.status)).length,
      suspended: all.where((s) => s.status == 'suspended').length,
      archived: all.where((s) => s.status == 'archived').length,
    );
  }

  Widget _labeledDropdown(String label, String value, List<List<String>> options, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontWeight: FontWeight.w600, fontSize: 11.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSecondary),
            borderRadius: BorderRadius.circular(9),
            color: AppColors.bgPrimary,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              isDense: true,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
              items: options.map((o) => DropdownMenuItem(value: o[0], child: Text(o[1], overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => onChanged(v ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  // ── Accordion 03 body: status quick tabs, active-filter + Export/Refresh, table ──
  Widget _buildSchoolsListBody(
    BuildContext context,
    List<SchoolEntity> rows,
    int totalCount,
    int activeCount,
    int trialCount,
    int attnCount,
    int archivedCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _statusTab('All', totalCount, 'all'),
            _statusTab('Active', activeCount, 'active'),
            _statusTab('Trial', trialCount, 'trial'),
            _statusTab('Suspended', attnCount, 'suspended'),
            _statusTab('Archived', archivedCount, 'archived'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 12.5), children: [
                  const TextSpan(text: 'Active filter: '),
                  TextSpan(
                    text: _statusFilter == 'all' ? 'All · Active' : _statusLabel(_statusFilter),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.purpleDeep),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 12),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                minimumSize: Size.zero,
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, size: 12),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Text('No schools found', style: AppTextStyles.boardLabel),
                  const SizedBox(height: 4),
                  Text('Try adjusting the filters above or add a new school above.', style: AppTextStyles.sectionSubtitle, textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          _buildSchoolsTable(context, rows),
      ],
    );
  }

  Widget _statusTab(String label, int count, String value) {
    final active = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryPurple : AppColors.bgPrimary,
          border: active ? null : Border.all(color: AppColors.borderSecondary),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary)),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: active ? Colors.white.withValues(alpha: 0.2) : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // Column widths (dp) — mirrors the web schools table's exact column order:
  // School, Tenant · State, Board, GSTIN, Plan · Students, Status, Actions.
  static const double _colSchool = 190;
  static const double _colTenant = 110;
  static const double _colBoard = 96;
  static const double _colGstin = 130;
  static const double _colPlan = 110;
  static const double _colStatus = 110;
  static const double _colActions = 190;
  static const double _colGap = 12;

  Widget _buildSchoolsTable(BuildContext context, List<SchoolEntity> rows) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            _schoolsHeaderRow(),
            for (final s in rows) _schoolsDataRow(context, s),
          ],
        ),
      ),
    );
  }

  Widget _schoolsHeaderRow() {
    final headStyle = const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4);
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: _colSchool, child: Text('SCHOOL', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colTenant, child: Text('TENANT · STATE', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colBoard, child: Text('BOARD', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colGstin, child: Text('GSTIN', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colPlan, child: Text('PLAN · STUDENTS', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colStatus, child: Text('STATUS', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colActions, child: Text('ACTIONS', style: headStyle)),
        ],
      ),
    );
  }

  Widget _schoolsDataRow(BuildContext context, SchoolEntity school) {
    final gradient = _avatarGradient(school.tenantId);
    final isArchived = school.status == 'archived';

    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // School
          SizedBox(
            width: _colSchool,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(child: Text(_initials(school.name), style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(school.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.accordionTitle.copyWith(fontSize: 12.5)),
                      Text('${school.subdomainUrl}.eskoolia.com',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.accordionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 10.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _colGap),
          // Tenant · State
          SizedBox(
            width: _colTenant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(school.tenantId, style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(school.state ?? school.shardRegion, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: _colGap),
          // Board
          SizedBox(
            width: _colBoard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoardChip(label: _boardLabel(school.board), color: AppColors.getBoardColor(school.board)),
                if (school.udiseCode != null) ...[
                  const SizedBox(height: 3),
                  Text(school.udiseCode!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: AppColors.textTertiary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: _colGap),
          // GSTIN
          SizedBox(
            width: _colGstin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school.gstin ?? 'Unregistered',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontFamily: school.gstin != null ? 'monospace' : null, color: school.gstin != null ? AppColors.textPrimary : AppColors.textQuaternary),
                ),
                if (school.pan != null)
                  Text('PAN ${school.pan}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: _colGap),
          // Plan · Students
          SizedBox(
            width: _colPlan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoardChip(label: _planLabel(school.plan), color: AppColors.getPlanColor(school.plan)),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: _formatIndian(school.students), style: AppTextStyles.boardCount.copyWith(fontSize: 13)),
                    TextSpan(text: ' / ${_formatIndian(school.seats)}', style: AppTextStyles.boardPercentage.copyWith(fontSize: 10)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: _colGap),
          // Status
          SizedBox(
            width: _colStatus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusDotColor(school.status), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(_statusLabel(school.status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusDotColor(school.status))),
                  ],
                ),
                if (school.lastActivity != null)
                  Text(school.lastActivity!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: _colGap),
          // Actions
          SizedBox(
            width: _colActions,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: isArchived
                  ? [
                      _iconAction(Icons.open_in_new, 'Open', () => _openSchool(context, school)),
                      _iconAction(Icons.restore, 'Restore', () => _showConfirm(context, 'restore', school.name)),
                      _iconAction(Icons.description_outlined, 'Audit Logs', () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opens ${school.tenantId} audit logs.')));
                      }),
                      _iconAction(Icons.delete_outline, 'Delete', () => _showConfirm(context, 'permanent_delete', school.name)),
                    ]
                  : [
                      _iconAction(Icons.open_in_new, 'Open', () => _openSchool(context, school)),
                      _iconAction(Icons.edit_outlined, 'Edit', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit school — provisioning wizard coming in a follow-up pass.')),
                        );
                      }),
                      _iconAction(Icons.people_outline, 'Impersonate', () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impersonating ${school.name} (not yet wired to a live API).')));
                      }),
                      _iconAction(Icons.pause_circle_outline, 'Suspend', () => _showConfirm(context, 'suspend', school.name)),
                      _iconAction(Icons.archive_outlined, 'Archive', () => _showConfirm(context, 'archive', school.name)),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, size: 13, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  void _openSchool(BuildContext context, SchoolEntity school) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('https://${school.subdomainUrl}.eskoolia.com')),
    );
  }
}
