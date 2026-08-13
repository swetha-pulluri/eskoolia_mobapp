import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/progress_bar_widget.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Client-side CSV from the already-loaded dashboard snapshot — mirrors
/// web's own `exportDashboardCsv()` exactly (`dashboard/page.tsx`), which
/// is itself purely client-side (no backend export endpoint for this).
///
/// Uses the app-wide `saveBytesForDownload` helper (already the convention
/// for every other export in this app — Fee Year-End reports, Student
/// list) instead of `file_picker`'s `saveFile()`: on web that call throws
/// `UnimplementedError` (file_picker has no web "save with bytes"
/// implementation), and on mobile it opens an interactive native
/// "Save As" dialog — exactly the popup the user does not want. The shared
/// helper instead does a zero-dialog Blob+anchor-click browser download on
/// web (matching the real web app's own `<a download>` mechanism exactly).
Future<void> _exportDashboardCsv(BuildContext context, DashboardEntity d) async {
  try {
    final rows = [
      ['Metric', 'Value'],
      ['Total Schools', d.totalSchools],
      ['Active Schools', d.activeSchools],
      ['Total Students', d.totalStudents],
      ['Active Students', d.activeStudents],
      ['Inactive Students', d.inactiveStudents],
      ['Total Staff', d.totalStaff],
      ['MRR (INR)', d.mrr.current],
      ['MRR Trend (%)', d.mrr.trend],
      ['Alert Count', d.alertCount],
      ['Overdue Invoices', d.overdueCount],
      ['Blocked Tenants', d.blockedCount],
    ];
    final csv = rows.map((r) => r.map((c) => '"$c"').join(',')).join('\n');
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await saveBytesForDownload(
      bytes: bytes,
      filename: 'eskoolia-dashboard-${DateTime.now().toIso8601String().split('T').first}.csv',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard exported.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dashboard export failed: $e')),
      );
    }
  }
}

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
    final dashboardAsync = ref.watch(schoolTenancyDashboardProvider);

    if (dashboardAsync.isLoading && !dashboardAsync.hasValue) {
      return const SchoolTenancyLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (dashboardAsync.hasError && !dashboardAsync.hasValue) {
      return SchoolTenancyLayout(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load dashboard data.\n${dashboardAsync.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageSubtitle,
            ),
          ),
        ),
      );
    }

    final dashboard = dashboardAsync.value!;

    // Matches web's `effectiveMrr`/`mrrTrend` fallbacks (see
    // super-admin/dashboard/page.tsx): when there's no current-month invoice
    // MRR yet, fall back to the sum of plan MRR; render "—" instead of "0.0%"
    // when there's no month-over-month trend to show.
    final planMrrTotal = dashboard.planBreakdown.fold<double>(0.0, (sum, p) => sum + p.mrr);
    final effectiveMrr = dashboard.mrr.current > 0 ? dashboard.mrr.current : planMrrTotal;
    final mrrTrendText = dashboard.mrr.trend != 0
        ? '${dashboard.mrr.trend > 0 ? '+' : ''}${dashboard.mrr.trend.toStringAsFixed(1)}%'
        : '—';

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
                    // `Wrap` (not a bare `Row`) — a plain Row of 3 buttons
                    // has no way to give way on a narrow screen, so
                    // "Add school" (the 3rd/rightmost button) could be
                    // pushed off-screen/clipped entirely on smaller phones.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: dashboardAsync.isLoading
                              ? null
                              : () => ref.invalidate(schoolTenancyDashboardProvider),
                          icon: dashboardAsync.isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
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
                          onPressed: () => _exportDashboardCsv(context, dashboard),
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
                          // Matches web's `router.push('/super-admin/schools?add=1')`
                          // (dashboard/page.tsx) — `?add=1` tells the Schools
                          // page to auto-open its "Add a new school" accordion
                          // instead of just landing on the plain list.
                          onPressed: () => context.go('/super-admin/schools?add=1'),
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
                spacing: 16,
                cards: [
                  KpiCard(
                    label: 'Total Schools',
                    value: '${dashboard.totalSchools}',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF5836E0),
                    trend: '● ${dashboard.activeSchools} active',
                    trendColor: AppColors.successGreen,
                    footnote: dashboard.stateBreakdown.isNotEmpty
                        ? dashboard.stateBreakdown.map((s) => s.state).join(' · ')
                        : 'Pan-India',
                  ),
                  KpiCard(
                    label: 'Students Served',
                    value: _formatStudents(dashboard.activeStudents),
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0E9F6E),
                    trend: '${dashboard.activeStudents} active',
                    trendColor: AppColors.successGreen,
                    footnote: '${dashboard.totalStudents} total · ${dashboard.totalStaff} staff',
                  ),
                  KpiCard(
                    label: 'Monthly Recurring',
                    value: _formatINR(effectiveMrr),
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0369A1),
                    trend: mrrTrendText,
                    trendColor: AppColors.successGreen,
                    footnote: 'GST collected this month · ${_formatINR(effectiveMrr * 0.18)}',
                  ),
                  KpiCard(
                    label: 'Needs Attention',
                    value: '${dashboard.alertCount}',
                    sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                    sparklineColor: const Color(0xFFE0463A),
                    trend: dashboard.alertCount > 0
                        ? '${dashboard.overdueCount} billing · ${dashboard.blockedCount} blocked'
                        : '— All clear',
                    trendColor: dashboard.alertCount > 0 ? AppColors.dangerRed : AppColors.textTertiary,
                    footnote: 'Open across all tenants',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SCHOOLS BY BOARD
              _buildSectionCard(
                title: 'Schools by board',
                subtitle: 'Affiliation mix across active tenants',
                child: dashboard.boardBreakdown.isEmpty
                    ? _buildEmptyMessage('No schools provisioned yet.')
                    : Column(
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
                child: dashboard.stateBreakdown.isEmpty
                    ? _buildEmptyMessage('No geographic data yet.')
                    : Column(
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
                    '$mrrTrendText MoM',
                    style: AppTextStyles.kpiTrend(color: const Color(0xFF15803D)),
                  ),
                ),
                child: dashboard.planBreakdown.isEmpty
                    ? _buildEmptyMessage('No plan data yet.')
                    : Column(
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
                  onTap: () => context.go('/super-admin/audit'),
                  child: Text(
                    'View all →',
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: dashboard.recentEvents.isEmpty
                    ? _buildEmptyMessage('No recent activity.')
                    : Column(
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

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 13, color: AppColors.textTertiary),
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
              ?trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
