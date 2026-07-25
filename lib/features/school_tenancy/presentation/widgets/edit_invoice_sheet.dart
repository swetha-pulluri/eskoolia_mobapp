import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/school_tenancy_provider.dart';

/// Mobile equivalent of web's `NewInvoiceDrawer` in edit mode
/// (`billing/NewInvoiceDrawer.tsx`, `isEditMode` branch) — the backend's
/// `InvoiceUpdateSerializer` only accepts `status`/`due_date`/`notes`/
/// `terms_conditions` ("Intentionally restricted to fields that do not
/// change GST-relevant amounts" — `serializers.py`), so unlike the full
/// New Invoice sheet, school/plan/line-items/amounts are shown read-only
/// for context only, not editable.
class EditInvoiceSheet extends ConsumerStatefulWidget {
  const EditInvoiceSheet({super.key, required this.invoice});

  final InvoiceEntity invoice;

  @override
  ConsumerState<EditInvoiceSheet> createState() => _EditInvoiceSheetState();
}

class _EditInvoiceSheetState extends ConsumerState<EditInvoiceSheet> {
  late DateTime _dueDate = DateTime.tryParse(widget.invoice.dueDate) ?? DateTime.now();
  late String _status = widget.invoice.status;
  late final _notesController = TextEditingController(text: widget.invoice.notes ?? '');
  late final _termsController = TextEditingController(text: widget.invoice.termsConditions ?? '');
  bool _submitting = false;

  bool get _locked => widget.invoice.status == 'paid' || widget.invoice.status == 'cancelled';

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDueDate() async {
    final invoiceDate = DateTime.tryParse(widget.invoice.invoiceDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: invoiceDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final updated = await repository.updateInvoice(widget.invoice.id, {
        'status': _status,
        'due_date': _isoDate(_dueDate),
        'notes': _notesController.text.trim(),
        'terms_conditions': _termsController.text.trim(),
      });
      ref.invalidate(invoicesProvider);
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.edit_outlined, size: 17, color: AppColors.purpleDeep),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Edit ', style: AppTextStyles.sectionTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
                            Text('Invoice', style: AppTextStyles.pageTitleAccent.copyWith(fontSize: 19)),
                          ],
                        ),
                        Text('Invoice ${widget.invoice.invoiceNumber}', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Matches web's lock banners exactly
                    // (`NewInvoiceDrawer.tsx:533-560`).
                    if (widget.invoice.status == 'paid')
                      _banner(
                        color: AppColors.dangerRed,
                        title: 'This invoice is paid and cannot be edited',
                        body: 'Paid invoices are locked to preserve the audit trail and GST compliance. '
                            'To make corrections, cancel this invoice and re-issue a new one.',
                      )
                    else if (widget.invoice.status == 'cancelled')
                      _banner(
                        color: AppColors.dangerRed,
                        title: 'This invoice is cancelled and cannot be edited',
                        body: 'Cancelled invoices are locked to preserve the audit trail.',
                      )
                    else
                      _banner(
                        color: AppColors.warningAmber,
                        title: 'Editing an issued invoice',
                        body: 'School, line items, amounts and GST cannot be modified once issued. To correct '
                            'those, cancel this invoice and create a new one. You can still update status, '
                            'due date, notes and payment terms here.',
                      ),
                    const SizedBox(height: 16),

                    Text('SCHOOL', style: _label),
                    const SizedBox(height: 6),
                    _readonlyField(widget.invoice.buyerName.isEmpty ? widget.invoice.schoolName : widget.invoice.buyerName),
                    const SizedBox(height: 14),

                    Text('AMOUNT', style: _label),
                    const SizedBox(height: 6),
                    _readonlyField(formatINR(widget.invoice.taxBreakdown.grandTotal, compact: false), mono: true),
                    const SizedBox(height: 14),

                    Text('DUE DATE', style: _label),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _locked ? null : _pickDueDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _locked ? AppColors.bgTertiary : AppColors.bgSecondary,
                          border: Border.all(color: AppColors.borderPrimary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_isoDate(_dueDate), style: AppTextStyles.boardLabel.copyWith(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('STATUS', style: _label),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'sent', child: Text('Sent')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: _locked ? null : (v) => setState(() => _status = v ?? _status),
                    ),
                    const SizedBox(height: 14),

                    Text('NOTES', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      enabled: !_locked,
                      maxLines: 3,
                      decoration: _fieldDecoration(),
                    ),
                    const SizedBox(height: 14),

                    Text('PAYMENT TERMS', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _termsController,
                      enabled: !_locked,
                      maxLines: 3,
                      decoration: _fieldDecoration(),
                    ),
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
                      onPressed: (_submitting || _locked) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: Text(_submitting ? 'Saving…' : 'Save changes'),
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

  Widget _banner({required Color color, required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: AppTextStyles.boardLabel.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }

  Widget _readonlyField(String value, {bool mono = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value, style: AppTextStyles.boardLabel.copyWith(fontSize: 13, fontFamily: mono ? 'monospace' : null)),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.bgSecondary,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
