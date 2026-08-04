import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../fees/presentation/utils/pdf_unicode_theme.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../domain/entities/invoice_entity.dart';

const _kStateCodes = {
  'andhra pradesh': '37', 'arunachal pradesh': '12', 'telangana': '36', 'karnataka': '29', 'tamil nadu': '33',
  'kerala': '32', 'maharashtra': '27', 'gujarat': '24', 'rajasthan': '08',
  'madhya pradesh': '23', 'uttar pradesh': '09', 'bihar': '10', 'west bengal': '19',
  'odisha': '21', 'jharkhand': '20', 'chhattisgarh': '22', 'haryana': '06',
  'punjab': '03', 'himachal pradesh': '02', 'uttarakhand': '05', 'delhi': '07',
  'goa': '30', 'assam': '18', 'tripura': '16', 'sikkim': '11',
};
String _stateCode(String state) => _kStateCodes[state.trim().toLowerCase()] ?? '';

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

pw.Widget _kv(String label, String value, {bool bold = false, double fontSize = 10}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize, color: const PdfColor.fromInt(0xFF6B7280))),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: const PdfColor.fromInt(0xFF181B2A)),
        ),
      ],
    ),
  );
}

/// Builds the real Tax Invoice PDF and saves it directly to a user-findable
/// location (see `saveBytesForDownload`), returning the saved path so the
/// caller can confirm it to the user — web's `handleDownloadPdf()`
/// (`billing/page.tsx`) is just `window.print()` on the same on-screen
/// invoice (no backend PDF file to fetch); on mobile a direct save is the
/// closer match to "download" than opening a print/share dialog. Same field
/// set as the Flutter Tax Invoice card (`billing_tab.dart`'s
/// `_buildTaxInvoiceCard`) — seller/buyer, line items, GST breakdown,
/// amount in words, payment terms.
Future<String> downloadInvoicePdf(InvoiceEntity invoice, {required String sellerGstin, required String sellerState}) async {
  final doc = await buildInvoicePdfDocument(invoice, sellerGstin: sellerGstin, sellerState: sellerState);
  final bytes = await doc.save();
  return saveBytesForDownload(bytes: bytes, filename: '${invoice.invoiceNumber}.pdf');
}

/// Builds the invoice PDF document — split out from [shareInvoicePdf] so the
/// real content generation can be exercised in a plain Dart/Flutter test
/// without the `printing` plugin's platform channel.
Future<pw.Document> buildInvoicePdfDocument(InvoiceEntity invoice, {required String sellerGstin, required String sellerState}) async {
  final effectiveSellerState = sellerState.isNotEmpty ? sellerState : invoice.sellerState;
  final effectiveSellerGstin = sellerGstin.isNotEmpty ? sellerGstin : invoice.sellerGstin;
  final inter = invoice.sellerState.trim().toLowerCase() != invoice.buyerState.trim().toLowerCase();
  final tax = invoice.taxBreakdown;

  final doc = pw.Document(theme: await pdfUnicodeTheme());
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 48),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Tax Invoice', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
                pw.Text('ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFA0A3B8))),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(invoice.sellerName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('12th Floor, Bagmane Tech Park, CV Raman Nagar, Bengaluru, $effectiveSellerState 560048 · India',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF6B7280)), textAlign: pw.TextAlign.right),
                pw.Text('GSTIN ${effectiveSellerGstin.isEmpty ? '—' : effectiveSellerGstin}',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF6B7280))),
              ],
            ),
          ],
        ),
        pw.Divider(color: const PdfColor.fromInt(0xFFE8E8EE), thickness: 1.4),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
                  pw.SizedBox(height: 3),
                  pw.Text(invoice.buyerName.isEmpty ? invoice.schoolName : invoice.buyerName, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(invoice.buyerState, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('GSTIN ${invoice.buyerGstin.isEmpty ? 'Unregistered' : invoice.buyerGstin}', style: const pw.TextStyle(fontSize: 10)),
                  if (invoice.tenantId.isNotEmpty) pw.Text('Tenant ${invoice.tenantId}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INVOICE DETAILS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
                  pw.SizedBox(height: 3),
                  _kv('Invoice no.', invoice.invoiceNumber, bold: true),
                  _kv('Invoice date', _formatDate(invoice.invoiceDate)),
                  _kv('Due date', _formatDate(invoice.dueDate)),
                  _kv('Status', invoice.status[0].toUpperCase() + invoice.status.substring(1)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text('PLACE OF SUPPLY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
        pw.SizedBox(height: 3),
        pw.Text('${_stateCode(invoice.buyerState).isNotEmpty ? '${_stateCode(invoice.buyerState)} — ' : ''}${invoice.buyerState} · ${inter ? 'Inter-state' : 'Intra-state'} supply · Reverse charge — ${invoice.reverseCharge ? 'Yes' : 'No'} · Currency — INR',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 16),

        pw.Text('LINE ITEMS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
        pw.SizedBox(height: 6),
        pw.Table(
          border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE8E8EE))),
          columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1), 3: pw.FlexColumnWidth(1), 4: pw.FlexColumnWidth(1.2)},
          children: [
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('Description', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('SAC', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('Qty', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('Rate', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('Amount', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            ]),
            for (final item in invoice.lineItems)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(item.sacCode, style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(formatINR(item.unitPrice, compact: false), style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(formatINR(item.amount, compact: false), style: const pw.TextStyle(fontSize: 9))),
              ]),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(
              children: [
                _kv('Subtotal', formatINR(tax.subtotal, compact: false)),
                if (inter) _kv('IGST @ 18%', formatINR(tax.igst ?? 0, compact: false)),
                if (!inter) _kv('CGST @ 9%', formatINR(tax.cgst ?? 0, compact: false)),
                if (!inter) _kv('SGST @ 9%', formatINR(tax.sgst ?? 0, compact: false)),
                pw.Divider(color: const PdfColor.fromInt(0xFFE8E8EE)),
                _kv('Total payable', formatINR(tax.grandTotal, compact: false), bold: true, fontSize: 12),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFF8F8FB), borderRadius: pw.BorderRadius.circular(6)),
          child: pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 9.5, color: PdfColor.fromInt(0xFF6B7280)),
              children: [
                const pw.TextSpan(text: 'Amount in words · '),
                pw.TextSpan(text: tax.amountInWords, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Text('PAYMENT TERMS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
        pw.SizedBox(height: 3),
        pw.Text(
          'Payable within 15 days of invoice date. Bank transfer to HDFC 0000123456789 · IFSC HDFC0001234 · '
          'A/c name Eskoolia Technologies Pvt Ltd · UPI eskoolia@hdfcbank · Reference ${invoice.invoiceNumber} in remittance.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF6B7280)),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('For ${invoice.sellerName.isEmpty ? 'Eskoolia Technologies Pvt Ltd' : invoice.sellerName}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Authorised Signatory', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text('NOTES', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1, color: const PdfColor.fromInt(0xFFA0A3B8))),
        pw.SizedBox(height: 3),
        pw.Text(
          'Whether tax payable under reverse charge — ${invoice.reverseCharge ? 'Yes' : 'No'}. This is a computer-generated invoice; signature not required if digitally signed.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF6B7280)),
        ),
      ],
    ),
  );

  return doc;
}
