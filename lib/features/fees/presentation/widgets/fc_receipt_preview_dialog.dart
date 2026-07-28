import 'package:flutter/material.dart';
import '../../domain/models/school_header_info.dart';
import '../utils/fc_receipt_pdf.dart';
import '../utils/fee_assignment_format.dart' show groupIndian;
import 'fees_collection_models.dart';
import 'fees_collection_styles.dart';

class _StatusCfg {
  final String label;
  final Color bg;
  final Color color;
  const _StatusCfg(this.label, this.bg, this.color);
}

/// Same status→label/color mapping as `fc_receipt_pdf.dart`'s printed
/// receipt (kept as its own small map here since that file's is
/// PdfColor-typed and private) — the on-screen preview and the generated
/// PDF must show the same status pill.
const Map<String, _StatusCfg> _statusCfg = {
  'posted': _StatusCfg('Settled', Color(0xFFDCFCE7), Color(0xFF15803D)),
  'pending_clearance': _StatusCfg('Pending Clearance', Color(0xFFFEF3C7), Color(0xFFD97706)),
  'pending_reconciliation': _StatusCfg('Pending Reconciliation', Color(0xFFFEF3C7), Color(0xFFD97706)),
  'pending_verification': _StatusCfg('Pending Verification', Color(0xFFEDE9FE), Color(0xFF7C3AED)),
  'reversed': _StatusCfg('Reversed', Color(0xFFFEE2E2), Color(0xFFDC2626)),
};

const _methodLabel = {'cash': 'Cash', 'bank': 'Bank Transfer', 'online': 'Online / UPI', 'wallet': 'Wallet', 'cheque': 'Cheque'};

/// In-app screen shown when the "Receipt" action is tapped (Recent
/// Payments tab) — mirrors what the web app's `downloadReceipt` popup
/// shows visually (school header + RECEIPT badge, amount box, Payment
/// Details, Student Details, Notes, footer disclaimer) before the user
/// chooses to print/share the actual PDF via [shareReceiptPdf].
class FcReceiptPreviewDialog extends StatelessWidget {
  final FcPaymentRow payment;
  final SchoolHeaderInfo header;

  const FcReceiptPreviewDialog({super.key, required this.payment, required this.header});

  static Future<void> show(BuildContext context, {required FcPaymentRow payment, required SchoolHeaderInfo header}) {
    return showDialog(
      context: context,
      barrierColor: const Color(0x660E1020),
      builder: (_) => FcReceiptPreviewDialog(payment: payment, header: header),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _statusCfg[payment.status] ?? _statusCfg['posted']!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(context).size.height * 0.88),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    children: [
                      Expanded(child: Text('Receipt ${payment.rcpt}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fcInk1))),
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(10)),
                              child: const Text('🏫', style: TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(header.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: fcInk1)),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${header.address}${header.email.isNotEmpty ? '  ·  ${header.email}' : ''}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(color: fcPurple, borderRadius: BorderRadius.circular(20)),
                              child: const Text('RECEIPT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6)),
                            ),
                          ],
                        ),
                        Container(margin: const EdgeInsets.symmetric(vertical: 20), height: 2, color: fcBorder),
                        const Text('Payment Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fcInk1)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Text('Receipt No: ', style: TextStyle(fontSize: 13, color: fcInk3)),
                            Text(payment.rcpt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fcPurple)),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(color: const Color(0xFFF8F7FF), border: Border.all(color: fcPurple, width: 1.4), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Amount Paid', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fcPurple)),
                              Text('Rs. ${groupIndian(payment.amount.round().toString())}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: fcPurple)),
                            ],
                          ),
                        ),
                        _sectionHeader('PAYMENT DETAILS'),
                        _row('Date', payment.date.isEmpty ? '—' : payment.date),
                        _row('Payment Method', _methodLabel[payment.method] ?? payment.method),
                        if (payment.txRef.isNotEmpty) _row('Transaction Reference', payment.txRef),
                        if (payment.feeName.isNotEmpty) _row('Fee Type', payment.feeName),
                        _row(
                          'Status',
                          '',
                          valueWidget: FcStatusPill(label: cfg.label, bg: cfg.bg, color: cfg.color),
                        ),
                        _sectionHeader('STUDENT DETAILS'),
                        _row('Student Name', payment.student),
                        _row('Admission No.', payment.admNo),
                        _row('Class', payment.cls),
                        if (payment.noteText.isNotEmpty) ...[
                          _sectionHeader('NOTES'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFFF8F8FB), borderRadius: BorderRadius.circular(8)),
                            child: Text(payment.noteText, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.5)),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.only(top: 14),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: fcBorder))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'This is a computer-generated receipt and does not require a signature.',
                                style: TextStyle(fontSize: 11, color: fcInk3),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${header.name}${header.email.isNotEmpty ? '  ·  ${header.email}' : ''}',
                                style: const TextStyle(fontSize: 11, color: fcInk3),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: fcBorder))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FcOutlineButton(label: 'Close', onPressed: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      FcPrimaryButton(label: 'Print / Share', onPressed: () => shareReceiptPdf(payment: payment, header: header)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: fcInk3)),
    );
  }

  Widget _row(String label, String value, {Widget? valueWidget}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          valueWidget ?? Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fcInk1), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
