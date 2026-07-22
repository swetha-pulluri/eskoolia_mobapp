import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/filter_pill_widget.dart';
import '../../../../core/widgets/status_chip_widget.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Schools Page
/// Exact conversion of web frontend schools structure
class SuperAdminSchoolsPage extends ConsumerStatefulWidget {
  const SuperAdminSchoolsPage({super.key});

  @override
  ConsumerState<SuperAdminSchoolsPage> createState() => _SuperAdminSchoolsPageState();
}

class _SuperAdminSchoolsPageState extends ConsumerState<SuperAdminSchoolsPage> {
  final Set<String> _expandedSchools = {};
  String _statusFilter = 'active';

  String _formatStudents(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
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

  @override
  Widget build(BuildContext context) {
    final schools = ref.watch(schoolsProvider);

    // Calculate stats
    final activeCount = schools.results.where((s) => s.status == 'active').length;
    final trialCount = schools.results.where((s) => s.plan == 'trial' && s.status != 'archived').length;
    final totalActiveStudents = schools.results.fold(0, (sum, s) => sum + s.activeStudents);

    // Apply status filter
    final filteredSchools = _statusFilter == 'all'
        ? schools.results
        : schools.results.where((s) => s.status == _statusFilter).toList();

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
                          onPressed: () {},
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
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.2,
                children: [
                  KpiCard(
                    label: 'Total Schools',
                    value: '${schools.count}',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF5836E0),
                    trend: '+3 QoQ',
                    trendColor: AppColors.successGreen,
                    footnote: 'Telangana & AP',
                  ),
                  KpiCard(
                    label: 'Active Tenants',
                    value: '$activeCount',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0E9F6E),
                    trend: 'Healthy',
                    trendColor: AppColors.successGreen,
                    footnote: '${_formatStudents(totalActiveStudents)} active students',
                  ),
                  KpiCard(
                    label: 'On Trial',
                    value: '$trialCount',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFFA65D08),
                    trend: 'Avg conv 68%',
                    trendColor: AppColors.warningAmber,
                    footnote: 'Trial-to-paid',
                  ),
                  KpiCard(
                    label: 'Needs Attention',
                    value: '0',
                    sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                    sparklineColor: const Color(0xFFE0463A),
                    trend: 'All clear',
                    trendColor: AppColors.textTertiary,
                    footnote: 'Open across tenants',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // FILTER PILLS
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterPill(
                    label: 'All',
                    count: schools.results.length,
                    isSelected: _statusFilter == 'all',
                    onTap: () => setState(() => _statusFilter = 'all'),
                  ),
                  FilterPill(
                    label: 'Active',
                    count: activeCount,
                    isSelected: _statusFilter == 'active',
                    onTap: () => setState(() => _statusFilter = 'active'),
                  ),
                  FilterPill(
                    label: 'Trial',
                    count: trialCount,
                    isSelected: _statusFilter == 'trial',
                    onTap: () => setState(() => _statusFilter = 'trial'),
                  ),
                  FilterPill(
                    label: 'Suspended',
                    count: 0,
                    isSelected: _statusFilter == 'suspended',
                    onTap: () => setState(() => _statusFilter = 'suspended'),
                  ),
                  FilterPill(
                    label: 'Archived',
                    count: 0,
                    isSelected: _statusFilter == 'archived',
                    onTap: () => setState(() => _statusFilter = 'archived'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SCHOOLS LIST
              Text(
                'Schools (${filteredSchools.length})',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),

              ...filteredSchools.asMap().entries.map((entry) {
                final index = entry.key;
                final school = entry.value;
                final isExpanded = _expandedSchools.contains(school.tenantId);
                final gradient = _getAvatarGradient(school.tenantId);
                final number = (index + 1).toString().padLeft(2, '0');

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
    required school,
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
                            label: school.board,
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
                  // Details grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3,
                    children: [
                      _buildDetailItem('Students', '${school.students}'),
                      _buildDetailItem('Active', '${school.activeStudents}'),
                      _buildDetailItem('Staff', '${school.staff}'),
                      _buildDetailItem('State', school.state),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildActionButton('View ERP', Icons.open_in_new),
                      _buildActionButton('Edit', Icons.edit_outlined),
                      _buildActionButton('Suspend', Icons.pause_circle_outline),
                    ],
                  ),
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

  Widget _buildActionButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 14),
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
