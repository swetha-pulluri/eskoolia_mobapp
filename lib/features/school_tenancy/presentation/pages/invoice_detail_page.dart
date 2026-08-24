import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/new_invoice_sheet.dart';
import '../widgets/record_payment_sheet.dart';
import '../utils/invoice_pdf.dart';

/// Dedicated invoice-details screen — reached by tapping a card in the
/// Billing tab's "Recent invoices" list. Shows the exact same Tax Invoice
/// preview (invoice body, GST breakdown, tax logic, actions) that used to
/// render inline on the Billing page for the "selected" invoice
/// (`billing_tab.dart`'s old `_buildTaxInvoiceCard`), now on its own screen
/// with a back button — no invoice data, API calls, or business logic
/// changed, only where this content is displayed.
class InvoiceDetailPage extends ConsumerStatefulWidget {
  final InvoiceEntity invoice;
  final String sellerGstin;
  final String sellerState;

  const InvoiceDetailPage({
    super.key,
    required this.invoice,
    required this.sellerGstin,
    required this.sellerState,
  });

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  late InvoiceEntity _invoice = widget.invoice;

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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
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

  String _stateCode(String state) => _stateCodes[state.trim().toLowerCase()] ?? '';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => RecordPaymentSheet(invoice: invoice),
    ).then((result) {
      if (result is RecordPaymentResultEntity && mounted) {
        setState(() => _invoice = result.invoice);
        final remaining = result.invoice.dueAmount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remaining > 0
                  ? 'Recorded ${formatINR(result.payment.amount, compact: false)}. Remaining due ${formatINR(remaining, compact: false)}.'
                  : 'Invoice ${result.invoice.invoiceNumber} fully paid.',
            ),
          ),
        );
      }
    });
  }

  void _openEditInvoiceSheet(InvoiceEntity invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NewInvoiceSheet(invoice: invoice),
    ).then((updated) {
      if (updated is InvoiceEntity && mounted) {
        setState(() => _invoice = updated);
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
        const SnackBar(
          content: Text(
            'Paid invoices cannot be cancelled. Issue a credit note instead.',
          ),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
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
        setState(() => _invoice = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${updated.invoiceNumber} cancelled.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cancel invoice failed: $e')));
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
          SnackBar(
            content: Text(
              'Reminder recorded for ${result.invoiceNumber} (status: ${_statusLabel(result.status)}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Send reminder failed: $e')));
      }
    }
  }

  Future<void> _downloadInvoicePdf(
    InvoiceEntity invoice, {
    required String sellerGstin,
    required String sellerState,
  }) async {
    try {
      final path = await downloadInvoicePdf(
        invoice,
        sellerGstin: sellerGstin,
        sellerState: sellerState,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Back to invoices'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              _buildTaxInvoiceCard(_invoice, widget.sellerGstin, widget.sellerState),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Matches web's `TaxInvoiceCard` (`billing/page.tsx:296-530`) — a 2-column
  /// desktop grid (invoice body + GST breakdown/Tax logic/Actions), stacked
  /// into a single column here for mobile width. Moved verbatim from
  /// `billing_tab.dart`'s old inline "selected invoice" preview.
  Widget _buildTaxInvoiceCard(
    InvoiceEntity invoice,
    String sellerGstin,
    String sellerState,
  ) {
    final inter = _isInterState(invoice);
    final tax = invoice.taxBreakdown;
    final sellerCode = _stateCode(
      sellerState.isNotEmpty ? sellerState : invoice.sellerState,
    );
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
                        Text(
                          'Tax Invoice',
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 22,
                            fontFamily: 'serif',
                          ),
                        ),
                        Text(
                          'ORIGINAL FOR RECIPIENT',
                          style: AppTextStyles.sectionSubtitle.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 2, right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'e',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          invoice.sellerName,
                          style: AppTextStyles.boardLabel.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          '12th Floor, Bagmane Tech Park, CV Raman Nagar, Bengaluru, ${sellerState.isNotEmpty ? sellerState : invoice.sellerState} 560048 · India',
                          style: AppTextStyles.sectionSubtitle.copyWith(
                            fontSize: 10.5,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          'GSTIN ${(sellerGstin.isNotEmpty ? sellerGstin : invoice.sellerGstin).isEmpty ? '—' : (sellerGstin.isNotEmpty ? sellerGstin : invoice.sellerGstin)}',
                          style: AppTextStyles.sectionSubtitle.copyWith(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              _invoiceInfoBlock('BILLED TO', [
                invoice.buyerName.isEmpty
                    ? invoice.schoolName
                    : invoice.buyerName,
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
              Text(
                'LINE ITEMS',
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              // Matches web's 5-column table (Description/SAC/Qty/Rate/
              // Amount, `billing/page.tsx:398-419`) restructured as a
              // 2-line block per item for mobile width. This header mirrors
              // each row's own Expanded+left / fixed+right alignment exactly
              // (row 1: description ↔ SAC, row 2: qty×rate ↔ amount) so the
              // headings actually line up with the values underneath them.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'DESCRIPTION',
                      style: AppTextStyles.sectionSubtitle.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SAC',
                    style: AppTextStyles.sectionSubtitle.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'QTY × RATE',
                      style: AppTextStyles.sectionSubtitle.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AMOUNT',
                    style: AppTextStyles.sectionSubtitle.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...invoice.lineItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.description,
                              style: AppTextStyles.boardLabel.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SAC ${item.sacCode}',
                            style: AppTextStyles.sectionSubtitle.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity} × ${_formatINR(item.unitPrice, compact: false, symbol: false)}',
                              style: AppTextStyles.sectionSubtitle.copyWith(
                                fontSize: 11.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatINR(
                              item.amount,
                              compact: false,
                              symbol: false,
                            ),
                            style: AppTextStyles.boardLabel.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
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
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.sectionSubtitle.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Amount in words · ',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(
                        text: tax.amountInWords,
                        style: AppTextStyles.boardLabel.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'PAYMENT TERMS',
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Payable within 15 days of invoice date. Bank transfer to HDFC 0000123456789 · IFSC HDFC0001234 · '
                'A/c name Eskoolia Technologies Pvt Ltd · UPI eskoolia@hdfcbank · Reference ${invoice.invoiceNumber} in remittance.',
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'For ${invoice.sellerName.isEmpty ? 'Eskoolia Technologies Pvt Ltd' : invoice.sellerName}',
                      style: AppTextStyles.sectionSubtitle.copyWith(
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Authorised Signatory',
                      style: AppTextStyles.boardLabel.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Text(
                'NOTES',
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Whether tax payable under reverse charge — ${invoice.reverseCharge ? 'Yes' : 'No'}. This is a computer-generated invoice; signature not required if digitally signed.',
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // GST breakdown, Tax logic applied, Invoice actions — each its own
        // bordered card, stacked below the invoice body on mobile.
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
              Text(
                'GST BREAKDOWN',
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              _totalRow('Taxable value', tax.subtotal),
              if (inter) _totalRow('IGST · 18%', tax.igst ?? 0),
              if (!inter) _totalRow('CGST · 9%', tax.cgst ?? 0),
              if (!inter) _totalRow('SGST · 9%', tax.sgst ?? 0),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total invoice',
                      style: AppTextStyles.boardLabel.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatINR(tax.grandTotal, compact: false),
                    style: AppTextStyles.boardLabel.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successGreen,
                    ),
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
              Text(
                'TAX LOGIC APPLIED',
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              _logicRow(
                'Seller state',
                '${sellerCode.isNotEmpty ? '$sellerCode ' : ''}${sellerState.isNotEmpty ? sellerState : invoice.sellerState}',
              ),
              _logicRow(
                'Buyer state',
                '${buyerCode.isNotEmpty ? '$buyerCode ' : ''}${invoice.buyerState}',
              ),
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
              Text(
                'INVOICE ACTIONS',
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              // Web itself uses the browser's native window.print() for this
              // (`handleDownloadPdf`) on the same on-screen invoice — this
              // builds an equivalent real PDF from the same data and saves
              // it directly (no print/share dialog), matching "download".
              _actionRow(
                context,
                Icons.download_outlined,
                'Download PDF',
                () => _downloadInvoicePdf(
                  invoice,
                  sellerGstin: sellerGstin,
                  sellerState: sellerState,
                ),
              ),
              // Real call to POST /billing/invoices/{id}/reminder/.
              _actionRow(
                context,
                Icons.send_outlined,
                'Send to buyer',
                () => _sendReminder(invoice),
              ),
              // Real call — opens Record Payment, which posts to
              // POST /billing/invoices/{id}/payments/. Matches web's exact
              // label logic (`billing/page.tsx`, `git show f956c3ce`).
              _actionRow(
                context,
                Icons.check_circle_outline,
                invoice.status == 'partially_paid'
                    ? 'Record payment'
                    : 'Record payment / Mark paid',
                (invoice.status == 'paid' || invoice.status == 'cancelled')
                    ? null
                    : () => _openRecordPaymentSheet(invoice),
              ),
              // Real call — opens Edit Invoice, which PATCHes
              // /billing/invoices/{id}/ (status/due_date/notes/terms only).
              _actionRow(
                context,
                Icons.edit_outlined,
                'Edit invoice',
                () => _openEditInvoiceSheet(invoice),
              ),
              // Real call to DELETE /billing/invoices/{id}/ (cancels, does
              // not hard-delete) — matches web's `handleCancel()` exactly.
              _actionRow(
                context,
                Icons.block,
                'Cancel invoice',
                invoice.status == 'cancelled'
                    ? null
                    : () => _confirmCancelInvoice(invoice),
                danger: true,
              ),
            ],
          ),
        ),
      ],
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
        Text(
          'INVOICE DETAILS',
          style: AppTextStyles.sectionSubtitle.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Invoice no.',
          style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
        ),
        Text(
          invoice.invoiceNumber,
          style: AppTextStyles.boardLabel.copyWith(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Invoice date',
          style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
        ),
        Text(
          _formatDate(invoice.invoiceDate),
          style: AppTextStyles.boardLabel.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
            children: [
              const TextSpan(text: 'Due date '),
              TextSpan(
                text: _formatDate(invoice.dueDate),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
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
        Text(
          label,
          style: AppTextStyles.sectionSubtitle.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        ...lines.map(
          (l) =>
              Text(l, style: AppTextStyles.boardLabel.copyWith(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.sectionSubtitle.copyWith(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatINR(value, compact: false),
            style: AppTextStyles.boardLabel.copyWith(
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
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
          Text(
            label,
            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5),
          ),
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

  Widget _actionRow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? AppColors.dangerRed : AppColors.textPrimary,
          side: BorderSide(
            color: danger
                ? AppColors.dangerRed.withValues(alpha: 0.4)
                : AppColors.borderPrimary,
          ),
          backgroundColor: danger
              ? AppColors.dangerRed.withValues(alpha: 0.06)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
