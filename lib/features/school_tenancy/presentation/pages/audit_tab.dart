import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/action_badge_widget.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Audit Log Page
/// Exact conversion of web frontend audit structure
class SuperAdminAuditPage extends ConsumerStatefulWidget {
  const SuperAdminAuditPage({super.key});

  @override
  ConsumerState<SuperAdminAuditPage> createState() => _SuperAdminAuditPageState();
}

class _SuperAdminAuditPageState extends ConsumerState<SuperAdminAuditPage> {
  String _searchQuery = '';
  String _severityFilter = 'all';

  String _relativeTime(String timestamp) {
    final diff = DateTime.now().difference(DateTime.parse(timestamp));
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditProvider);

    // Calculate stats
    final criticalCount = auditState.events
        .where((e) => e.severity.toLowerCase() == 'critical' || e.severity.toLowerCase() == 'error')
        .length;
    final uniqueActors = auditState.events.map((e) => e.actor).toSet().length;
    final last24h = auditState.events
        .where((e) => DateTime.now().difference(DateTime.parse(e.timestamp)).inHours < 24)
        .length;

    // Apply filters
    final filteredEvents = auditState.events.where((event) {
      final matchesSearch = _searchQuery.isEmpty ||
          event.actor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.action.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.detail.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesSeverity = _severityFilter == 'all' ||
          (_severityFilter == 'critical' && (event.severity.toLowerCase() == 'critical' || event.severity.toLowerCase() == 'error')) ||
          (_severityFilter == 'warning' && event.severity.toLowerCase() == 'warning') ||
          (_severityFilter == 'info' && event.severity.toLowerCase() == 'info');

      return matchesSearch && matchesSeverity;
    }).toList();

    return SchoolTenancyLayout(
      currentPath: '/super-admin/audit',
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
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: AppTextStyles.buttonSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download, size: 14),
                          label: const Text('Export CSV'),
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

              // KPI CARDS
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  KpiCard(
                    label: 'Total Events',
                    value: '${auditState.events.length}',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF5836E0),
                    trend: 'in loaded window',
                    trendColor: AppColors.textTertiary,
                    footnote: 'All events',
                  ),
                  KpiCard(
                    label: 'Critical / Error',
                    value: '$criticalCount',
                    sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                    sparklineColor: const Color(0xFFE0463A),
                    trend: 'failed actions',
                    trendColor: AppColors.dangerRed,
                    footnote: 'High severity',
                  ),
                  KpiCard(
                    label: 'Unique Actors',
                    value: '$uniqueActors',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0369A1),
                    trend: 'distinct users',
                    trendColor: AppColors.infoBlue,
                    footnote: 'All actors',
                  ),
                  KpiCard(
                    label: 'Last 24 Hours',
                    value: '$last24h',
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
                onChanged: (value) => setState(() => _searchQuery = value),
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

              // FILTER BUTTONS
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterButton('All', 'all'),
                  _buildFilterButton('Critical', 'critical'),
                  _buildFilterButton('Warning', 'warning'),
                  _buildFilterButton('Info', 'info'),
                ],
              ),

              const SizedBox(height: 20),

              // EVENTS LIST
              Text(
                'Events (${filteredEvents.length})',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border.all(color: AppColors.borderPrimary),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderPrimary),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action badge and timestamp
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ActionBadge(
                                action: event.action,
                                color: AppColors.primaryPurple,
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

                          if (event.schoolName != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.business_outlined, size: 14, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  event.schoolName!,
                                  style: AppTextStyles.sectionSubtitle,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _severityFilter == value;
    return OutlinedButton(
      onPressed: () => setState(() => _severityFilter = value),
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
}
