import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/progress_bar_widget.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Dashboard Page
/// Exact conversion of web frontend dashboard structure
class SuperAdminDashboardPage extends ConsumerWidget {
  const SuperAdminDashboardPage({super.key});

  String _formatINR(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatStudents(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _getActionLabel(String action) {
    const labels = {
      'school.provision': 'School provisioned',
      'school.archive': 'School archived',
      'school.update': 'School updated',
      'school.suspend': 'School suspended',
      'school.activate': 'School activated',
      'plan.upgrade': 'Plan upgraded',
      'plan.downgrade': 'Plan downgraded',
      'storage.threshold': 'Storage threshold exceeded',
      'invoice.overdue': 'Invoice overdue',
      'invoice.paid': 'Invoice paid',
      'auth.impersonate': 'Admin impersonation',
      'api_key.rotate': 'API key rotated',
      'backup.complete': 'Backup completed',
      'policy.update': 'Policy updated',
      'provision_failed': 'Provisioning failed',
      'seeding_completed': 'Data seeding completed',
      'migrations_ran': 'Migrations ran',
    };
    return labels[action] ?? action.replaceAll('_', ' ').replaceAll('.', ' · ');
  }

  Widget _buildActivityIcon(String action, String severity) {
    final a = action.toLowerCase();
    final isUpgrade = a.contains('upgrade') || a.contains('plan') || a.contains('migrat');
    final isWarn = severity == 'warning' || a.contains('threshold') || a.contains('storage');
    final isDanger = severity == 'error' || severity == 'critical' || a.contains('overdue') || a.contains('suspend');

    Color bgColor;
    Color iconColor;
    IconData icon;

    if (isDanger) {
      bgColor = AppColors.redSoft;
      iconColor = AppColors.dangerRed;
      icon = Icons.cancel;
    } else if (isWarn) {
      bgColor = AppColors.amberSoft;
      iconColor = AppColors.warningAmber;
      icon = Icons.warning;
    } else if (isUpgrade) {
      bgColor = AppColors.purpleSoft;
      iconColor = AppColors.primaryPurple;
      icon = Icons.mail_outline;
    } else {
      bgColor = AppColors.greenSoft;
      iconColor = AppColors.successGreen;
      icon = Icons.check_circle;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: iconColor),
    );
  }

  Color _getStateColor(String state) {
    const colors = {
      'Telangana': Color(0xFF5836E0),
      'Andhra Pradesh': Color(0xFFA65D08),
      'Karnataka': Color(0xFF0369A1),
      'Tamil Nadu': Color(0xFF059669),
      'Maharashtra': Color(0xFF6D28D9),
      'Delhi': Color(0xFFDC2626),
    };
    return colors[state] ?? AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(schoolTenancyDashboardProvider);

    return SchoolTenancyLayout(
      currentPath: '/super-admin/dashboard',
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
                        Text('Super Admin', style: AppTextStyles.pageTitle),
                        Text('Dashboard', style: AppTextStyles.pageTitleAccent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.pageSubtitle,
                        children: [
                          const TextSpan(text: 'Cross-tenant overview of every school on the Eskoolia platform. · '),
                          TextSpan(
                            text: '${dashboard.totalSchools} schools',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const TextSpan(text: ' · '),
                          TextSpan(
                            text: '${dashboard.totalStudents.toStringAsFixed(0)} students',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const TextSpan(text: ' served across India · GST-compliant billing & full data isolation.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  KpiCard(
                    label: 'Total Schools',
                    value: '${dashboard.totalSchools}',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF5836E0),
                    trend: '● ${dashboard.activeSchools} active',
                    trendColor: AppColors.successGreen,
                    footnote: 'Pan-India',
                  ),
                  KpiCard(
                    label: 'Students Served',
                    value: _formatStudents(dashboard.activeStudents),
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0E9F6E),
                    trend: '${dashboard.activeStudents} active',
                    trendColor: AppColors.successGreen,
                    footnote: '${dashboard.totalStaff} staff',
                  ),
                  KpiCard(
                    label: 'Monthly Recurring',
                    value: _formatINR(dashboard.mrr.current),
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0369A1),
                    trend: '${dashboard.mrr.trend.toStringAsFixed(1)}%',
                    trendColor: AppColors.successGreen,
                    footnote: 'GST collected · ${_formatINR(dashboard.mrr.current * 0.18)}',
                  ),
                  KpiCard(
                    label: 'Needs Attention',
                    value: '${dashboard.alertCount}',
                    sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                    sparklineColor: const Color(0xFFE0463A),
                    trend: '— All clear',
                    trendColor: AppColors.textTertiary,
                    footnote: 'Open across all tenants',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SCHOOLS BY BOARD
              _buildSectionCard(
                title: 'Schools by board',
                subtitle: 'Affiliation mix across active tenants',
                child: Column(
                  children: [
                    ...dashboard.boardBreakdown.map((board) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.getBoardColor(board.board),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(board.board, style: AppTextStyles.boardLabel),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('${board.count}', style: AppTextStyles.boardCount),
                                    const SizedBox(width: 8),
                                    Text('· ${board.percent}%', style: AppTextStyles.boardPercentage),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ProgressBar(
                              value: board.percent / 100,
                              color: AppColors.getBoardColor(board.board),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (dashboard.boardBreakdown.isNotEmpty) ...[
                      const Divider(color: AppColors.borderPrimary, height: 32),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: dashboard.boardBreakdown.map((board) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderPrimary),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${board.board} · ${board.count}',
                              style: AppTextStyles.chipLabel(color: AppColors.textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // GEOGRAPHIC DISTRIBUTION
              _buildSectionCard(
                title: 'Geographic distribution',
                subtitle: 'Schools by Indian state',
                child: Column(
                  children: [
                    ...dashboard.stateBreakdown.map((state) {
                      final maxCount = dashboard.stateBreakdown
                          .fold<int>(0, (max, s) => s.count > max ? s.count : max);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(state.state, style: AppTextStyles.boardLabel),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProgressBar(
                                value: maxCount > 0 ? state.count / maxCount : 0,
                                color: _getStateColor(state.state),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 70,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${state.count}', style: AppTextStyles.boardCount),
                                  const SizedBox(width: 3),
                                  Text('· ${_formatStudents(state.students)} st.', 
                                    style: AppTextStyles.boardPercentage.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (dashboard.stateBreakdown.isNotEmpty) ...[
                      const Divider(color: AppColors.borderPrimary, height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Place of supply (GST)', style: AppTextStyles.sectionSubtitle),
                          Flexible(
                            child: Text(
                              dashboard.stateBreakdown
                                  .map((s) => '${s.code}-${s.state}')
                                  .join(' · '),
                              style: AppTextStyles.sectionSubtitle.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // PLAN REVENUE
              _buildSectionCard(
                title: 'Plan revenue (MRR)',
                subtitle: 'Excluding GST · in INR',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${dashboard.mrr.trend.toStringAsFixed(1)}% MoM',
                    style: AppTextStyles.kpiTrend(color: const Color(0xFF15803D)),
                  ),
                ),
                child: Column(
                  children: [
                    ...dashboard.planBreakdown.map((plan) {
                      final maxMrr = dashboard.planBreakdown
                          .fold<double>(0, (max, p) => p.mrr > max ? p.mrr : max);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(plan.plan, style: AppTextStyles.boardLabel),
                                    const SizedBox(width: 8),
                                    Text('· ${plan.count}', style: AppTextStyles.boardPercentage),
                                  ],
                                ),
                                Text(
                                  plan.mrr > 0 ? _formatINR(plan.mrr) : 'Trial',
                                  style: AppTextStyles.boardCount.copyWith(fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ProgressBar(
                              value: maxMrr > 0 ? plan.mrr / maxMrr : 0,
                              color: AppColors.getPlanColor(plan.plan),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // RECENT ACTIVITY
              _buildSectionCard(
                title: 'Recent activity',
                subtitle: 'Cross-tenant audit events',
                trailing: GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View all →',
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    ...dashboard.recentEvents.take(5).map((event) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                _formatRelativeTime(DateTime.parse(event.timestamp)),
                                style: AppTextStyles.relativeTime,
                              ),
                            ),
                            _buildActivityIcon(event.action, event.severity),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getActionLabel(event.action)}${event.tenantId != null ? ' · ${event.tenantId}' : ''}',
                                    style: AppTextStyles.activityAction,
                                  ),
                                  if (event.schoolName != null || event.detail.isNotEmpty)
                                    Text(
                                      event.schoolName ?? event.detail,
                                      style: AppTextStyles.activityDetail,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.sectionSubtitle),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
