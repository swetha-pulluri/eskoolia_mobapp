import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/inline_kpi_card.dart';
import '../../domain/entities/billing_entity.dart' show InvoiceEntity;
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Billing page — "Tenants & Billing".
/// Converts the web `/super-admin/billing` page (header, KPI row,
/// Subscription plans, Tax invoice preview + Recent invoices table) into a
/// mobile-first layout. The New invoice / New plan drawers are large
/// desktop forms not yet wired to a backend and are intentionally out of
/// scope for this pass; the Tax Invoice preview itself IS implemented below,
/// stacked instead of the desktop's 3-column layout.
class SuperAdminBillingPage extends ConsumerStatefulWidget {
  const SuperAdminBillingPage({super.key});

  @override
  ConsumerState<SuperAdminBillingPage> createState() => _SuperAdminBillingPageState();
}

class _SuperAdminBillingPageState extends ConsumerState<SuperAdminBillingPage> {
  InvoiceEntity? _selected;

  // Eskoolia's registered office is in Bengaluru (Karnataka) per the web
  // Tax Invoice header — used only to classify intra vs inter-state supply.
  static const String _sellerState = 'Karnataka';
  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  String _formatINR(double amount, {bool compact = true}) {
    if (compact) {
      if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
      if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)}L';
      if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}K';
      return '₹${amount.toStringAsFixed(0)}';
    }
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  // Exact web `STATUS_META` (billing/page.tsx) — draft/sent/paid/overdue/cancelled.
  static const Map<String, ({String label, Color color})> _statusMeta = {
    'draft': (label: 'Draft', color: AppColors.textTertiary),
    'sent': (label: 'Sent', color: Color(0xFFB45309)),
    'paid': (label: 'Paid', color: Color(0xFF059669)),
    'overdue': (label: 'Overdue', color: AppColors.dangerRed),
    'cancelled': (label: 'Cancelled', color: AppColors.textTertiary),
  };

  /// Exact web `stateCode()` map (billing/page.tsx) — 2-digit GST state codes.
  static const Map<String, String> _stateCodes = {
    'andhra pradesh': '37',
    'arunachal pradesh': '12',
    'assam': '18',
    'bihar': '10',
    'chhattisgarh': '22',
    'delhi': '07',
    'goa': '30',
    'gujarat': '24',
    'haryana': '06',
    'himachal pradesh': '02',
    'jharkhand': '20',
    'karnataka': '29',
    'kerala': '32',
    'madhya pradesh': '23',
    'maharashtra': '27',
    'odisha': '21',
    'punjab': '03',
    'rajasthan': '08',
    'sikkim': '11',
    'tamil nadu': '33',
    'telangana': '36',
    'tripura': '16',
    'uttar pradesh': '09',
    'uttarakhand': '05',
    'west bengal': '19',
  };

  String _stateCode(String? state) {
    if (state == null) return '';
    return _stateCodes[state.trim().toLowerCase()] ?? '';
  }

  int? _daysOverdue(InvoiceEntity inv) {
    if (inv.status != 'overdue' || inv.dueDate == null) return null;
    final days = DateTime.now().difference(inv.dueDate!).inDays;
    return days < 0 ? 0 : days;
  }

  bool _isInterState(InvoiceEntity inv) => (inv.buyerState ?? '').trim() != _sellerState;

  // Indian-numeral amount-in-words — ports the web `amountInWords()` helper.
  String _amountInWords(double amount) {
    if (amount <= 0) return 'Zero';
    const ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    const teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    String two(int n) {
      if (n < 10) return ones[n];
      if (n < 20) return teens[n - 10];
      final t = n ~/ 10, o = n % 10;
      return '${tens[t]}${o != 0 ? ' ${ones[o]}' : ''}';
    }
    String three(int n) {
      final h = n ~/ 100, r = n % 100;
      return '${h != 0 ? '${ones[h]} Hundred${r != 0 ? ' ' : ''}' : ''}${two(r)}';
    }
    final whole = amount.floor();
    final crore = whole ~/ 10000000;
    final lakh = (whole % 10000000) ~/ 100000;
    final thousand = (whole % 100000) ~/ 1000;
    final rest = whole % 1000;
    var s = '';
    if (crore != 0) s += '${two(crore)} Crore ';
    if (lakh != 0) s += '${two(lakh)} Lakh ';
    if (thousand != 0) s += '${two(thousand)} Thousand ';
    if (rest != 0) s += three(rest);
    s = s.trim();
    if (s.isEmpty) s = 'Zero';
    return 'Indian Rupees $s Only';
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final invoices = billingState.invoices;
    final selected = _selected ?? (invoices.isNotEmpty ? invoices.first : null);

    final paidTotal = invoices.where((i) => i.status == 'paid').fold(0.0, (s, i) => s + i.amount);
    final outstanding = invoices.where((i) => i.status == 'sent' || i.status == 'overdue');
    final outstandingTotal = outstanding.fold(0.0, (s, i) => s + i.amount);
    final gstCollected = paidTotal * 0.18;
    final paidCount = invoices.where((i) => i.status == 'paid').length;

    final now = DateTime.now();
    final monthLabel = _months[now.month - 1];
    final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
    final fyLabel = 'FY $fyStartYear-${(fyStartYear + 1).toString().substring(2)}';

    return SchoolTenancyLayout(
      currentPath: '/super-admin/billing',
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PAGE HEADER — "Tenants & Billing" (32px, single weight, web pattern)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text('Tenants &',
                              style: AppTextStyles.pageTitle.copyWith(fontSize: 30, letterSpacing: -0.5)),
                          Text('Billing', style: AppTextStyles.pageTitleAccent.copyWith(fontSize: 32)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GST-compliant invoicing across all schools. Place of supply auto-detected from '
                        'buyer state code · IGST for inter-state, CGST + SGST for intra-state.',
                        style: AppTextStyles.pageSubtitle,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download, size: 14),
                            label: const Text('Export GSTR-1'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              textStyle: AppTextStyles.buttonSecondary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('New invoice — drawer coming in a follow-up pass.'),
                              ));
                            },
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

                // KPI GRID (2x2) — content-driven Row+Expanded, not a fixed aspect ratio.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InlineKpiCard(
                          label: 'MRR',
                          value: _formatINR(paidTotal),
                          footnote: 'Recurring · pre-GST',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InlineKpiCard(
                          label: 'GST Collected ($monthLabel)',
                          value: _formatINR(gstCollected),
                          footnote: 'Tax collected this cycle',
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
                          label: 'Outstanding',
                          value: _formatINR(outstandingTotal),
                          trend: outstanding.isNotEmpty ? '${outstanding.length} invoice${outstanding.length == 1 ? '' : 's'}' : null,
                          trendColor: AppColors.dangerRed,
                          footnote: 'Open receivables',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InlineKpiCard(
                          label: 'Invoices YTD',
                          value: '${invoices.length}',
                          trend: paidCount > 0 ? '$paidCount paid' : null,
                          trendColor: const Color(0xFF059669),
                          footnote: fyLabel,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SUBSCRIPTION PLANS
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.primaryPurple),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subscription plans', style: AppTextStyles.sectionTitle),
                          Text('India-priced · GST 18% under SAC 998313',
                              style: AppTextStyles.sectionSubtitle, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Add plan — drawer coming in a follow-up pass.'),
                        ));
                      },
                      icon: const Icon(Icons.add, size: 12),
                      label: const Text('Add plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._buildPlanRows(billingState.plans),

                const SizedBox(height: 24),

                // TAX INVOICE PREVIEW (tap a row below to preview it here)
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.description_outlined, size: 16, color: AppColors.primaryPurple),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tax invoice', style: AppTextStyles.sectionTitle),
                          Text('Tap a row in Recent invoices to preview it here',
                              style: AppTextStyles.sectionSubtitle, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTaxInvoiceSection(context, selected),

                const SizedBox(height: 24),

                // RECENT INVOICES
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recent invoices', style: AppTextStyles.sectionTitle),
                          Text('${invoices.length} invoices · $fyLabel', style: AppTextStyles.sectionSubtitle),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 12),
                      label: const Text('Export'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildInvoicesTable(context, invoices, selected),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlanRows(List<dynamic> plans) {
    final rows = <Widget>[];
    for (var i = 0; i < plans.length; i += 2) {
      final hasSecond = i + 1 < plans.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildPlanCard(plans[i])),
              if (hasSecond) ...[
                const SizedBox(width: 12),
                Expanded(child: _buildPlanCard(plans[i + 1])),
              ] else
                const Spacer(),
            ],
          ),
        ),
      );
      if (i + 2 < plans.length) rows.add(const SizedBox(height: 12));
    }
    return rows;
  }

  Widget _buildPlanCard(dynamic plan) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(plan.name.toString().toUpperCase(),
              style: AppTextStyles.kpiLabel.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            TextSpan(text: _formatINR(plan.priceInr as double, compact: false).replaceFirst('₹ ', '₹'), style: AppTextStyles.boardCount.copyWith(fontSize: 20)),
            TextSpan(text: '/mo', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11)),
          ])),
          const SizedBox(height: 6),
          Text(plan.description as String, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildTaxInvoiceSection(BuildContext context, InvoiceEntity? inv) {
    if (inv == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border.all(color: AppColors.borderPrimary, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No invoice selected.', style: AppTextStyles.sectionSubtitle),
        ),
      );
    }

    final inter = _isInterState(inv);
    final subtotal = inv.amount / 1.18;
    final gst = inv.amount - subtotal;
    final cgst = inter ? 0.0 : gst / 2;
    final sgst = inter ? 0.0 : gst / 2;
    final igst = inter ? gst : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice body
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            border: Border.all(color: AppColors.borderPrimary),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C5BFF), Color(0xFF5836E0)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('e', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tax Invoice', style: AppTextStyles.boardCount.copyWith(fontSize: 22)),
                        Text('ORIGINAL FOR RECIPIENT', style: AppTextStyles.kpiLabel.copyWith(fontSize: 9.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Eskoolia Technologies Pvt Ltd', style: AppTextStyles.boardLabel.copyWith(fontSize: 12.5)),
              Text('12th Floor, Bagmane Tech Park, CV Raman Nagar, Bengaluru, Karnataka 560048 · India',
                  style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, height: 1.4)),
              Text.rich(TextSpan(style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5), children: const [
                TextSpan(text: 'GSTIN '),
                TextSpan(text: '—', style: TextStyle(fontFamily: 'monospace', color: AppColors.textSecondary)),
              ])),
              const Divider(height: 24, color: AppColors.borderPrimary),
              _invoiceInfoRow('BILLED TO', [
                (inv.schoolName, true),
                (inv.buyerState ?? '—', false),
                ('GSTIN ${inv.gstin ?? 'Unregistered'}', false),
              ]),
              const SizedBox(height: 12),
              _invoiceInfoRow('INVOICE DETAILS', [
                (inv.invoiceNumber, true),
                ('Invoice date: ${_formatDate(inv.issuedDate)}', false),
                ('Due date: ${_formatDate(inv.dueDate)}', false),
              ]),
              const SizedBox(height: 12),
              _invoiceInfoRow('PLACE OF SUPPLY', [
                (inv.buyerState ?? '—', true),
                (inter ? 'Inter-state supply' : 'Intra-state supply', false),
                ('Reverse charge: No · Currency: INR', false),
              ]),
              const Divider(height: 24, color: AppColors.borderPrimary),
              Text('LINE ITEMS', style: AppTextStyles.kpiLabel.copyWith(fontSize: 9.5)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Eskoolia ERP subscription — ${inv.schoolName}',
                              style: AppTextStyles.boardLabel.copyWith(fontSize: 12)),
                          Text('SAC 998313 · Qty 1', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5)),
                        ],
                      ),
                    ),
                    Text(_formatINR(subtotal, compact: false), style: AppTextStyles.boardLabel.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _totalsRow('Subtotal', subtotal),
              _totalsRow('Taxable value', subtotal),
              if (inter)
                _totalsRow('IGST @ 18%', igst)
              else ...[
                _totalsRow('CGST @ 9%', cgst),
                _totalsRow('SGST @ 9%', sgst),
              ],
              const Divider(height: 20, color: AppColors.borderPrimary),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total payable', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(_formatINR(inv.amount, compact: false), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8)),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Amount in words · ', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, fontStyle: FontStyle.italic)),
                  TextSpan(text: _amountInWords(inv.amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ])),
              ),
              const SizedBox(height: 12),
              Text('PAYMENT TERMS', style: AppTextStyles.kpiLabel.copyWith(fontSize: 9.5)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, height: 1.5), children: [
                  const TextSpan(text: 'Payable within 15 days of invoice date. Bank transfer to '),
                  const TextSpan(text: 'HDFC 0000123456789', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' · IFSC '),
                  const TextSpan(text: 'HDFC0001234', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' · UPI '),
                  const TextSpan(text: 'eskoolia@hdfcbank', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  TextSpan(text: ' · Reference '),
                  TextSpan(text: inv.invoiceNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' in remittance.'),
                ]),
              ),
              const SizedBox(height: 10),
              Text(
                'This is a computer-generated invoice; signature not required if digitally signed.',
                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // GST breakdown
        Container(
          decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GST BREAKDOWN', style: AppTextStyles.kpiLabel.copyWith(fontSize: 9.5)),
              const SizedBox(height: 10),
              _totalsRow('Taxable value', subtotal),
              if (inter) _totalsRow('IGST · 18%', igst) else ...[
                _totalsRow('CGST · 9%', cgst),
                _totalsRow('SGST · 9%', sgst),
              ],
              const Divider(height: 20, color: AppColors.borderPrimary),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total invoice', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(_formatINR(inv.amount, compact: false), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tax logic applied
        Container(
          decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TAX LOGIC APPLIED', style: AppTextStyles.kpiLabel.copyWith(fontSize: 9.5)),
              const SizedBox(height: 10),
              _logicRow('Seller state', _sellerState),
              _logicRow('Buyer state', inv.buyerState ?? '—'),
              _logicRow('Supply type', inter ? 'Inter-state' : 'Intra-state'),
              _logicRow('Applied', inter ? 'IGST' : 'CGST + SGST'),
              _logicRow('SAC', '998313 · Education software'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Actions
        Container(
          decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INVOICE ACTIONS', style: AppTextStyles.kpiLabel.copyWith(fontSize: 9.5)),
              const SizedBox(height: 10),
              _invoiceActionButton(Icons.download, 'Download PDF', () => _stub(context, 'PDF export')),
              _invoiceActionButton(Icons.open_in_new, 'Send to buyer', () => _stub(context, 'Send to buyer')),
              _invoiceActionButton(
                Icons.check_circle_outline,
                'Mark as paid',
                inv.status == 'paid' ? null : () => _markPaid(inv),
              ),
              _invoiceActionButton(Icons.edit_outlined, 'Edit invoice', () => _stub(context, 'Edit invoice')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _invoiceInfoRow(String label, List<(String, bool)> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.kpiLabel.copyWith(fontSize: 9.5)),
        const SizedBox(height: 4),
        for (final (text, emphasis) in lines)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: emphasis
                  ? AppTextStyles.boardLabel.copyWith(fontSize: 13)
                  : AppTextStyles.sectionSubtitle.copyWith(fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _totalsRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 12)),
          Text(_formatINR(value, compact: false), style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _logicRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _invoiceActionButton(IconData icon, String label, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 14),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.borderPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  void _stub(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action — not yet wired to a live API.')),
    );
  }

  void _markPaid(InvoiceEntity inv) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${inv.invoiceNumber} marked as paid (not yet wired to a live API).')),
    );
  }

  // Column widths (dp) — mirrors the web Recent Invoices table's column order
  // exactly: Invoice, School · GSTIN, Place of supply, Issued / Due, Tax,
  // Status, Total (right-aligned). Header + rows share one horizontal scroll
  // so the table only grows wider than the screen instead of being squeezed
  // or restructured into cards.
  static const double _icInvoice = 118;
  static const double _icSchool = 150;
  static const double _icSupply = 140;
  static const double _icDates = 100;
  static const double _icTax = 118;
  static const double _icStatus = 100;
  static const double _icTotal = 110;
  static const double _icGap = 12;

  Widget _buildInvoicesTable(BuildContext context, List<InvoiceEntity> invoices, InvoiceEntity? selected) {
    if (invoices.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('No invoices yet.', style: AppTextStyles.sectionSubtitle)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            _invoiceHeaderRow(),
            for (final inv in invoices) _invoiceDataRow(context, inv, selected),
          ],
        ),
      ),
    );
  }

  Widget _invoiceHeaderRow() {
    final headStyle = const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4);
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _icInvoice, child: Text('INVOICE', style: headStyle)),
          const SizedBox(width: _icGap),
          SizedBox(width: _icSchool, child: Text('SCHOOL · GSTIN', style: headStyle)),
          const SizedBox(width: _icGap),
          SizedBox(width: _icSupply, child: Text('PLACE OF SUPPLY', style: headStyle)),
          const SizedBox(width: _icGap),
          SizedBox(width: _icDates, child: Text('ISSUED / DUE', style: headStyle)),
          const SizedBox(width: _icGap),
          SizedBox(width: _icTax, child: Text('TAX', style: headStyle)),
          const SizedBox(width: _icGap),
          SizedBox(width: _icStatus, child: Text('STATUS', style: headStyle)),
          const SizedBox(width: _icGap),
          SizedBox(width: _icTotal, child: Text('TOTAL', textAlign: TextAlign.right, style: headStyle)),
        ],
      ),
    );
  }

  Widget _invoiceDataRow(BuildContext context, InvoiceEntity inv, InvoiceEntity? selected) {
    final inter = _isInterState(inv);
    final isSelected = selected != null && selected.invoiceNumber == inv.invoiceNumber;
    final meta = _statusMeta[inv.status] ?? _statusMeta['draft']!;
    final overdueDays = _daysOverdue(inv);
    final buyerCode = _stateCode(inv.buyerState);

    return InkWell(
      onTap: () => setState(() => _selected = inv),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purpleTint : null,
          border: const Border(top: BorderSide(color: AppColors.borderPrimary)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice — number + SAC
            SizedBox(
              width: _icInvoice,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.invoiceNumber,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const Text('SAC 998313', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: _icGap),
            // School · GSTIN
            SizedBox(
              width: _icSchool,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.schoolName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Text(inv.gstin ?? 'Unregistered',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: _icGap),
            // Place of supply
            SizedBox(
              width: _icSupply,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      if (buyerCode.isNotEmpty)
                        TextSpan(text: '$buyerCode — ', style: const TextStyle(fontFamily: 'monospace', color: AppColors.textTertiary)),
                      TextSpan(text: inv.buyerState ?? '—'),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                  ),
                  Text(inter ? 'Inter-state' : 'Intra-state', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: _icGap),
            // Issued / Due
            SizedBox(
              width: _icDates,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(inv.issuedDate), style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary)),
                  Text('Due ${_formatDate(inv.dueDate)}', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: _icGap),
            // Tax
            SizedBox(
              width: _icTax,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(6)),
                child: Text(inter ? 'IGST 18%' : 'CGST+SGST 18%',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppColors.purpleDeep)),
              ),
            ),
            const SizedBox(width: _icGap),
            // Status
            SizedBox(
              width: _icStatus,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      overdueDays != null ? '${meta.label} · ${overdueDays}d' : meta.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: meta.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _icGap),
            // Total — compact + full precision
            SizedBox(
              width: _icTotal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatINR(inv.amount), style: AppTextStyles.boardCount.copyWith(fontSize: 14)),
                  Text(_formatINR(inv.amount, compact: false).replaceFirst('₹ ', '₹'),
                      style: const TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
