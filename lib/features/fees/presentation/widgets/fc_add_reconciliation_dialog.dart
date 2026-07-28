import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/fees_reconciliation.dart';
import '../providers/fees_collection_providers.dart';
import 'fees_collection_styles.dart';

/// "Add Reconciliation Record" modal — mirrors FeesCollectionPanel.tsx's
/// `showReconModal` block (§8 of the port spec) field-for-field, including
/// its exact validation order/messages.
class FcAddReconciliationDialog extends ConsumerStatefulWidget {
  final void Function(String message) onToast;
  const FcAddReconciliationDialog({super.key, required this.onToast});

  static Future<FeesReconciliation?> show(BuildContext context, {required void Function(String) onToast}) {
    return showDialog<FeesReconciliation>(
      context: context,
      barrierColor: const Color(0x73000000), // rgba(0,0,0,0.45)
      builder: (_) => FcAddReconciliationDialog(onToast: onToast),
    );
  }

  @override
  ConsumerState<FcAddReconciliationDialog> createState() => _FcAddReconciliationDialogState();
}

class _FcAddReconciliationDialogState extends ConsumerState<FcAddReconciliationDialog> {
  final _referenceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _matchNoteCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = 'bank';
  String _status = 'review';
  DateTime? _date;
  bool _saving = false;

  @override
  void dispose() {
    _referenceCtrl.dispose();
    _amountCtrl.dispose();
    _matchNoteCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_referenceCtrl.text.trim().isEmpty) {
      widget.onToast('Reference / UTR is required.');
      return;
    }
    final amountText = _amountCtrl.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      widget.onToast('Enter a valid amount.');
      return;
    }
    if (_date == null) {
      widget.onToast('Date is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final d = _date!;
      final dateStr = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final created = await ref.read(feesCollectionRepositoryProvider).createReconciliation(FeesReconciliation(
            reference: _referenceCtrl.text.trim(),
            amount: amountText,
            method: _method,
            date: dateStr,
            status: _status,
            matchNote: _matchNoteCtrl.text.trim(),
            notes: _notesCtrl.text.trim(),
            score: 0,
          ));
      if (mounted) Navigator.of(context).pop(created);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        widget.onToast('Failed to save. Please try again.');
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 40, offset: Offset(0, 12))],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Reconciliation Record', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fcInk1)),
                const SizedBox(height: 4),
                const Text('Manually log a bank / payment reference for matching against receipts.', style: TextStyle(fontSize: 13, color: fcInk3)),
                const SizedBox(height: 22),
                FcLabeledField(
                  label: 'REFERENCE / UTR *',
                  field: TextField(controller: _referenceCtrl, decoration: fcModalFieldDecoration(hintText: 'e.g. HDFC252705881 or CHQ842901')),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FcLabeledField(
                        label: 'AMOUNT *',
                        field: TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: fcModalFieldDecoration(hintText: '0.00'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FcLabeledField(
                        label: 'METHOD',
                        field: DropdownButtonFormField<String>(
                          initialValue: _method,
                          isExpanded: true,
                          decoration: fcModalFieldDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                            DropdownMenuItem(value: 'online', child: Text('Online / UPI')),
                            DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                            DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                          ],
                          onChanged: (v) => setState(() => _method = v ?? 'bank'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FcLabeledField(
                        label: 'DATE *',
                        field: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: fcModalFieldDecoration(hintText: 'YYYY-MM-DD'),
                            child: Text(
                              _date == null
                                  ? ''
                                  : '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 13, color: fcInk1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FcLabeledField(
                        label: 'STATUS',
                        field: DropdownButtonFormField<String>(
                          initialValue: _status,
                          isExpanded: true,
                          decoration: fcModalFieldDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'review', child: Text('Review')),
                            DropdownMenuItem(value: 'matched', child: Text('Matched')),
                            DropdownMenuItem(value: 'needs_mapping', child: Text('Needs Mapping')),
                          ],
                          onChanged: (v) => setState(() => _status = v ?? 'review'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FcLabeledField(
                  label: 'MATCH / CANDIDATE RECEIPT',
                  field: TextField(controller: _matchNoteCtrl, decoration: fcModalFieldDecoration(hintText: 'e.g. Matched to RCPT-25-4218 · Aditi Nair')),
                ),
                const SizedBox(height: 14),
                FcLabeledField(
                  label: 'NOTES',
                  field: TextField(controller: _notesCtrl, maxLines: 2, decoration: fcModalFieldDecoration(hintText: 'Any additional details…')),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FcOutlineButton(label: 'Cancel', onPressed: _saving ? null : () => Navigator.of(context).pop()),
                    const SizedBox(width: 10),
                    FcPrimaryButton(label: _saving ? 'Saving…' : 'Save Record', busy: _saving, onPressed: _save),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
