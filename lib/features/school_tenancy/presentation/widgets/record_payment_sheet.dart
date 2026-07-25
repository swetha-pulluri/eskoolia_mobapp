import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/school_tenancy_provider.dart';

/// Mobile equivalent of web's `RecordPaymentModal`
/// (`billing/RecordPaymentModal.tsx`) — records a full or partial payment
/// against an invoice via `POST /billing/invoices/{id}/payments/`. The
/// backend recomputes `paid_amount`/`due_amount` and derives status
/// (`partially_paid` vs `paid`) from the payment ledger.
class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({super.key, required this.invoice});

  final InvoiceEntity invoice;

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();

  static const methods = [
    {'value': 'bank_transfer', 'label': 'Bank Transfer'},
    {'value': 'upi', 'label': 'UPI'},
    {'value': 'cheque', 'label': 'Cheque'},
    {'value': 'cash', 'label': 'Cash'},
    {'value': 'razorpay', 'label': 'Razorpay'},
    {'value': 'stripe', 'label': 'Stripe'},
    {'value': 'adjustment', 'label': 'Adjustment / Credit Note'},
    {'value': 'other', 'label': 'Other'},
  ];
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  late final double _grandTotal = widget.invoice.taxBreakdown.grandTotal;
  late final double _alreadyPaid = widget.invoice.paidAmount;
  late final double _initialDue = (widget.invoice.dueAmount > 0 ? widget.invoice.dueAmount : (_grandTotal - _alreadyPaid)).clamp(0, double.infinity).toDouble();

  late final _amountController = TextEditingController(text: _initialDue.toStringAsFixed(2));
  DateTime _paidOn = DateTime.now();
  String _method = 'bank_transfer';
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String _error = '';
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _numericAmount => double.tryParse(_amountController.text.trim()) ?? 0;

  bool get _willFullySettle => _numericAmount >= _initialDue - 0.005 && _numericAmount > 0;

  String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _paidOn, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _paidOn = picked);
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    if (_numericAmount <= 0) {
      setState(() => _error = 'Enter a payment amount greater than 0.');
      return;
    }
    if (_numericAmount > _initialDue + 0.005) {
      setState(() => _error = 'Amount cannot exceed outstanding ${formatINR(_initialDue, compact: false)}.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        'amount': _numericAmount,
        'paid_on': _isoDate(_paidOn),
        'method': _method,
        if (_referenceController.text.trim().isNotEmpty) 'reference_no': _referenceController.text.trim(),
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      };
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final result = await repository.recordInvoicePayment(widget.invoice.id, payload);
      ref.invalidate(invoicesProvider);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      setState(() => _error = 'Failed to record payment: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RECORD PAYMENT', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                        Text(widget.invoice.invoiceNumber, style: AppTextStyles.sectionTitle.copyWith(fontSize: 16, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          _totalStat('TOTAL', _grandTotal, AppColors.textPrimary),
                          _totalStat('PAID', _alreadyPaid, AppColors.successGreen),
                          _totalStat('DUE', _initialDue, AppColors.warningAmber),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('AMOUNT (₹)', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _fieldDecoration(),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _willFullySettle
                          ? 'This will fully settle the invoice (status → Paid).'
                          : 'Partial amount allowed (status → Partially Paid).',
                      style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PAID ON', style: _label),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSecondary,
                                    border: Border.all(color: AppColors.borderPrimary),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_isoDate(_paidOn), style: AppTextStyles.boardLabel.copyWith(fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('METHOD', style: _label),
                              const SizedBox(height: 6),
                              AppDropdown<String>(
                                value: _method,
                                items: RecordPaymentSheet.methods
                                    .map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (v) => setState(() => _method = v ?? 'bank_transfer'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text('REFERENCE NO. (UTR / CHEQUE / TXN)', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _referenceController,
                      decoration: _fieldDecoration().copyWith(hintText: 'Optional'),
                    ),
                    const SizedBox(height: 14),

                    Text('NOTES', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: _fieldDecoration().copyWith(hintText: 'Optional'),
                    ),

                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_error, style: const TextStyle(fontSize: 11.5, color: AppColors.dangerRed)),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_submitting || _initialDue <= 0) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: Text(_submitting ? 'Recording…' : (_willFullySettle ? 'Settle invoice' : 'Record partial payment')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle get _label => AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6);

  Widget _totalStat(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
          const SizedBox(height: 2),
          Text(
            formatINR(value, compact: false),
            style: AppTextStyles.boardLabel.copyWith(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.bgSecondary,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
