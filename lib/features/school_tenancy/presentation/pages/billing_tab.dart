import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/status_chip_widget.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Billing Page
/// Exact conversion of web frontend billing structure
class SuperAdminBillingPage extends ConsumerWidget {
  const SuperAdminBillingPage({super.key});

  String _formatINR(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.successGreen;
      case 'pending':
        return AppColors.warningAmber;
      case 'overdue':
        return AppColors.dangerRed;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingProvider);

    // Calculate MRR
    final currentMrr = billingState.invoices
        .where((i) => i.status.toLowerCase() == 'paid')
        .fold(0.0, (sum, i) => sum + i.amount);

    return SchoolTenancyLayout(
      currentPath: '/super-admin/billing',
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
                        Text('Billing', style: AppTextStyles.pageTitle),
                        Text('& Revenue', style: AppTextStyles.pageTitleAccent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.pageSubtitle,
                        children: const [
                          TextSpan(text: 'Invoicing, GST compliance & plan management · '),
                          TextSpan(
                            text: 'GST-compliant',
                            style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                          TextSpan(text: ' invoices with CGST/SGST/IGST breakdowns · GSTR-1 export ready.'),
                        ],
                      ),
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
                          label: const Text('New invoice'),
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
                childAspectRatio: 1.1,
                children: [
                  KpiCard(
                    label: 'Current MRR',
                    value: _formatINR(currentMrr),
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0369A1),
                    trend: '+${(8.3).toStringAsFixed(1)}%',
                    trendColor: AppColors.successGreen,
                    footnote: 'Month-over-month',
                  ),
                  KpiCard(
                    label: 'Outstanding',
                    value: _formatINR(50000),
                    sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                    sparklineColor: const Color(0xFFE0463A),
                    trend: '3 overdue',
                    trendColor: AppColors.dangerRed,
                    footnote: 'Unpaid invoices',
                  ),
                  KpiCard(
                    label: 'Collected YTD',
                    value: _formatINR(1250000),
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0E9F6E),
                    trend: 'On track',
                    trendColor: AppColors.successGreen,
                    footnote: 'Year to date',
                  ),
                  KpiCard(
                    label: 'GST Collected',
                    value: _formatINR(225000),
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFFA65D08),
                    trend: '18% rate',
                    trendColor: AppColors.warningAmber,
                    footnote: 'This month',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // RECENT INVOICES
              Text('Recent invoices', style: AppTextStyles.sectionTitle),
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
                  itemCount: billingState.invoices.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderPrimary),
                  itemBuilder: (context, index) {
                    final invoice = billingState.invoices[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      title: Text(
                        invoice.invoiceNumber,
                        style: AppTextStyles.boardLabel.copyWith(fontFamily: 'monospace'),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            invoice.schoolName,
                            style: AppTextStyles.sectionSubtitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due ${_formatDate(invoice.dueDate)}',
                            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatINR(invoice.amount),
                            style: AppTextStyles.boardCount.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          StatusChip(
                            label: invoice.status[0].toUpperCase() + invoice.status.substring(1),
                            color: _getStatusColor(invoice.status),
                            showDot: true,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // PLANS
              Text('Subscription plans', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.9,
                children: [
                  _buildPlanCard('Starter', '₹5,000', '/month', false),
                  _buildPlanCard('Standard', '₹12,000', '/month', true),
                  _buildPlanCard('Premium', '₹25,000', '/month', false),
                  _buildPlanCard('Enterprise', 'Custom', 'pricing', false),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPlanCard(String name, String price, String period, bool popular) {
    return Container(
      decoration: BoxDecoration(
        color: popular ? AppColors.purpleTint : AppColors.bgPrimary,
        border: Border.all(
          color: popular ? AppColors.primaryPurple : AppColors.borderPrimary,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (popular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'POPULAR',
                style: AppTextStyles.chipLabel(color: Colors.white).copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          if (popular) const SizedBox(height: 12),
          Text(
            name,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: AppTextStyles.kpiValue.copyWith(fontSize: 28),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  period,
                  style: AppTextStyles.sectionSubtitle,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: popular ? AppColors.primaryPurple : AppColors.borderPrimary,
                ),
                foregroundColor: popular ? AppColors.primaryPurple : AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View details'),
            ),
          ),
        ],
      ),
    );
  }
}
