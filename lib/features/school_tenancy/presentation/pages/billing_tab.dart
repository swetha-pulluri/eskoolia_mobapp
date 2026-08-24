import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../widgets/compact_kpi_card.dart';
import '../../../../core/widgets/status_chip_widget.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/new_invoice_sheet.dart';
import '../widgets/plan_form_sheet.dart';
import '../widgets/school_tenancy_layout.dart';
import 'invoice_detail_page.dart';

/// Super Admin Billing Page
/// Exact conversion of web frontend billing structure
class SuperAdminBillingPage extends ConsumerStatefulWidget {
  const SuperAdminBillingPage({super.key});

  @override
  ConsumerState<SuperAdminBillingPage> createState() =>
      _SuperAdminBillingPageState();
}

class _SuperAdminBillingPageState extends ConsumerState<SuperAdminBillingPage> {
  // Neither Export button showed any state change on tap while the network
  // request/file dialog was in flight — with no spinner or disabled state,
  // a slow response (or one that silently hung) looked exactly like "the
  // button does nothing".
  bool _exportBusy = false;

  void _openInvoiceDetail(InvoiceEntity invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoice: invoice,
          sellerGstin: invoice.sellerGstin,
          sellerState: invoice.sellerState,
        ),
      ),
    );
  }

  String _formatINR(
    double amount, {
    bool compact = true,
    bool symbol = true,
    int fraction = 2,
  }) => formatINR(amount, compact: compact, symbol: symbol, fraction: fraction);

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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
    'andhra pradesh': '37',
    'arunachal pradesh': '12',
    'telangana': '36',
    'karnataka': '29',
    'tamil nadu': '33',
    'kerala': '32',
    'maharashtra': '27',
    'gujarat': '24',
    'rajasthan': '08',
    'madhya pradesh': '23',
    'uttar pradesh': '09',
    'bihar': '10',
    'west bengal': '19',
    'odisha': '21',
    'jharkhand': '20',
    'chhattisgarh': '22',
    'haryana': '06',
    'punjab': '03',
    'himachal pradesh': '02',
    'uttarakhand': '05',
    'delhi': '07',
    'goa': '30',
    'assam': '18',
    'tripura': '16',
    'sikkim': '11',
  };

  String _stateCode(String state) =>
      _stateCodes[state.trim().toLowerCase()] ?? '';

  /// A representative invoice for the page header's seller GSTIN/state text
  /// (`billing/page.tsx:641-642` defaults `selected` to the first fetched
  /// invoice) — there's no more single "selected" invoice on this page now
  /// that each row opens its own dedicated detail screen.
  InvoiceEntity? _headerInvoice(PaginatedInvoicesEntity invoices) {
    if (invoices.results.isEmpty) return null;
    return invoices.results.first;
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final mrrAsync = ref.watch(billingMrrProvider);
    final plansAsync = ref.watch(plansProvider);

    if (invoicesAsync.isLoading && !invoicesAsync.hasValue) {
      return const SchoolTenancyLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (invoicesAsync.hasError && !invoicesAsync.hasValue) {
      return SchoolTenancyLayout(
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
    final headerInvoice = _headerInvoice(invoices);

    // Web sources `sellerGstin`/`sellerState` from `mrr?.seller_gstin`
    // falling back to the `selected` invoice (`billing/page.tsx:641-642`).
    final sellerGstin = headerInvoice?.sellerGstin ?? '';
    final sellerState = headerInvoice?.sellerState ?? '';

    // Matches web's `monthLabel`/`fyLabel` fallbacks (`billing/page.tsx:639-640`)
    // — the backend never returns `gst_month_label`/`fiscal_year_label`, so
    // web always falls through to these locally-computed labels too.
    final now = DateTime.now();
    const monthNames = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final monthLabel = monthNames[now.month - 1];
    final fyLabel = 'FY ${now.year}-${(now.year + 1).toString().substring(2)}';

    return SchoolTenancyLayout(
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          // Pull-to-refresh + `AlwaysScrollableScrollPhysics` — matches
          // Admin Home's own scroll behavior exactly.
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(invoicesProvider);
              ref.invalidate(billingMrrProvider);
              ref.invalidate(plansProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PAGE HEADER — its own card, same white/bordered style as
                  // every section below it, instead of floating text directly
                  // on the page background.
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      border: Border.all(color: AppColors.borderPrimary),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Web's actual title is "Tenants & Billing", not
                        // "Billing & Revenue" (`billing/page.tsx:650-652`).
                        Wrap(
                          spacing: 6,
                          children: [
                            Text('Tenants &', style: AppTextStyles.pageTitle),
                            Text(
                              'Billing',
                              style: AppTextStyles.pageTitleAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Matches web's subtitle exactly (`billing/page.tsx:653-661`).
                        Text.rich(
                          TextSpan(
                            style: AppTextStyles.pageSubtitle,
                            children: [
                              const TextSpan(
                                text:
                                    'GST-compliant invoicing across all schools. ',
                              ),
                              if (sellerGstin.isNotEmpty)
                                TextSpan(
                                  children: [
                                    const TextSpan(text: '· Seller GSTIN '),
                                    TextSpan(
                                      text: sellerGstin,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const TextSpan(text: ' '),
                                  ],
                                ),
                              if (sellerState.isNotEmpty)
                                TextSpan(text: '· $sellerState. '),
                              const TextSpan(
                                text:
                                    'Place of supply auto-detected from buyer state code · IGST for inter-state, CGST + SGST for intra-state.',
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
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.download, size: 14),
                              label: const Text('Export GSTR-1'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(
                                  color: AppColors.borderPrimary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                textStyle: AppTextStyles.buttonPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // KPI CARDS
                  // `KpiCardGrid` (width-constrained, height-intrinsic tiles)
                  // instead of a fixed-`childAspectRatio` `GridView` — a forced
                  // ratio gives every card the same height regardless of its
                  // actual label/value/footnote content, overflowing on narrow
                  // phones (confirmed: 78.9px cells vs. content needing more).
                  CompactKpiCardGrid(
                    spacing: 12,
                    crossAxisCount: 2,
                    cards: [
                      CompactKpiCard(
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
                      CompactKpiCard(
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
                      CompactKpiCard(
                        label: 'Outstanding',
                        value: mrr == null
                            ? '—'
                            : _formatINR(mrr.outstandingAmount),
                        sparklineData: null,
                        sparklineColor: const Color(0xFFE0463A),
                        // Web's `outstanding_count`/`outstanding_avg_overdue_days`
                        // also aren't returned by the backend, so web shows no
                        // trend and the generic footnote here too.
                        trend: null,
                        trendColor: AppColors.dangerRed,
                        footnote: 'Open receivables',
                      ),
                      CompactKpiCard(
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

                  const SizedBox(height: 16),

                  // PLANS — wrapped in a bordered card matching web's
                  // `<section className="rounded-2xl border ...">`
                  // (`billing/page.tsx:748`).
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      border: Border.all(color: AppColors.borderPrimary),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
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
                              child: const Icon(
                                Icons.receipt_long,
                                size: 16,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Subscription plans',
                                    style: AppTextStyles.sectionTitle,
                                  ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                textStyle: AppTextStyles.buttonPrimary.copyWith(
                                  fontSize: 11.5,
                                ),
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
                            child: Center(
                              child: Text(
                                'No plans configured.',
                                style: AppTextStyles.sectionSubtitle,
                              ),
                            ),
                          )
                        else
                          // `KpiCardGrid` (width-constrained, height-intrinsic
                          // tiles) instead of a fixed-`childAspectRatio`
                          // `GridView` — a forced ratio gives every card the
                          // same height regardless of its actual content
                          // (name/price/description/buttons), which is what
                          // made the 18px card padding read as "excessive":
                          // the content area was being squeezed shorter than
                          // it needed while the padding stayed fixed. Reusing
                          // the same widget already used for KPI rows (Schools/
                          // Dashboard/Audit Log tabs) keeps card sizing
                          // consistent across the module too.
                          //
                          // `crossAxisCount` is now responsive (1 column
                          // below 380px, otherwise 2) instead of always 2 —
                          // a fixed 2-column split squeezed each plan card to
                          // ~135px on a narrow phone, forcing the name/price/
                          // description to wrap onto extra lines and
                          // inflating card height; a single full-width
                          // column on narrow screens lets that same text sit
                          // on fewer lines instead.
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return KpiCardGrid(
                                spacing: 14,
                                crossAxisCount: constraints.maxWidth < 380 ? 1 : 2,
                                cards: plans.plans
                                    .map((p) => _buildPlanCard(p))
                                    .toList(),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // RECENT INVOICES — a compact card per invoice for mobile
                  // (was a desktop-style dense table row); tapping a card
                  // opens the full Tax Invoice on its own dedicated screen
                  // (`InvoiceDetailPage`) instead of previewing inline.
                  _buildRecentInvoicesList(invoices, fyLabel),

                  const SizedBox(height: 20),
                ],
              ),
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
        // `Flexible` + ellipsis — a `Wrap` gives a lone item on its own line
        // up to the wrap's full width, but nothing shrinks the `Text`
        // itself, so a long place-of-supply/date-range string (e.g. "01 Aug
        // 2026 · Due 15 Aug 2026") could overflow a narrow phone card.
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _openNewInvoiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const NewInvoiceSheet(),
    ).then((created) {
      if (created is InvoiceEntity && mounted) {
        // Matches web's exact toast text — `toast.success(\`Invoice
        // ${created.invoice_number} ${statusValue === 'sent' ? 'sent' :
        // 'saved as draft'}.\`)` (`NewInvoiceDrawer.tsx:377`).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invoice ${created.invoiceNumber} ${created.status == 'sent' ? 'sent' : 'saved as draft'}.',
            ),
          ),
        );
      }
    });
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
      await saveBytesForDownload(
        bytes: bytes,
        filename: 'gstr1-report-$stamp.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Matches web's exact toast text — `toast.success('GSTR-1
          // exported.')` (`billing/page.tsx:617`).
          const SnackBar(content: Text('GSTR-1 exported.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('GSTR-1 export failed: $e')));
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PlanFormSheet(existing: existing),
    ).then((saved) {
      if (saved is SubscriptionPlanEntity && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan "${saved.name}" ${existing != null ? 'updated' : 'created'}.',
            ),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Plan "${plan.name}" deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  /// Recent invoices, redesigned for mobile — each invoice is a compact,
  /// tap-to-open card (invoice no., school, place of supply, issued/due
  /// date, tax type, status) instead of the old dense per-row block that
  /// packed in amount/GSTIN/SAC/action-icons all at once. Full details and
  /// actions (Download/Send/Record payment/Edit/Cancel) now live on the
  /// dedicated [InvoiceDetailPage] opened on tap — same invoice data, same
  /// backend calls, just moved off the list card per that page's own header
  /// icon+title+subtitle+button treatment (matches Subscription plans).
  Widget _buildRecentInvoicesList(
    PaginatedInvoicesEntity invoices,
    String fyLabel,
  ) {
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
                decoration: BoxDecoration(
                  color: AppColors.purpleTint,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent invoices', style: AppTextStyles.sectionTitle),
                    Text(
                      '${invoices.results.length} of ${invoices.count} invoices · $fyLabel',
                      style: AppTextStyles.sectionSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _exportBusy ? null : _exportGstr1,
                icon: _exportBusy
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 13),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  textStyle: AppTextStyles.buttonSecondary.copyWith(
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (invoices.results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No invoices yet.',
                  style: AppTextStyles.sectionSubtitle,
                ),
              ),
            )
          else
            ...invoices.results.map((invoice) => _buildInvoiceCard(invoice)),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceEntity invoice) {
    final inter = _isInterState(invoice);
    final buyerCode = _stateCode(invoice.buyerState);
    final dueDate = DateTime.tryParse(invoice.dueDate);
    final daysOverdue = (dueDate != null && invoice.status == 'overdue')
        ? DateTime.now().difference(dueDate).inDays.clamp(0, 999999)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderPrimary),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Matches web's row click exactly — `onClick={() =>
        // setSelected(inv)}` (`billing/page.tsx:868`) — here it opens the
        // dedicated detail screen instead of an inline preview.
        onTap: () => _openInvoiceDetail(invoice),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber,
                      style: AppTextStyles.boardLabel.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    label: daysOverdue != null
                        ? '${_statusLabel(invoice.status)} · ${daysOverdue}d'
                        : _statusLabel(invoice.status),
                    color: _getStatusColor(invoice.status),
                    showDot: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                invoice.schoolName,
                style: AppTextStyles.boardLabel.copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _metaChip(
                    Icons.place_outlined,
                    '${buyerCode.isNotEmpty ? '$buyerCode — ' : ''}${invoice.buyerState.isEmpty ? '—' : invoice.buyerState}',
                  ),
                  _metaChip(
                    Icons.calendar_today_outlined,
                    '${_formatDate(invoice.invoiceDate)} · Due ${_formatDate(invoice.dueDate)}',
                  ),
                  _metaChip(
                    Icons.receipt_long_outlined,
                    inter ? 'IGST 18%' : 'CGST+SGST 18%',
                  ),
                ],
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                  style: AppTextStyles.sectionSubtitle.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (popular)
                // `Flexible` — on very narrow cards the badge's own natural
                // width (padding + "POPULAR" glyphs) can slightly exceed
                // whatever the Row has left after the flexible name Text,
                // overflowing the Row even though a sibling is `Expanded`.
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'POPULAR',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.chipLabel(color: Colors.white)
                          .copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
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
                child: Text(
                  '/mo',
                  style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plan.description,
            style: AppTextStyles.sectionSubtitle.copyWith(
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
          // `Spacer` requires a bounded-height ancestor — fine under the old
          // fixed-aspect-ratio grid cell, but these cards now size to their
          // own content inside `KpiCardGrid`'s `Wrap` (intrinsic height,
          // unbounded), so a fixed gap replaces it.
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openPlanFormSheet(existing: plan),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: popular
                          ? AppColors.primaryPurple
                          : AppColors.borderPrimary,
                    ),
                    foregroundColor: popular
                        ? AppColors.primaryPurple
                        : AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Compact, explicit padding (was vertical-only, leaving
                    // the button wider than it needed to be next to the
                    // now-also-compact Delete icon).
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 6),
              // Compact icon button — a bare `IconButton` defaults to a
              // large ~48dp tap target/padding, which looked oversized next
              // to the now-tighter Edit button and card padding.
              IconButton(
                onPressed: () => _confirmDeletePlan(plan),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.dangerRed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
