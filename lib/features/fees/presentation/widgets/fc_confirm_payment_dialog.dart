import 'package:flutter/material.dart';
import '../utils/fee_assignment_format.dart' show fmtRs;
import '../utils/fees_collection_format.dart' show resolvedDueAmount, resolvedTotal;
import 'fees_collection_models.dart';
import 'fees_collection_styles.dart';

/// "Confirm {method} Payment" modal — mirrors FeesCollectionPanel.tsx's
/// `showConfirm` block (§11 of the port spec). Owns nothing about the
/// actual posting — [onConfirm] does the real work (API calls + refresh +
/// toast) and returns whether it succeeded; this dialog only closes itself
/// on success, mirroring the source's `postPayment` closing `showConfirm`
/// only in the try-succeeded path.
class FcConfirmPaymentDialog extends StatefulWidget {
  final String studentName;
  final String admNo;
  final String cls;
  final String method;
  final List<FcDue> selDues;
  final String amtPaidText;
  final String rcptPreview;
  final String initialCollectedBy;
  final String initialCounter;
  final bool initialPrintNow;
  final bool initialSendSms;
  final ValueChanged<String> onCollectedByChanged;
  final ValueChanged<String> onCounterChanged;
  final ValueChanged<bool> onPrintNowChanged;
  final ValueChanged<bool> onSendSmsChanged;
  final Future<bool> Function() onConfirm;

  const FcConfirmPaymentDialog({
    super.key,
    required this.studentName,
    required this.admNo,
    required this.cls,
    required this.method,
    required this.selDues,
    required this.amtPaidText,
    required this.rcptPreview,
    required this.initialCollectedBy,
    required this.initialCounter,
    required this.initialPrintNow,
    required this.initialSendSms,
    required this.onCollectedByChanged,
    required this.onCounterChanged,
    required this.onPrintNowChanged,
    required this.onSendSmsChanged,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String studentName,
    required String admNo,
    required String cls,
    required String method,
    required List<FcDue> selDues,
    required String amtPaidText,
    required String rcptPreview,
    required String initialCollectedBy,
    required String initialCounter,
    required bool initialPrintNow,
    required bool initialSendSms,
    required ValueChanged<String> onCollectedByChanged,
    required ValueChanged<String> onCounterChanged,
    required ValueChanged<bool> onPrintNowChanged,
    required ValueChanged<bool> onSendSmsChanged,
    required Future<bool> Function() onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierColor: const Color(0x660E1020), // rgba(14,16,32,0.40)
      builder: (_) => FcConfirmPaymentDialog(
        studentName: studentName,
        admNo: admNo,
        cls: cls,
        method: method,
        selDues: selDues,
        amtPaidText: amtPaidText,
        rcptPreview: rcptPreview,
        initialCollectedBy: initialCollectedBy,
        initialCounter: initialCounter,
        initialPrintNow: initialPrintNow,
        initialSendSms: initialSendSms,
        onCollectedByChanged: onCollectedByChanged,
        onCounterChanged: onCounterChanged,
        onPrintNowChanged: onPrintNowChanged,
        onSendSmsChanged: onSendSmsChanged,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<FcConfirmPaymentDialog> createState() => _FcConfirmPaymentDialogState();
}

class _FcConfirmPaymentDialogState extends State<FcConfirmPaymentDialog> {
  late final TextEditingController _collectedByCtrl;
  late String _counter;
  late bool _printNow;
  late bool _sendSms;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _collectedByCtrl = TextEditingController(text: widget.initialCollectedBy);
    _counter = widget.initialCounter;
    _printNow = widget.initialPrintNow;
    _sendSms = widget.initialSendSms;
  }

  @override
  void dispose() {
    _collectedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _posting = true);
    final ok = await widget.onConfirm();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = resolvedTotal(widget.selDues, widget.amtPaidText);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 64, offset: Offset(0, 24))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Confirm ${widget.method} Payment', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fcInk1)),
                              const SizedBox(height: 3),
                              const Text('Verify before posting — this cannot be undone without a reversal.', style: TextStyle(fontSize: 12, color: fcInk3)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: fcBorder)),
                            child: const Text('×', style: TextStyle(fontSize: 17, color: fcInk3, height: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: fcBorder),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            const Text('Amount to post', style: TextStyle(fontSize: 12.5, color: fcInk3)),
                            const SizedBox(height: 8),
                            Text(fmtRs(total), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: fcPurple, height: 1)),
                            const SizedBox(height: 8),
                            Text('${widget.studentName} · ${widget.admNo} · Class ${widget.cls}', style: const TextStyle(fontSize: 13, color: fcInk3)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(10)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final d in widget.selDues)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: const BoxDecoration(color: fcPurpleTintRow, border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(d.label, style: const TextStyle(fontSize: 12.5, color: fcInk2))),
                                      Text(fmtRs(resolvedDueAmount(d, widget.selDues.length, widget.amtPaidText)), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fcInk1)),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Receipt No (preview)', style: TextStyle(fontSize: 13, color: fcInk2)),
                                    Text(widget.rcptPreview, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fcInk1)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Payment Method', style: TextStyle(fontSize: 13, color: fcInk2)),
                                    Text(widget.method, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fcInk1)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: FcLabeledField(
                                label: 'COLLECTED BY',
                                field: TextField(
                                  controller: _collectedByCtrl,
                                  decoration: fcFieldDecoration(),
                                  onChanged: widget.onCollectedByChanged,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FcLabeledField(
                                label: 'COUNTER / DRAWER',
                                field: DropdownButtonFormField<String>(
                                  initialValue: _counter,
                                  isExpanded: true,
                                  decoration: fcFieldDecoration(),
                                  items: const [
                                    DropdownMenuItem(value: 'Counter 1', child: Text('Counter 1')),
                                    DropdownMenuItem(value: 'Counter 2', child: Text('Counter 2')),
                                    DropdownMenuItem(value: 'Counter 3', child: Text('Counter 3')),
                                    DropdownMenuItem(value: 'Cashier Office', child: Text('Cashier Office')),
                                  ],
                                  onChanged: (v) {
                                    final val = v ?? 'Counter 1';
                                    setState(() => _counter = val);
                                    widget.onCounterChanged(val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        CheckboxListTile(
                          value: _printNow,
                          onChanged: (v) {
                            final val = v ?? false;
                            setState(() => _printNow = val);
                            widget.onPrintNowChanged(val);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: fcPurple,
                          title: const Text('Print receipt now', style: TextStyle(fontSize: 13.5, color: fcInk1)),
                        ),
                        CheckboxListTile(
                          value: _sendSms,
                          onChanged: (v) {
                            final val = v ?? false;
                            setState(() => _sendSms = val);
                            widget.onSendSmsChanged(val);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: fcPurple,
                          title: const Text('Send receipt to parent via SMS / app', style: TextStyle(fontSize: 13.5, color: fcInk1)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: fcBorder))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FcOutlineButton(label: 'Cancel', onPressed: _posting ? null : () => Navigator.of(context).pop()),
                        const SizedBox(width: 12),
                        FcPrimaryButton(label: _posting ? 'Posting…' : 'Post ${widget.method} Payment', busy: _posting, onPressed: _submit),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
