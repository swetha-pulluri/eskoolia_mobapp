import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pdf_unicode_theme.dart';
import '../../domain/models/school_header_info.dart';
import '../widgets/fees_collection_models.dart';
import 'fee_assignment_format.dart' show groupIndian;

class _StatusCfg {
  final String label;
  final PdfColor bg;
  final PdfColor color;
  final PdfColor border;
  const _StatusCfg(this.label, this.bg, this.color, this.border);
}

/// Third, slightly different status-label set from the ledger's
/// `STATUS_LABEL` / the payments table's `STATUS_CFG` — preserved as its
/// own map to match the source's own inconsistency (see port spec §13/§17).
const Map<String, _StatusCfg> _receiptStatusCfg = {
  'posted': _StatusCfg('Settled', PdfColor.fromInt(0xFFdcfce7), PdfColor.fromInt(0xFF15803d), PdfColor.fromInt(0xFF86efac)),
  'pending_clearance': _StatusCfg('Pending Clearance', PdfColor.fromInt(0xFFfef3c7), PdfColor.fromInt(0xFFd97706), PdfColor.fromInt(0xFFfde68a)),
  'pending_reconciliation': _StatusCfg('Pending Reconciliation', PdfColor.fromInt(0xFFfef3c7), PdfColor.fromInt(0xFFd97706), PdfColor.fromInt(0xFFfde68a)),
  'pending_verification': _StatusCfg('Pending Verification', PdfColor.fromInt(0xFFede9fe), PdfColor.fromInt(0xFF7c3aed), PdfColor.fromInt(0xFFc4b5fd)),
  'reversed': _StatusCfg('Reversed', PdfColor.fromInt(0xFFfee2e2), PdfColor.fromInt(0xFFdc2626), PdfColor.fromInt(0xFFfca5a5)),
};

const _methodLabel = {'cash': 'Cash', 'bank': 'Bank Transfer', 'online': 'Online / UPI', 'wallet': 'Wallet', 'cheque': 'Cheque'};

Future<Uint8List?> _fetchImageBytes(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final response = await Dio().get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final data = response.data;
    return data == null ? null : Uint8List.fromList(data);
  } catch (_) {
    return null;
  }
}

pw.Widget _row(String label, String value, {pw.Widget? valueWidget}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 10),
    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFF3F4F6)))),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF6B7280))),
        valueWidget ?? pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
      ],
    ),
  );
}

/// Mirrors FeesCollectionPanel.tsx's `downloadReceipt` (§13 of the port
/// spec) — the source opens a printable HTML doc in a new browser tab; on
/// mobile there is no such popup, so this builds an equivalent real PDF and
/// hands it to the native print/share sheet, matching the same established
/// pattern as `document_print_helper.dart`.
Future<void> shareReceiptPdf({required FcPaymentRow payment, required SchoolHeaderInfo header}) async {
  final logoBytes = await _fetchImageBytes(header.logoUrl);
  final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
  final cfg = _receiptStatusCfg[payment.status] ?? _receiptStatusCfg['posted']!;

  final doc = pw.Document(theme: await pdfUnicodeTheme());
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 60, vertical: 56),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 24),
              margin: const pw.EdgeInsets.only(bottom: 28),
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColor.fromInt(0xFFE8E8EE)))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFF3F4F6),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE8E8EE)),
                          borderRadius: pw.BorderRadius.circular(12),
                          image: logoImage != null ? pw.DecorationImage(image: logoImage, fit: pw.BoxFit.cover) : null,
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(header.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '${header.address}${header.email.isNotEmpty ? '  ·  ${header.email}' : ''}',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFF6D4AFF), borderRadius: pw.BorderRadius.circular(20)),
                    child: pw.Text('RECEIPT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                ],
              ),
            ),
            pw.Text('Payment Receipt', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
            pw.SizedBox(height: 4),
            pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColor.fromInt(0xFFA0A3B8)),
                children: [
                  const pw.TextSpan(text: 'Receipt No: '),
                  pw.TextSpan(text: payment.rcpt, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF6D4AFF))),
                ],
              ),
            ),
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 16),
              padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8F7FF),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFF6D4AFF), width: 1.4),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Paid', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF6D4AFF))),
                  pw.Text('Rs. ${groupIndian(payment.amount.round().toString())}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF6D4AFF))),
                ],
              ),
            ),
            pw.Text('PAYMENT DETAILS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
            pw.SizedBox(height: 6),
            _row('Date', payment.date.isEmpty ? '—' : payment.date),
            _row('Payment Method', _methodLabel[payment.method] ?? payment.method),
            if (payment.txRef.isNotEmpty) _row('Transaction Reference', payment.txRef),
            if (payment.feeName.isNotEmpty) _row('Fee Type', payment.feeName),
            _row(
              'Status',
              '',
              valueWidget: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: pw.BoxDecoration(color: cfg.bg, border: pw.Border.all(color: cfg.border), borderRadius: pw.BorderRadius.circular(20)),
                child: pw.Text(cfg.label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: cfg.color)),
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text('STUDENT DETAILS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
            pw.SizedBox(height: 6),
            _row('Student Name', payment.student),
            _row('Admission No.', payment.admNo),
            _row('Class', payment.cls),
            if (payment.noteText.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Text('NOTES', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFF8F8FB), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Text(payment.noteText, style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF6B7280))),
              ),
            ],
            pw.SizedBox(height: 32),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 12),
              decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE8E8EE)))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'This is a computer-generated receipt and does not require a signature.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFA0A3B8)),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    '${header.name}${header.email.isNotEmpty ? '  ·  ${header.email}' : ''}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFA0A3B8)),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: '${payment.rcpt}.pdf');
}
