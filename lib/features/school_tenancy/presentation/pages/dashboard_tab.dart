import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/progress_bar_widget.dart';
import '../../../../core/widgets/sparkline_painter.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Dashboard Page
/// Exact conversion of web frontend `/super-admin/dashboard` page.
class SuperAdminDashboardPage extends ConsumerWidget {
  const SuperAdminDashboardPage({super.key});

  // Sparkline point data (matches web <Spark />)
  static const List<double> _sparkUp = [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14];
  static const List<double> _sparkDown = [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4];

  String _formatINR(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatStudents(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  /// Indian digit grouping — mirrors web `toLocaleString('en-IN')`.
  String _formatIndian(int n) {
    final neg = n < 0;
    final digits = n.abs().toString();
    if (digits.length <= 3) return (neg ? '-' : '') + digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${neg ? '-' : ''}${parts.join(',')},$last3';
  }

  String _formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
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

    // Derived values — mirror the web page's computed fields.
    final planMrrTotal =
        dashboard.planBreakdown.fold<double>(0, (sum, p) => sum + p.mrr);
    final effectiveMrr =
        dashboard.mrr.current > 0 ? dashboard.mrr.current : planMrrTotal;
    final gstAmt = (effectiveMrr * 0.18).round();
    final mrrTrend = dashboard.mrr.trend != 0
        ? '${dashboard.mrr.trend > 0 ? '+' : ''}${dashboard.mrr.trend.toStringAsFixed(1)}%'
        : '—';
    final statesLabel = dashboard.stateBreakdown.isNotEmpty
        ? dashboard.stateBreakdown.map((s) => s.state).join(' · ')
        : 'Pan-India';

    return SchoolTenancyLayout(
      currentPath: '/super-admin/dashboard',
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── PAGE HEADER ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text(
                            'Super Admin',
                            style: AppTextStyles.pageTitle
                                .copyWith(color: const Color(0xFF0F1222)),
                          ),
                          Text('Dashboard', style: AppTextStyles.pageTitleAccent),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: AppTextStyles.pageSubtitle,
                          children: [
                            const TextSpan(
                                text:
                                    'Cross-tenant overview of every school on the Eskoolia platform. · '),
                            TextSpan(
                              text: '${dashboard.totalSchools} schools',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text:
                                  '${_formatIndian(dashboard.totalStudents)} students',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                            const TextSpan(
                                text:
                                    ' served across India · GST-compliant billing & full data isolation.'),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              textStyle: AppTextStyles.buttonSecondary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/super-admin/schools'),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Add school'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              textStyle: AppTextStyles.buttonPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── KPI ROW ─────────────────────────────────────────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _kpiCard(
                          label: 'Total Schools',
                          value: '${dashboard.totalSchools}',
                          sparkData: _sparkUp,
                          sparkColor: const Color(0xFF5836E0),
                          trend: _kpiTrendText(
                            '● ${dashboard.activeSchools} active',
                            AppColors.successGreen,
                          ),
                          footnote: statesLabel,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _kpiCard(
                          label: 'Students Served',
                          value: _formatStudents(dashboard.activeStudents),
                          sparkData: _sparkUp,
                          sparkColor: const Color(0xFF0E9F6E),
                          trend: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _studentChip(
                                '${_formatIndian(dashboard.activeStudents)} active',
                                fg: AppColors.successGreen,
                                bg: const Color(0xFFF0FDF4),
                                border: AppColors.greenBorder,
                              ),
                              if (dashboard.inactiveStudents > 0)
                                _studentChip(
                                  '${_formatIndian(dashboard.inactiveStudents)} inactive',
                                  fg: AppColors.textSecondary,
                                  bg: AppColors.bgSecondary,
                                  border: AppColors.borderPrimary,
                                ),
                            ],
                          ),
                          footnote:
                              '${_formatIndian(dashboard.totalStudents)} total · ${dashboard.totalStaff} staff',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _kpiCard(
                          label: 'Monthly Recurring',
                          value: _formatINR(effectiveMrr),
                          sparkData: _sparkUp,
                          sparkColor: const Color(0xFF0369A1),
                          trend: _kpiTrendText(mrrTrend, AppColors.successGreen),
                          footnote:
                              'GST collected this month · ${_formatINR(gstAmt.toDouble())}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _kpiCard(
                          label: 'Needs Attention',
                          value: '${dashboard.alertCount}',
                          sparkData: _sparkDown,
                          sparkColor: const Color(0xFFE0463A),
                          trend: _kpiTrendText(
                            dashboard.alertCount > 0
                                ? '⊙ ${dashboard.overdueCount} billing · ${dashboard.blockedCount} blocked'
                                : '— All clear',
                            dashboard.alertCount > 0
                                ? AppColors.dangerRed
                                : AppColors.textTertiary,
                          ),
                          footnote: 'Open across all tenants',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── SCHOOLS BY BOARD ────────────────────────────────────────
                _buildSectionCard(
                  title: 'Schools by board',
                  subtitle: 'Affiliation mix across active tenants',
                  child: Column(
                    children: [
                      ...dashboard.boardBreakdown.map((board) {
                        final maxBoard = dashboard.boardBreakdown
                            .fold<int>(1, (m, b) => b.count > m ? b.count : m);
                        final pct = board.percent > 0
                            ? board.percent
                            : (board.count / maxBoard) * 100;
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
                                      Text('· ${pct.round()}%',
                                          style: AppTextStyles.boardPercentage),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ProgressBar(
                                value: pct / 100,
                                color: AppColors.getBoardColor(board.board),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (dashboard.boardBreakdown.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        const _DashedDivider(),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: dashboard.boardBreakdown.map((board) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.borderPrimary),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${board.board} · ${board.count}',
                                style: AppTextStyles.chipLabel(
                                        color: AppColors.textSecondary)
                                    .copyWith(fontSize: 11, fontWeight: FontWeight.w400),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── GEOGRAPHIC DISTRIBUTION ─────────────────────────────────
                _buildSectionCard(
                  title: 'Geographic distribution',
                  subtitle: 'Schools by Indian state',
                  child: Column(
                    children: [
                      ...dashboard.stateBreakdown.map((state) {
                        final maxCount = dashboard.stateBreakdown
                            .fold<int>(1, (m, s) => s.count > m ? s.count : m);
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
                                  value: state.count / maxCount,
                                  color: _getStateColor(state.state),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 78,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('${state.count}',
                                        style: AppTextStyles.boardCount),
                                    const SizedBox(width: 3),
                                    Text('· ${_formatStudents(state.students)} st.',
                                        style: AppTextStyles.boardPercentage
                                            .copyWith(fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (dashboard.stateBreakdown.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        const _DashedDivider(),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Place of supply (GST)',
                                style: AppTextStyles.sectionSubtitle),
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

                // ── PLAN REVENUE (MRR) ──────────────────────────────────────
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
                      '$mrrTrend MoM',
                      style: AppTextStyles.kpiTrend(color: const Color(0xFF15803D)),
                    ),
                  ),
                  child: Column(
                    children: [
                      ...dashboard.planBreakdown.map((plan) {
                        final maxMrr = dashboard.planBreakdown
                            .fold<double>(1, (m, p) => p.mrr > m ? p.mrr : m);
                        final barPct = ((plan.mrr / maxMrr) * 100)
                            .clamp(2, 100)
                            .toDouble();
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
                                      Text('· ${plan.count}',
                                          style: AppTextStyles.boardPercentage),
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
                                value: barPct / 100,
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

                // ── RECENT ACTIVITY ─────────────────────────────────────────
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
                  child: Column(
                    children: () {
                      final events = dashboard.recentEvents.take(5).toList();
                      return [
                        for (var i = 0; i < events.length; i++)
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: i < events.length - 1
                                      ? AppColors.bgSecondary
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _formatRelativeTime(
                                          DateTime.parse(events[i].timestamp)),
                                      style: AppTextStyles.relativeTime,
                                    ),
                                  ),
                                ),
                                _buildActivityIcon(
                                    events[i].action, events[i].severity),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_getActionLabel(events[i].action)}${events[i].tenantId != null ? ' · ${events[i].tenantId}' : ''}',
                                        style: AppTextStyles.activityAction,
                                      ),
                                      if (events[i].schoolName != null ||
                                          events[i].detail.isNotEmpty)
                                        Text(
                                          events[i].schoolName ?? events[i].detail,
                                          style: AppTextStyles.activityDetail,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ];
                    }(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── KPI card (matches web card markup) ─────────────────────────────────────
  Widget _kpiCard({
    required String label,
    required String value,
    required List<double> sparkData,
    required Color sparkColor,
    required Widget trend,
    required String footnote,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.kpiLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: 0.65,
                child: SizedBox(
                  width: 56,
                  height: 20,
                  child: CustomPaint(
                    painter: SparklinePainter(
                      data: sparkData,
                      color: sparkColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTextStyles.kpiValue),
          ),
          const SizedBox(height: 8),
          trend,
          const SizedBox(height: 4),
          Text(
            footnote,
            style: AppTextStyles.kpiFootnote,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _kpiTrendText(String text, Color color) {
    return Text(text, style: AppTextStyles.kpiTrend(color: color));
  }

  Widget _studentChip(String text,
      {required Color fg, required Color bg, required Color border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
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

/// Dashed horizontal rule — matches web `borderTop: '1px dashed #E5E7EB'`.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashGap = 4.0;
    final paint = Paint()
      ..color = AppColors.borderPrimary
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}
