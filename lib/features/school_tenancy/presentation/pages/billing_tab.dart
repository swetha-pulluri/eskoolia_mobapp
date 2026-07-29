import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/status_chip_widget.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/new_invoice_sheet.dart';
import '../widgets/plan_form_sheet.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/school_tenancy_layout.dart';
import '../utils/invoice_pdf.dart';

/// Super Admin Billing Page
/// Exact conversion of web frontend billing structure
class SuperAdminBillingPage extends ConsumerStatefulWidget {
  const SuperAdminBillingPage({super.key});

  @override
  ConsumerState<SuperAdminBillingPage> createState() => _SuperAdminBillingPageState();
}

class _SuperAdminBillingPageState extends ConsumerState<SuperAdminBillingPage> {
  /// Web's `TaxInvoiceCard` always renders the currently `selected` invoice
  /// inline on the page (auto-selected as the first fetched invoice, updated
  /// by clicking a row in "Recent invoices" — `billing/page.tsx:579,
  /// 597-598, 868`) rather than opening a modal per row. This mirrors that
  /// "selected invoice" state.
  String? _selectedInvoiceId;

  // The Tax Invoice card (showing the `selected` invoice) sits well above
  // Recent Invoices on this scroll-everything mobile layout. Selecting a row
  // updated state correctly but gave no visible feedback when the user was
  // scrolled down to Recent Invoices, which read as "View does nothing" —
  // this key lets us scroll the card into view on selection.
  final GlobalKey _taxInvoiceKey = GlobalKey();

  // Neither Export button showed any state change on tap while the network
  // request/file dialog was in flight — with no spinner or disabled state,
  // a slow response (or one that silently hung) looked exactly like "the
  // button does nothing".
  bool _exportBusy = false;

  void _selectInvoice(String invoiceId) {
    setState(() => _selectedInvoiceId = invoiceId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _taxInvoiceKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.05);
      }
    });
  }

  String _formatINR(double amount, {bool compact = true, bool symbol = true, int fraction = 2}) =>
      formatINR(amount, compact: compact, symbol: symbol, fraction: fraction);

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  /// Matches web's `STATUS_META` (`billing/page.tsx:227-233`) — the real
  /// invoice status vocabulary is draft/sent/partially_paid/paid/overdue/
  /// cancelled (`partially_paid` and the `paid_amount`/`due_amount`/payment
  /// ledger it's derived from live on an unmerged branch — `git show
  /// f956c3ce:backend/apps/tenancy/models.py` — that the live backend this
  /// app talks to is actually running, confirmed by real `partially_paid`
  /// invoices already observed in production data).
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.successGreen;
      case 'sent':
        return AppColors.warningAmber;
      case 'partially_paid':
        return AppColors.skyBlue;
      case 'overdue':
        return AppColors.dangerRed;
      case 'cancelled':
      case 'draft':
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'sent':
        return 'Sent';
      case 'partially_paid':
        return 'Partially Paid';
      case 'overdue':
        return 'Overdue';
      case 'cancelled':
        return 'Cancelled';
      case 'draft':
        return 'Draft';
      default:
        return 'Draft';
    }
  }

  bool _isInterState(InvoiceEntity invoice) {
    final seller = invoice.sellerState.trim().toLowerCase();
    final buyer = invoice.buyerState.trim().toLowerCase();
    return seller != buyer;
  }

  // Matches web's own `stateCode()` map exactly (`billing/page.tsx:71-101`).
  static const _stateCodes = {
    'andhra pradesh': '37', 'arunachal pradesh': '12', 'telangana': '36', 'karnataka': '29', 'tamil nadu': '33',
    'kerala': '32', 'maharashtra': '27', 'gujarat': '24', 'rajasthan': '08',
    'madhya pradesh': '23', 'uttar pradesh': '09', 'bihar': '10', 'west bengal': '19',
    'odisha': '21', 'jharkhand': '20', 'chhattisgarh': '22', 'haryana': '06',
    'punjab': '03', 'himachal pradesh': '02', 'uttarakhand': '05', 'delhi': '07',
    'goa': '30', 'assam': '18', 'tripura': '16', 'sikkim': '11',
  };

  String _stateCode(String state) => _stateCodes[state.trim().toLowerCase()] ?? '';

  InvoiceEntity? _selectedInvoice(PaginatedInvoicesEntity invoices) {
    if (invoices.results.isEmpty) return null;
    if (_selectedInvoiceId != null) {
      for (final inv in invoices.results) {
        if (inv.id == _selectedInvoiceId) return inv;
      }
    }
    return invoices.results.first;
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final mrrAsync = ref.watch(billingMrrProvider);
    final plansAsync = ref.watch(plansProvider);

    if (invoicesAsync.isLoading && !invoicesAsync.hasValue) {
      return const SchoolTenancyLayout(
        currentPath: '/super-admin/billing',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (invoicesAsync.hasError && !invoicesAsync.hasValue) {
      return SchoolTenancyLayout(
        currentPath: '/super-admin/billing',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load billing data.\n${invoicesAsync.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageSubtitle,
            ),
          ),
        ),
      );
    }

    final invoices = invoicesAsync.value!;
    final mrr = mrrAsync.value;
    final plans = plansAsync.value;
    final selected = _selectedInvoice(invoices);

    // Web sources `sellerGstin`/`sellerState` from `mrr?.seller_gstin`
    // falling back to the `selected` invoice (`billing/page.tsx:641-642`).
    final sellerGstin = selected?.sellerGstin ?? '';
    final sellerState = selected?.sellerState ?? '';

    // Matches web's `monthLabel`/`fyLabel` fallbacks (`billing/page.tsx:639-640`)
    // — the backend never returns `gst_month_label`/`fiscal_year_label`, so
    // web always falls through to these locally-computed labels too.
    final now = DateTime.now();
    const monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final monthLabel = monthNames[now.month - 1];
    final fyLabel = 'FY ${now.year}-${(now.year + 1).toString().substring(2)}';

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
                    // Web's actual title is "Tenants & Billing", not
                    // "Billing & Revenue" (`billing/page.tsx:650-652`).
                    Wrap(
                      spacing: 6,
                      children: [
                        Text('Tenants &', style: AppTextStyles.pageTitle),
                        Text('Billing', style: AppTextStyles.pageTitleAccent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Matches web's subtitle exactly (`billing/page.tsx:653-661`).
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.pageSubtitle,
                        children: [
                          const TextSpan(text: 'GST-compliant invoicing across all schools. '),
                          if (sellerGstin.isNotEmpty)
                            TextSpan(
                              children: [
                                const TextSpan(text: '· Seller GSTIN '),
                                TextSpan(
                                  text: sellerGstin,
                                  style: const TextStyle(fontFamily: 'monospace', color: AppColors.textPrimary),
                                ),
                                const TextSpan(text: ' '),
                              ],
                            ),
                          if (sellerState.isNotEmpty) TextSpan(text: '· $sellerState. '),
                          const TextSpan(
                            text: 'Place of supply auto-detected from buyer state code · IGST for inter-state, CGST + SGST for intra-state.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Web's Billing header has exactly two buttons —
                        // "Export GSTR-1" and "New invoice" — no Refresh
                        // button at all (`billing/page.tsx:663-680`).
                        OutlinedButton.icon(
                          onPressed: _exportBusy ? null : _exportGstr1,
                          icon: _exportBusy
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download, size: 14),
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
                          onPressed: _openNewInvoiceSheet,
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
                    label: 'MRR',
                    value: mrr == null ? '—' : _formatINR(mrr.currentMrr),
                    // Web plots `mrr?.mrr_series` here — the backend never
                    // returns that field, so web's own sparkline renders
                    // empty (`Spark` returns a blank svg when data is
                    // missing, `billing/page.tsx:104-107`). No series data
                    // exists to plot, so this is omitted rather than
                    // fabricated.
                    sparklineData: null,
                    sparklineColor: const Color(0xFF0369A1),
                    // Matches web: trend only shows when `trend_percent` is
                    // non-zero (`billing/page.tsx:689-694`).
                    trend: (mrr != null && mrr.trendPercent != 0)
                        ? '${mrr.trendPercent > 0 ? '+' : ''}${mrr.trendPercent}%'
                        : null,
                    trendColor: AppColors.successGreen,
                    footnote: 'Recurring · pre-GST',
                  ),
                  KpiCard(
                    label: 'GST Collected ($monthLabel)',
                    value: mrr == null ? '—' : _formatINR(mrr.gstCollected),
                    sparklineData: null,
                    sparklineColor: const Color(0xFFA65D08),
                    // Web's `gst_trend_percent` isn't returned by the
                    // backend, so web itself never shows a trend badge here.
                    trend: null,
                    trendColor: AppColors.warningAmber,
                    // Matches web: footnote is the IGST/CGST+SGST split
                    // whenever `mrr` is loaded, falling back to
                    // 'Tax collected this cycle' only while loading
                    // (`billing/page.tsx:708-714`).
                    footnote: mrr == null
                        ? 'Tax collected this cycle'
                        : 'IGST ${_formatINR(mrr.gstIgst)} · CGST+SGST ${_formatINR(mrr.gstCgstSgst)}',
                  ),
                  KpiCard(
                    label: 'Outstanding',
                    value: mrr == null ? '—' : _formatINR(mrr.outstandingAmount),
                    sparklineData: null,
                    sparklineColor: const Color(0xFFE0463A),
                    // Web's `outstanding_count`/`outstanding_avg_overdue_days`
                    // also aren't returned by the backend, so web shows no
                    // trend and the generic footnote here too.
                    trend: null,
                    trendColor: AppColors.dangerRed,
                    footnote: 'Open receivables',
                  ),
                  KpiCard(
                    label: 'Invoices YTD',
                    // Web's `invoices_ytd`/`invoices_paid` also aren't
                    // returned by the backend, so web always shows '0' here
                    // with no trend badge (`billing/page.tsx:738-739`).
                    value: mrr == null ? '—' : '0',
                    sparklineData: null,
                    sparklineColor: const Color(0xFF6D28D9),
                    trend: null,
                    trendColor: AppColors.successGreen,
                    footnote: fyLabel,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // PLANS — wrapped in a bordered card matching web's
              // `<section className="rounded-2xl border ...">`
              // (`billing/page.tsx:748`).
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border.all(color: AppColors.borderPrimary),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.purpleTint,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.receipt_long, size: 16, color: AppColors.primaryPurple),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subscription plans', style: AppTextStyles.sectionTitle),
                              if (plans != null)
                                Text(
                                  'India-priced · GST ${plans.gstPercent.toStringAsFixed(0)}% under SAC ${plans.sacCode} (${plans.sacDescription})',
                                  style: AppTextStyles.sectionSubtitle,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Web's "Add plan" is a filled purple button, not a
                        // plain text button (`billing/page.tsx:762-768`).
                        ElevatedButton.icon(
                          onPressed: () => _openPlanFormSheet(),
                          icon: const Icon(Icons.add, size: 13),
                          label: const Text('Add plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            textStyle: AppTextStyles.buttonPrimary.copyWith(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (plansAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (plans == null || plans.plans.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No plans configured.', style: AppTextStyles.sectionSubtitle)),
                      )
                    else
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.9,
                        children: plans.plans.map((p) => _buildPlanCard(p)).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // TAX INVOICE — always visible inline, showing the currently
              // `selected` invoice (`billing/page.tsx:800-806`), not a modal.
              // Wrapped in KeyedSubtree so `_selectInvoice`'s
              // Scrollable.ensureVisible can actually find this section —
              // previously the key was declared but never attached to
              // anything, so `_taxInvoiceKey.currentContext` was always
              // null and the scroll silently did nothing.
              KeyedSubtree(
                key: _taxInvoiceKey,
                child: selected == null
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.bgPrimary,
                          border: Border.all(color: AppColors.borderPrimary, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No invoice selected. Tap a row in "Recent invoices" to preview it here.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.sectionSubtitle,
                        ),
                      )
                    : _buildTaxInvoiceCard(selected, sellerGstin, sellerState),
              ),

              const SizedBox(height: 24),

              // RECENT INVOICES — a real table, matching web's 7-column
              // layout (`billing/page.tsx:808-910`), wrapped in the same
              // icon+title+subtitle+button header treatment as Plans.
              _buildRecentInvoicesTable(invoices, fyLabel),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(text, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5)),
      ],
    );
  }

  void _openNewInvoiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => const NewInvoiceSheet(),
    ).then((created) {
      if (created is InvoiceEntity && mounted) {
        setState(() => _selectedInvoiceId = created.id);
        // Matches web's exact toast text — `toast.success(\`Invoice
        // ${created.invoice_number} ${statusValue === 'sent' ? 'sent' :
        // 'saved as draft'}.\`)` (`NewInvoiceDrawer.tsx:377`).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${created.invoiceNumber} ${created.status == 'sent' ? 'sent' : 'saved as draft'}.')),
        );
      }
    });
  }

  /// Opens the real Record Payment sheet — mirrors web's `handleMarkPaid()`,
  /// which (per `git show f956c3ce`) no longer calls mark-paid directly but
  /// opens `RecordPaymentModal`, which calls `POST
  /// /billing/invoices/{id}/payments/`. Matches web's exact success toast
  /// text (`page.tsx` `handleRecordPayment`).
  void _openRecordPaymentSheet(InvoiceEntity invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => RecordPaymentSheet(invoice: invoice),
    ).then((result) {
      if (result is RecordPaymentResultEntity && mounted) {
        setState(() => _selectedInvoiceId = result.invoice.id);
        final remaining = result.invoice.dueAmount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(remaining > 0
              ? 'Recorded ${formatINR(result.payment.amount, compact: false)}. Remaining due ${formatINR(remaining, compact: false)}.'
              : 'Invoice ${result.invoice.invoiceNumber} fully paid.')),
        );
      }
    });
  }

  void _openEditInvoiceSheet(InvoiceEntity invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => NewInvoiceSheet(invoice: invoice),
    ).then((updated) {
      if (updated is InvoiceEntity && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${updated.invoiceNumber} updated.')),
        );
      }
    });
  }

  /// Matches web's `handleCancel()` exactly (`billing/page.tsx`, `git show
  /// f956c3ce`) — blocks cancelling a paid invoice with the same message,
  /// confirms with the same dialog text, and calls the same real
  /// `DELETE /billing/invoices/{id}/` endpoint.
  Future<void> _confirmCancelInvoice(InvoiceEntity invoice) async {
    if (invoice.status == 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paid invoices cannot be cancelled. Issue a credit note instead.')),
      );
      return;
    }
    if (invoice.status == 'cancelled') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cancel invoice ${invoice.invoiceNumber}?'),
        content: const Text(
          'This marks the invoice as cancelled and cannot be undone. The invoice will remain visible '
          'for audit. Create a new invoice to re-bill.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.dangerRed),
            child: const Text('Cancel Invoice'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final updated = await repository.cancelInvoice(invoice.id);
      ref.invalidate(invoicesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${updated.invoiceNumber} cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancel invoice failed: $e')),
        );
      }
    }
  }

  /// Real call to `POST /billing/invoices/{id}/reminder/` — mirrors web's
  /// `sendInvoiceReminder()` (defined in `billing.ts` but not wired up to
  /// any button in the currently-checked-out `billing/page.tsx`; the
  /// backend endpoint is real, so "Send to buyer" is wired to it here).
  Future<void> _sendReminder(InvoiceEntity invoice) async {
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final result = await repository.sendInvoiceReminder(invoice.id);
      ref.invalidate(invoicesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder recorded for ${result.invoiceNumber} (status: ${_statusLabel(result.status)}).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send reminder failed: $e')),
        );
      }
    }
  }

  /// Real call to `GET /billing/export/gstr1/` — mirrors web's
  /// `exportGstr1()`/`downloadFile()`. Uses the app-wide `saveBytesForDownload`
  /// helper (the established convention for every other export in this app)
  /// instead of `file_picker`'s `saveFile()`, which throws `UnimplementedError`
  /// on web and opens an unwanted interactive "Save As" dialog on mobile —
  /// this instead does a zero-dialog Blob+anchor-click download on web,
  /// matching the real web app's own `<a download>` mechanism exactly.
  Future<void> _exportGstr1() async {
    if (_exportBusy) return;
    setState(() => _exportBusy = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final bytes = Uint8List.fromList(await repository.exportGstr1());
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      await saveBytesForDownload(bytes: bytes, filename: 'gstr1-report-$stamp.xlsx');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Matches web's exact toast text — `toast.success('GSTR-1
          // exported.')` (`billing/page.tsx:617`).
          const SnackBar(content: Text('GSTR-1 exported.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GSTR-1 export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  void _openPlanFormSheet({SubscriptionPlanEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => PlanFormSheet(existing: existing),
    ).then((saved) {
      if (saved is SubscriptionPlanEntity && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan "${saved.name}" ${existing != null ? 'updated' : 'created'}.')),
        );
      }
    });
  }

  Future<void> _confirmDeletePlan(SubscriptionPlanEntity plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text('Delete plan "${plan.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      await repository.deletePlan(plan.code);
      ref.invalidate(plansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan "${plan.name}" deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  /// Matches web's `TaxInvoiceCard` (`billing/page.tsx:296-530`) — a 2-column
  /// desktop grid (invoice body + GST breakdown/Tax logic/Actions), stacked
  /// into a single column here for mobile width.
  Widget _buildTaxInvoiceCard(InvoiceEntity invoice, String sellerGstin, String sellerState) {
    final inter = _isInterState(invoice);
    final tax = invoice.taxBreakdown;
    final sellerCode = _stateCode(sellerState.isNotEmpty ? sellerState : invoice.sellerState);
    final buyerCode = _stateCode(invoice.buyerState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: invoice body
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            border: Border.all(color: AppColors.borderPrimary),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tax Invoice', style: AppTextStyles.sectionTitle.copyWith(fontSize: 22, fontFamily: 'serif')),
                        Text('ORIGINAL FOR RECIPIENT', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 2, right: 8),
                    decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(7)),
                    child: const Text('e', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(invoice.sellerName, style: AppTextStyles.boardLabel.copyWith(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
                        Text('12th Floor, Bagmane Tech Park, CV Raman Nagar, Bengaluru, ${sellerState.isNotEmpty ? sellerState : invoice.sellerState} 560048 · India',
                            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5), textAlign: TextAlign.right),
                        Text('GSTIN ${(sellerGstin.isNotEmpty ? sellerGstin : invoice.sellerGstin).isEmpty ? '—' : (sellerGstin.isNotEmpty ? sellerGstin : invoice.sellerGstin)}',
                            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontFamily: 'monospace'), textAlign: TextAlign.right),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              _invoiceInfoBlock('BILLED TO', [
                invoice.buyerName.isEmpty ? invoice.schoolName : invoice.buyerName,
                invoice.buyerState,
                'GSTIN ${invoice.buyerGstin.isEmpty ? 'Unregistered' : invoice.buyerGstin}',
                if (invoice.tenantId.isNotEmpty) 'Tenant ${invoice.tenantId}',
              ]),
              const SizedBox(height: 12),
              _invoiceDetailsBlock(invoice),
              const SizedBox(height: 12),
              _invoiceInfoBlock('PLACE OF SUPPLY', [
                '${buyerCode.isNotEmpty ? '$buyerCode — ' : ''}${invoice.buyerState}',
                inter ? 'Inter-state supply' : 'Intra-state supply',
                'Reverse charge — ${invoice.reverseCharge ? 'Yes' : 'No'}',
                'Currency — INR',
              ]),

              const SizedBox(height: 18),
              Text('LINE ITEMS', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
              const SizedBox(height: 8),
              // Matches web's 5-column table (Description/SAC/Qty/Rate/
              // Amount, `billing/page.tsx:398-419`) restructured as a
              // 2-line block per item for mobile width.
              ...invoice.lineItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(item.description, style: AppTextStyles.boardLabel.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(width: 8),
                            Text('SAC ${item.sacCode}', style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 10.5)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity} × ${_formatINR(item.unitPrice, compact: false, symbol: false)}',
                                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatINR(item.amount, compact: false, symbol: false),
                              style: AppTextStyles.boardLabel.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _totalRow('Subtotal', tax.subtotal),
                    _totalRow('Discount', 0),
                    _totalRow('Taxable value', tax.subtotal),
                    if (inter) _totalRow('IGST @ 18%', tax.igst ?? 0),
                    if (!inter) _totalRow('CGST @ 9%', tax.cgst ?? 0),
                    if (!inter) _totalRow('SGST @ 9%', tax.sgst ?? 0),
                    _totalRow('Round off', 0),
                    const Divider(),
                    _totalRow('Total payable', tax.grandTotal, bold: true),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8)),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Amount in words · ', style: TextStyle(fontStyle: FontStyle.italic)),
                      TextSpan(text: tax.amountInWords, style: AppTextStyles.boardLabel.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text('PAYMENT TERMS', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(
                'Payable within 15 days of invoice date. Bank transfer to HDFC 0000123456789 · IFSC HDFC0001234 · '
                'A/c name Eskoolia Technologies Pvt Ltd · UPI eskoolia@hdfcbank · Reference ${invoice.invoiceNumber} in remittance.',
                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, height: 1.5),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('For ${invoice.sellerName.isEmpty ? 'Eskoolia Technologies Pvt Ltd' : invoice.sellerName}',
                        style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11)),
                    Text('Authorised Signatory', style: AppTextStyles.boardLabel.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Text('NOTES', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(
                'Whether tax payable under reverse charge — ${invoice.reverseCharge ? 'Yes' : 'No'}. This is a computer-generated invoice; signature not required if digitally signed.',
                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // RIGHT column (stacked below on mobile): GST breakdown, Tax logic
        // applied, Invoice actions — each its own bordered card.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            border: Border.all(color: AppColors.borderPrimary),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GST BREAKDOWN', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              _totalRow('Taxable value', tax.subtotal),
              if (inter) _totalRow('IGST · 18%', tax.igst ?? 0),
              if (!inter) _totalRow('CGST · 9%', tax.cgst ?? 0),
              if (!inter) _totalRow('SGST · 9%', tax.sgst ?? 0),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text('Total invoice', style: AppTextStyles.boardLabel.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatINR(tax.grandTotal, compact: false),
                    style: AppTextStyles.boardLabel.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.successGreen),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            border: Border.all(color: AppColors.borderPrimary),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TAX LOGIC APPLIED', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              _logicRow('Seller state', '${sellerCode.isNotEmpty ? '$sellerCode ' : ''}${sellerState.isNotEmpty ? sellerState : invoice.sellerState}'),
              _logicRow('Buyer state', '${buyerCode.isNotEmpty ? '$buyerCode ' : ''}${invoice.buyerState}'),
              _logicRow('Supply type', inter ? 'Inter-state' : 'Intra-state'),
              _logicRow('Applied', inter ? 'IGST' : 'CGST + SGST'),
              _logicRow('SAC', '998313 Education software'),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            border: Border.all(color: AppColors.borderPrimary),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INVOICE ACTIONS', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              // Web itself uses the browser's native window.print() for this
              // (`handleDownloadPdf`) on the same on-screen invoice — this
              // builds an equivalent real PDF from the same data and hands
              // it to the native print/share sheet.
              _actionRow(context, Icons.download_outlined, 'Download PDF', () => shareInvoicePdf(invoice, sellerGstin: sellerGstin, sellerState: sellerState)),
              // Real call to POST /billing/invoices/{id}/reminder/.
              _actionRow(context, Icons.send_outlined, 'Send to buyer', () => _sendReminder(invoice)),
              // Real call — opens Record Payment, which posts to
              // POST /billing/invoices/{id}/payments/. Matches web's exact
              // label logic (`billing/page.tsx`, `git show f956c3ce`).
              _actionRow(
                context,
                Icons.check_circle_outline,
                invoice.status == 'partially_paid' ? 'Record payment' : 'Record payment / Mark paid',
                (invoice.status == 'paid' || invoice.status == 'cancelled') ? null : () => _openRecordPaymentSheet(invoice),
              ),
              // Real call — opens Edit Invoice, which PATCHes
              // /billing/invoices/{id}/ (status/due_date/notes/terms only).
              _actionRow(context, Icons.edit_outlined, 'Edit invoice', () => _openEditInvoiceSheet(invoice)),
              // Real call to DELETE /billing/invoices/{id}/ (cancels, does
              // not hard-delete) — matches web's `handleCancel()` exactly.
              _actionRow(
                context,
                Icons.block,
                'Cancel invoice',
                invoice.status == 'cancelled' ? null : () => _confirmCancelInvoice(invoice),
                danger: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Matches web's "Recent invoices" table (`billing/page.tsx:808-910`) —
  /// same icon+title+subtitle+button card header as Subscription plans, then
  /// a real 7-column table (horizontally scrollable at mobile width). Tapping
  /// a row updates the `selected` invoice shown in the Tax Invoice card above,
  /// instead of opening a per-row modal.
  Widget _buildRecentInvoicesTable(PaginatedInvoicesEntity invoices, String fyLabel) {
    final selected = _selectedInvoice(invoices);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: const Icon(Icons.description_outlined, size: 16, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent invoices', style: AppTextStyles.sectionTitle),
                    Text('${invoices.results.length} of ${invoices.count} invoices · $fyLabel', style: AppTextStyles.sectionSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _exportBusy ? null : _exportGstr1,
                icon: _exportBusy
                    ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download, size: 13),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  textStyle: AppTextStyles.buttonSecondary.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (invoices.results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No invoices yet.', style: AppTextStyles.sectionSubtitle)),
            )
          else
            ...invoices.results.map((invoice) {
              final inter = _isInterState(invoice);
              final buyerCode = _stateCode(invoice.buyerState);
              final isSelected = selected?.id == invoice.id;
              final dueDate = DateTime.tryParse(invoice.dueDate);
              final daysOverdue = (dueDate != null && invoice.status == 'overdue')
                  ? DateTime.now().difference(dueDate).inDays.clamp(0, 999999)
                  : null;

              // The action icons are a SIBLING of the "select card" tap
              // area below (not a descendant of its InkWell) — nesting an
              // InkWell inside another tappable InkWell's hit-test region is
              // exactly the kind of ambiguity that can swallow taps on the
              // inner icons, so this avoids that entirely rather than
              // relying on gesture-arena resolution to sort it out.
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                color: isSelected ? AppColors.purpleTint : AppColors.bgSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? AppColors.primaryPurple : AppColors.borderPrimary),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        // Matches web's row click exactly — `onClick={() =>
                        // setSelected(inv)}` (`billing/page.tsx:868`) — a
                        // silent selection, no toast/popup of any kind.
                        onTap: () => _selectInvoice(invoice.id),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(invoice.invoiceNumber, style: AppTextStyles.boardLabel.copyWith(fontFamily: 'monospace', fontSize: 12.5, fontWeight: FontWeight.w700)),
                                        Text('SAC 998313', style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 9.5)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_formatINR(invoice.taxBreakdown.grandTotal), style: AppTextStyles.boardCount.copyWith(fontSize: 15)),
                                      Text(_formatINR(invoice.taxBreakdown.grandTotal, compact: false, symbol: false), style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 9.5)),
                                      // Matches web's due sub-line exactly
                                      // (`billing/page.tsx`, `git show f956c3ce`).
                                      if (invoice.dueAmount > 0 && invoice.status != 'cancelled')
                                        Text('Due ${_formatINR(invoice.dueAmount, compact: false, symbol: false)}',
                                            style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 9.5, color: AppColors.warningAmber)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(invoice.schoolName, style: AppTextStyles.boardLabel.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(invoice.buyerGstin.isEmpty ? 'Unregistered' : invoice.buyerGstin, style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 10.5)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  _metaChip(Icons.place_outlined, '${buyerCode.isNotEmpty ? '$buyerCode — ' : ''}${invoice.buyerState.isEmpty ? '—' : invoice.buyerState} · ${inter ? 'Inter-state' : 'Intra-state'}'),
                                  _metaChip(Icons.calendar_today_outlined, '${_formatDate(invoice.invoiceDate)} · Due ${_formatDate(invoice.dueDate)}'),
                                  _metaChip(Icons.receipt_long_outlined, inter ? 'IGST 18%' : 'CGST+SGST 18%'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              StatusChip(
                                label: daysOverdue != null ? '${_statusLabel(invoice.status)} · ${daysOverdue}d' : _statusLabel(invoice.status),
                                color: _getStatusColor(invoice.status),
                                showDot: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Same silent selection as the row tap above —
                          // no popup, matching web's row-click behavior.
                          _rowActionIcon(
                            icon: Icons.visibility_outlined,
                            tooltip: 'View',
                            onTap: () => _selectInvoice(invoice.id),
                          ),
                          const SizedBox(width: 6),
                          _rowActionIcon(
                            icon: Icons.download_outlined,
                            tooltip: 'Download PDF',
                            // shareInvoicePdf already falls back to the
                            // invoice's own seller fields when these are
                            // empty (`invoice_pdf.dart`), so this is
                            // equivalent to the main Invoice Actions panel's
                            // call once `sellerGstin`/`sellerState` (sourced
                            // from `mrr`) are unset for this invoice.
                            onTap: () => shareInvoicePdf(invoice, sellerGstin: '', sellerState: ''),
                          ),
                          const SizedBox(width: 6),
                          _rowActionIcon(
                            icon: Icons.check_circle_outline,
                            tooltip: invoice.status == 'paid' ? 'Already paid' : invoice.status == 'cancelled' ? 'Cancelled invoice' : 'Record payment',
                            color: AppColors.successGreen,
                            onTap: (invoice.status == 'paid' || invoice.status == 'cancelled')
                                ? null
                                : () => _openRecordPaymentSheet(invoice),
                          ),
                          const SizedBox(width: 6),
                          _rowActionIcon(
                            icon: Icons.block,
                            tooltip: invoice.status == 'paid' ? 'Paid invoice — issue credit note instead' : invoice.status == 'cancelled' ? 'Already cancelled' : 'Cancel invoice',
                            color: AppColors.dangerRed,
                            onTap: (invoice.status == 'paid' || invoice.status == 'cancelled') ? null : () => _confirmCancelInvoice(invoice),
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
    );
  }

  Widget _rowActionIcon({required IconData icon, required String tooltip, required VoidCallback? onTap, Color? color}) {
    final effectiveColor = onTap == null ? AppColors.textTertiary.withValues(alpha: 0.4) : (color ?? AppColors.textSecondary);
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (color != null && onTap != null) ? color.withValues(alpha: 0.1) : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: effectiveColor),
          ),
        ),
      ),
    );
  }

  /// Matches web's INVOICE DETAILS block exactly (`billing/page.tsx:371-378`)
  /// — invoice no. and invoice date are each a gray label line followed by
  /// a bold value line, while due date is a single line with the label and
  /// value inline. This differs from [_invoiceInfoBlock]'s uniform
  /// label+lines layout, so it gets its own widget.
  Widget _invoiceDetailsBlock(InvoiceEntity invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INVOICE DETAILS', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text('Invoice no.', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5)),
        Text(invoice.invoiceNumber, style: AppTextStyles.boardLabel.copyWith(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('Invoice date', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5)),
        Text(_formatDate(invoice.invoiceDate), style: AppTextStyles.boardLabel.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
            children: [
              const TextSpan(text: 'Due date '),
              TextSpan(text: _formatDate(invoice.dueDate), style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _invoiceInfoBlock(String label, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 3),
        ...lines.map((l) => Text(l, style: AppTextStyles.boardLabel.copyWith(fontSize: 12))),
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          ),
          const SizedBox(width: 8),
          Text(
            _formatINR(value, compact: false),
            style: AppTextStyles.boardLabel.copyWith(fontSize: bold ? 14 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _logicRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.boardLabel.copyWith(fontSize: 11.5),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(BuildContext context, IconData icon, String label, VoidCallback? onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? AppColors.dangerRed : AppColors.textPrimary,
          side: BorderSide(color: danger ? AppColors.dangerRed.withValues(alpha: 0.4) : AppColors.borderPrimary),
          backgroundColor: danger ? AppColors.dangerRed.withValues(alpha: 0.06) : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanEntity plan) {
    final popular = plan.popular;
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
          // Matches web's `PlanCard` hierarchy (`billing/page.tsx:207-221`):
          // the plan name is a small uppercase label (not a large title) and
          // the price is the dominant large text.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.name.toUpperCase(),
                  style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
              ),
              if (popular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(999),
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  // Web uses `fraction: 0` for plan prices specifically
                  // (`billing/page.tsx:218`) — whole rupees, comma-grouped.
                  _formatINR(plan.priceInr, compact: false, fraction: 0),
                  style: AppTextStyles.kpiValue.copyWith(fontSize: 22),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // Web hardcodes "/mo" here regardless of `billing_cycle`
              // (`billing/page.tsx:219`) — not derived from the field.
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('/mo', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(plan.description, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, height: 1.3)),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openPlanFormSheet(existing: plan),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: popular ? AppColors.primaryPurple : AppColors.borderPrimary,
                    ),
                    foregroundColor: popular ? AppColors.primaryPurple : AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDeletePlan(plan),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.dangerRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
